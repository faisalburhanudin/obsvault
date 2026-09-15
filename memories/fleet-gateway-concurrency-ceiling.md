---
name: fleet-gateway-concurrency-ceiling
description: Concurrency ceiling for the backstage->gateway->daytona chain; was 5-7, now ~15 after daytona-fleet got uvicorn workers
metadata:
  type: project
---

Benchmarked 2026-09-15 with the test-manager schedule "connect amazon mock
backstage" (ladder, stop on first failure). Measure resources per batch — Logfire
has **no system metrics** for these services, only `http.*`/`db.*`, so CPU and
memory must be sampled live off the host.

| config | n=7 | n=10 | n=15 |
|---|---|---|---|
| 1 uvicorn worker | 7/7 | 10/10 cold, 1-9/10 warm | not reached |
| 4 workers (PR #11) | — | 10/10 | 14/15 |

**What actually limited it:** `daytona-fleet` ran a single uvicorn worker, so one
asyncio loop pinned at ~100% of one core while the host sat 76-99% idle
(`vmstat`). A starved loop misses `CDP_WS_OPEN_TIMEOUT = 3.0`, retries burn
`CDP_CONNECT_BUDGET = 25.0`, and fleet-gateway quits at its own 10s
`REQUEST_TIMEOUT_SECONDS`. With `--workers 4` it reaches 355% CPU and the ceiling
moves to ~15.

**Still unfixed:** `fleet-gateway/fleetgateway/proxy.py::_send_to_upstream` has no
try/except, unlike every other upstream call in that repo, so an upstream timeout
becomes a bare 500 instead of a retryable 503. Workers hid it; they did not fix it.

**Order of limits now:** at n=15 the host itself binds — load1 hit 47 on 8 cores
and memory 21.5 GB of 31 GB. Past 15 needs hardware, not code. Memory was never a
factor below that.

**Warm vs cold matters.** Leaked relay sockets (see
[[cdp-websocket-leak-findings]]) leave daytona-fleet at ~20% CPU and 40-60 open
Daytona sockets. They drain in ~5 min idle. Warm n=10 gave 1/10 and 9/10 on
identical config; cold gave 10/10. Always drain before comparing runs.

Test-manager timestamps are WIB (UTC+7); subtract 7h for Logfire. The hourly cron
at `50 * * * *` adds a stray job if a batch overlaps it. Gateway-side 500s are
only in `docker logs` — the gateway exports no server spans. See
[[reach-fly-6pn-from-docker]] for the flyfleet upstream.
