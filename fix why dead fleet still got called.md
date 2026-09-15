# fleet-gateway: 500s under concurrency + flyfleet upstream is unreachable

Repo: /Users/faisal/workspace/src/github.com/remotebrowser/fleet-gateway
Deployed on GCE host `fleet` (Dokku/docker), container `fleet-gateway.web.1`.
SSH: gcloud compute ssh --zone "us-central1-c" "fleet" --project "bluewizard"
Logfire project: getgather/remote-browser-dev (service_name='backstage' is the caller)

## Context: how this was found

Concurrency benchmark of the test-manager schedule "connect amazon mock backstage"
(https://test-manager.pitta-pound.ts.net/schedules/connect%20amazon%20mock%20backstage),
which drives tap-connect-dev -> backstage -> fleet-gateway -> fleets.
Ladder 1,3,5,7,10,15,20, stop on first failure:

| n | wall  | result            |
|---|-------|-------------------|
| 1 | 1.2m  | 1/1 passed        |
| 3 | 1.6m  | 3/3 passed        |
| 5 | 1.6m  | 5/5 passed        |
| 7 | 2.7m  | 6/7 — job 45858 FAILED |

So the ceiling is between 5 and 7 concurrent.

## Failure chain (job 45858)

Times UTC. test-manager UI shows WIB = UTC+7.

1. 08:00:40.485  backstage GET http://fleet.pitta-pound.ts.net/api/v1/browsers/Dcmf9awis
2. 08:00:53.748  gateway returns 500 after 13.26s
3. backstage converts to 502 on /api/signin/Dcmf9awis.../proxy-ip (span 30.85s):
   fastapi.exceptions.HTTPException: 502: Server error '500 Internal Server Error'
   for url 'http://fleet.pitta-pound.ts.net/api/v1/browsers/Dcmf9awis'
4. sign-in attempt 1 dies, backstage retries as attempt 2 on browser Disshvw7a
5. 08:00:41  tap-connect-dev logs "Error response from signin", {"detail": "Browser connection lost"}
6. job 45858 fails

Gateway container log at that moment:
  08:00:50 "GET /api/v1/browsers/Dcmf9awis HTTP/1.1" 500
  08:00:53 ERROR Exception in ASGI application
           httpx ReadTimeout
           /app/fleetgateway/browsers_router.py -> /app/fleetgateway/proxy.py

## Gateway latency vs load (backstage client spans)

| minute UTC | batch    | calls | avg   | max    | 5xx |
|------------|----------|-------|-------|--------|-----|
| 07:57      | n=3      | 9     | 0.94s | 4.87s  | 0   |
| 07:58      | n=5      | 16    | 2.06s | 6.87s  | 0   |
| 08:00      | n=7 peak | 29    | 3.77s | 21.45s | 1   |
| 08:02      | idle     | 22    | 0.49s | 2.03s  | 0   |

backstage's own connect-lock wait for a single browser grew
0.0s -> 17.6s -> 17.8s -> 33.6s -> 29.7s during that minute.

## Root causes (3, compounding)

### 1. BUG: _send_to_upstream has no exception handling

fleetgateway/proxy.py:

    async def _send_to_upstream(request, upstream, method, path, timeout) -> httpx.Response:
        headers = filtered_request_headers(request.headers)
        body = await request.body()
        return await upstream.client.request(...)   # <-- no try/except

    REQUEST_TIMEOUT_SECONDS = 10.0

    async def proxy_to_owner(request, browser_id, method, path) -> Response:
        ...
        response = await _send_to_upstream(request, owner, method, path, REQUEST_TIMEOUT_SECONDS)

Every other upstream call in the codebase handles failure, this one does not:
- upstreams.py race_launch/_attempt_launch  -> catches TimeoutException + TransportError
- upstreams.py fanout_probe_browser.probe   -> catches TimeoutException + TransportError
- upstreams.py fanout_list_browsers.list_one-> catches Exception
- proxy.py _send_to_upstream                -> catches NOTHING

So on the cache-hit path (the common path under load), a slow owner raises
httpx.ReadTimeout straight through FastAPI and uvicorn returns a bare 500.
Callers cannot distinguish "gateway is overloaded, retry" from "real server error".
It should be a 503/504 with Retry-After, so backstage can retry cleanly.

Callers: browsers_router.get_browser and browsers_router.terminate_browser both
go through proxy_to_owner.

### 2. flyfleet upstream is permanently unreachable (DNS)

Container env:
  UPSTREAM_URLS=http://flyfleet.flycast,http://daytona-fleet.web:8600,http://podman-fleet.web:8400

From inside the container:
  flyfleet.flycast  -> FAIL (Name or service not known)
  daytona-fleet.web -> 172.18.0.6
  podman-fleet.web  -> 172.18.0.5

.flycast is Fly.io internal DNS. It does not resolve outside Fly. The gateway
log is full of: ConnectError: [Errno -2] Name or service not known

BUT the network path itself works. Fly app `flyfleet` (org remote-browsers) has
private ingress IPv6 fdaa:40:80eb:0:1::2, and from inside the container:

  http://[fdaa:40:80eb:0:1::2]/health  -> 200 OK

(Host has tailscale accept-routes on (RouteAll: true; routes live in table 52,
not the main table), /etc/docker/daemon.json already has
{"ipv6": true, "fixed-cidr-v6": "fd00:d0c:1::/64", "ip6tables": true},
net.ipv6.conf.all.forwarding=1, container bridge v6 = fd00:d0c:1::3.)

So the immediate fix is to replace the flycast name with the literal IPv6:
  UPSTREAM_URLS=http://[fdaa:40:80eb:0:1::2],http://daytona-fleet.web:8600,http://podman-fleet.web:8400

(flyfleet-dev, org remote-browsers-dev, is fdaa:40:8b11:0:1::297d — check which
one this gateway should actually point at. The rest of this host runs the
non-dev fleets, so prod flyfleet looks right, but confirm.)

Note the docker network `fleet-net` reports v6 = "invalid IP" — only the default
`bridge` network gives the container IPv6. Worth checking that this is intentional.

### 3. Single uvicorn worker

The container runs one Python process (2 PIDs). All CDP WebSocket bridging AND
all REST API calls share one event loop. At n=7 the log shows dozens of
concurrent "[devtools] Bridging" sessions, which is why REST latency went from
0.5s idle to 3.77s avg / 21.45s max.

## What to do

1. Wrap _send_to_upstream (or proxy_to_owner) in try/except for
   httpx.TimeoutException and httpx.TransportError, returning 503/504 with
   Retry-After instead of letting it become a 500.
2. Add upstream health tracking / circuit breaking so a permanently unreachable
   upstream (like flyfleet today) is skipped instead of being probed on every
   single request. Right now every fanout pays a DNS failure for it.
   Decide: passive (mark down after N consecutive TransportErrors, retry after
   a cooldown) vs active (background /health poll). Passive is probably enough.
3. Fix UPSTREAM_URLS to the literal IPv6 so flyfleet is actually usable capacity.
4. Consider more uvicorn workers, or move CDP WebSocket proxying off the REST
   event loop.

Tests live in tests/ (test_upstreams_fanout.py, test_upstreams_race.py,
test_browsers_router.py, fake_upstream_server.py) — there is already a fake
upstream harness to add a timeout case to.

## Host resources: NOT the bottleneck

8 vCPU, 31GB RAM (21GB free), 96GB disk 15% used, no swap.
All containers run with NO cpu/memory limits, 0 restarts, no OOM kills.
fleet-gateway was using 104 MiB / 0.28% CPU. Load avg 0.29/0.90/1.46 on 8 cores.
