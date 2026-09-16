# Fleet Gateway: a redeployed upstream stays dead until the gateway restarts

Repo: ~/workspace/src/github.com/remotebrowser/fleet-gateway

## Problem

Each `Upstream` holds one long-lived `httpx.AsyncClient`, built once at startup
(`fleetgateway/upstreams.py:23` `build_upstream`, wired in the app entrypoint).
The client keeps a connection pool and never resets it.

On the Dokku box the upstreams are sibling apps on the `fleet-net` docker
network, reached by DNS names like `browserbase-fleet.web:8601`. A Dokku deploy
replaces the container, so the app gets a **new IP**. The gateway keeps trying
the old one and every call fails:

```
WARNING [list] http://browserbase-fleet.web:8601 failed: ConnectError: All connection attempts failed
```

`/api/v1/upstreams` reported `healthy: false` for it, while the app itself was
running and answering `200 OK` on that exact URL from inside the gateway
container. Restarting the gateway fixed it instantly, with no config change.

So: **any upstream that redeploys looks permanently dead to the gateway until
the gateway is restarted by hand.** Silent, and easy to mistake for a broken
upstream.

## Confirmed on 2026-09-16

- Before gateway restart: `browserbase-fleet` unreachable, `healthy: false`
- From inside `fleet-gateway.web.1`, same moment: `browserbase-fleet.web` resolves
  to `172.18.0.2` and `GET /health` returns `200 OK`
- After the gateway restarted: all four upstreams `healthy: true`

## What to look at

- `fleetgateway/upstreams.py:23` — one client per upstream, created at startup
- the failure paths in `fanout_list_browsers`, `fanout_probe_browser`,
  `_attempt_launch`, `gather_diagnostics` — they all log and swallow the
  `ConnectError`, so nothing ever triggers a recovery
- `proxy.py` turns timeouts into bare 500s (see memory
  `fleet-gateway-concurrency-ceiling`) — related rough edge

## Goal

Make the gateway recover on its own when an upstream's address changes.
Options to weigh:

- retry once on `ConnectError` after clearing that upstream's pool
- shorter DNS/connection reuse, or a per-request connection for probes
- rebuild the `AsyncClient` for an upstream after N consecutive connect failures
- a background health loop that resets a failed upstream's client

Keep the existing convention: every upstream-facing helper takes its deps as
explicit arguments, so it stays testable with fakes.

Propose options with trade-offs first. Do not implement yet.
