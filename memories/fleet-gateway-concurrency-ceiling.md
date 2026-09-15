---
name: fleet-gateway-concurrency-ceiling
description: fleet-gateway fails between 5 and 7 concurrent jobs; cause is an unguarded httpx call in proxy.py, not host resources
metadata:
  type: project
---

Benchmarked 2026-09-15 with the test-manager schedule "connect amazon mock
backstage" (ladder 1,3,5,7 — stop on first failure). 1/3/5 all passed clean;
**n=7 failed** (job 45858). So the ceiling sits between 5 and 7 concurrent.

**Why:** `fleetgateway/proxy.py::_send_to_upstream` has no try/except. Every
other upstream call in that repo catches `httpx.TimeoutException` /
`TransportError` (`race_launch._attempt_launch`, `fanout_probe_browser.probe`,
`fanout_list_browsers.list_one`) — this one does not. On the routing-table
cache-hit path a slow owner raises `ReadTimeout` (REQUEST_TIMEOUT_SECONDS =
10.0) straight through FastAPI, so uvicorn returns a bare **500**. backstage
turns that into a 502, the sign-in retries, and the job dies with
"Browser connection lost".

Two things make it worse: the gateway runs a **single uvicorn worker**, so CDP
WebSocket bridging and the REST API share one event loop (REST latency went
0.49s idle -> 3.77s avg / 21.45s max at n=7); and `flyfleet.flycast` in
`UPSTREAM_URLS` never resolves, so every fanout pays a dead upstream. Fix that
with the literal IPv6 — see [[reach-fly-6pn-from-docker]].

**Not the cause:** host resources. The `fleet` box has 8 vCPU / 31 GB (21 GB
free), containers run with *no* cpu/memory limits, 0 restarts, no OOM kills,
gateway at 104 MiB / 0.28% CPU. Don't re-investigate that.

Caller-side evidence is in Logfire [[logfire-project-remote-browser-dev]] under
`service_name='backstage'`; the gateway's own `/api/v1/browsers/*` server spans
are **not** exported, so the 500 is only visible in `docker logs`.

Test-manager timestamps are WIB (UTC+7) — subtract 7h to match Logfire.
