# Context handoff: tap-connect sidecar memory + failing tests

You are picking up a debugging session already in progress. Read this fully before acting. It records what was measured, what is proven vs. merely suspected, and what state was left deployed. Do not re-derive the settled parts.

## The setup

- **Repos** (all changes below are UNCOMMITTED working-tree edits):
  - `/Users/faisal/workspace/src/github.com/corelens-engineering/demos` — branch `feat/tap-connect-sidecar`. App `apps/tap-connect`.
  - `/Users/faisal/workspace/src/github.com/remotebrowser/remotebrowser` — branch `feat/tap-connect-sidecar` (the `getgather` Python service).
  - `/Users/faisal/workspace/src/github.com/corelens-engineering/flyfleet` — branch `live-desktop-view-rfb` (the Chrome fleet manager).
- **Fly apps** (org `remote-browsers-dev`): `tap-connect-mock-flyfleet` (aka tcmf, machine `819525a9015e38`) and `flyfleet-dev` (machine `683e512c422778`).
- tcmf runs two processes in one machine: `node dist/server.js` (tap-connect) and `uvicorn getgather.main:app` on 127.0.0.1:23456 (the "sidecar"), plus tailscaled. It reaches the fleet via `CHROMEFLEET_URL=http://flyfleet-dev.flycast`.
- **Observability**: Logfire project `getgather`. Custom memory samples are the span `[XRAY] memory sample`. Query with the logfire MCP tools; call `query_schema_reference` first.

## Part 1 — The memory investigation (essentially CLOSED)

Original symptom: uvicorn grew 147MB -> 632MB over 21h on a 1GB VM, wedging it. `oom_kill` was 0, `pgmajfault` 133k — it thrashed rather than being killed, so nothing restarted it and `/health` sat critical for 12h.

**What was proven:**

1. **Not a C memory leak.** Distinguish three things: (a) live Python objects still referenced, (b) memory freed by Python but retained by the allocator, (c) memory malloc'd outside Python and orphaned = a true C leak. Evidence points at (b).
2. **Idle-floor test (the decisive one).** Comparing two moments at *identical* idle state (`sockets 6, fds 19`): at 06:00:56 RSS was 146.0MB / traced 1.3MB; at 06:24:59 RSS was 505.7MB / traced 82.7MB. RSS +360MB, Python-traced only +81MB. The memory does not come back at idle.
3. **`tracemalloc` totals plateau while RSS keeps moving.** `traced_mb` settled ~79MB and `traced_peak_mb` froze at 98.3MB, while RSS oscillated 385–506MB *at idle*. So ~300MB is held outside Python's live set = allocator retention (glibc arenas), not an object leak.
4. **BeautifulSoup is exonerated.** `bs4/element.py:1303` swung +15,716KB then -9,577KB between samples. Violent churn, fully returned. It is the largest allocator and NOT the leak. It is, however, the most likely *cause* of heap fragmentation.
5. **One genuine small leak: zlib compression contexts.** `websockets/extensions/permessage_deflate.py:72` is literally `self.encoder = zlib.compressobj(...)`. Its live bytes rose monotonically 3.6 -> 10.95MB while socket count *fell* 44 -> 13. Contexts outlive their connections. Worth ~11MB; fix is `compression=None` (or `no_context_takeover`) on the `websockets.connect()` in `getgather/browsers/router.py` `websocket_proxy`. This is real but is ~11MB of a ~300MB question — do not oversell it.

**Conclusion: memory is NOT the cause of the failing tests.** It was a symptom riding on top of them. Current state is healthy: uvicorn ~400MB, node ~200MB, MemAvailable ~1.2GB of 2GB, oom_kill 0.

## Part 2 — The real problem: tests failing (OPEN)

Tests run every 5 minutes. The passing run took 2m11s; failures take 5m21s–8m32s, i.e. **longer than the 5-minute interval, so runs overlap and stack load**. At least two distinct failure modes, do not conflate them (I did, and was wrong):

**Mode A — connect/handshake timeouts (dominant, e.g. 06:07–06:13):**
- `httpx.ConnectTimeout` on `GET /api/v1/browsers/{id}` (remote-browser -> flyfleet), 6–96s
- `ConnectionError: CDP WebSocket handshake timed out after 120s`
- `fastmcp.exceptions.ToolError` on `get_browser_ip_address` / `get_browsing_history` (one took 475.9s ~= the 8m32s test)
- tap-connect `POST /mcp` "This operation was aborted" at 60s and 179.8s

**Mode B — fleet state inconsistency (rare: only 4 FleetErrors in 2 hours):**
- `FleetError: App already exists and is deleted / Status 422 / {'browser_id': 'B55rr2arm'}`
- This hung a live test run at 06:50:42: tap-connect logged `[remotebrowser] request POST http://127.0.0.1:23456/api/v1/browsers` and never got a response — matching the user's observation "test is running but no running browser in flyfleet".

**The one perfectly steady signal:** `Orphan teardown skipped; will retry on next reconcile` fires **exactly 27 times per reconcile cycle (~every 10 min), unchanged for 2+ hours**. Same stuck set of orphaned Chrome apps (e.g. `chrome-ij366k`, `chrome-zvtthg`, `chrome-t2z87y`). Source: `flyfleet/src/pool/app_lifecycle.py` `teardown_orphaned_app`. It is NOT proven that these orphans cause the timeouts — that link is still open.

## Two unproven leads worth chasing first

1. **flyfleet-dev capacity.** Its `fly.toml` has `min_machines_running = 1` and `[http_service.concurrency] soft_limit = 20`, i.e. ONE machine with a 20-concurrent-request soft limit. Observed load was 44+ concurrent CDP connections. Fits perfectly: fleet fast at idle, 78s avg / 228s max under overlapping runs, recovers when load eases. Cheap test: add machines and see if overlap stops producing timeouts.
2. **Tailscale routing on tcmf.** Every ~5 min tailscaled logs `Extension CONNMARK revision 0 not supported` and `wgengine: Reconfig: router config failed`. Its DNS table routes `flycast.` through Tailscale (`100.109.247.69`) even though tcmf and flyfleet-dev are in the SAME Fly org and should use native Flycast with no Tailscale hop. Intermittent disruption here would look exactly like Mode A.

**Also worth considering:** breaking the overlap itself (raise the test interval above worst-case duration, or add a lock so a run can't start while one is in flight). That removes the self-reinforcing loop regardless of root cause.

## Deployed state — IMPORTANT

- **tcmf VM resized 1GB -> 2GB** (`fly.mock-flyfleet.toml`).
- **The RSS watchdog is DISABLED** via `SIDECAR_RSS_LIMIT_MB = '0'` in `fly.mock-flyfleet.toml`. `start-sidecar.sh` has a guard: `<= 0` disables. It was added to kill the sidecar at 500MB and let Fly restart it, because a wedge otherwise sits critical indefinitely with no auto-recovery. **RE-ARM IT (set e.g. 800–1200 for the 2GB VM) before leaving this unattended.**
- **New file `getgather/memory_xray.py`** (stdlib only, no new deps — deliberately, to avoid churning `uv.lock`). Sampler emits RSS, fds, sockets, asyncio tasks, gc object census, tracemalloc top-N sites, and traced totals. Enabled on tcmf via `MEMORY_XRAY`, `MEMORY_XRAY_CENSUS`, `MEMORY_XRAY_TRACEMALLOC` env in `fly.mock-flyfleet.toml`. Settings live in `getgather/config.py`; wired into the lifespan in `getgather/main.py`.
- **flyfleet `app_lifecycle.py`**: all 6 silent `except Exception` handlers changed to `logger.opt(exception=True).warning(..., error=f"{type(e).__name__}: {e}", ...)`. Deployed to flyfleet-dev TWICE, deliberately left uncommitted per the user.
- **UNVERIFIED / next action**: after the 2nd deploy, the 06:44 reconcile still showed NO `error` attribute and `code.lineno: 179`. In the new code the logging call moved to ~182 (three comment lines were added above it), so 179 is the OLD line number — suggesting the reconcile ran pre-deploy code. This was being verified when the session ended. Check: `fly ssh console -a flyfleet-dev -C "grep -c 'error=f' /app/src/pool/app_lifecycle.py"` and the machine's uptime/image, then wait one reconcile (~10 min) and re-query.

## Gotchas learned the hard way (do not repeat these)

- **loguru -> Logfire drops `opt(exception=True)`.** No `exception_type`, no stacktrace. But loguru **kwargs DO become queryable span attributes** (`app_name`, `tag` arrive fine) — so pass the error as a kwarg. Also: loguru has no `exc_info=` parameter; passing it silently becomes an extra field.
- **`tracemalloc.get_traced_memory()` only counts allocations after `tracemalloc.start()`**, which here runs in the app lifespan (deliberately, to exclude ~145MB of boot/MCP-bundle allocations). So absolute `untraced_mb` is meaningless and inflated by that constant — **only deltas are valid**.
- **The gc type census misses a lot.** CPython untracks dicts/tuples holding only atomic values, and raw bytes/str buffers were never tracked. Verified: allocating 60,000 dicts moved the census `dict` count by **1** while tracemalloc caught the full 6.5MB. A flat census is not a flat heap.
- **`fly ssh console -C "sh -c '... case $c in *uvicorn*) ...'"` self-matches**: the wrapper's own cmdline contains the pattern. Filter out anything containing `proc` first, or take the max-RSS match.
- **`rtk` rewrites `grep` patterns as ERE**, so `grep -c "logger.opt(exception=True)"` returns 0 because the parens become a capture group. Use `grep -cF`.
- `ps` and `free` are NOT in the tcmf image (no procps). Read `/proc` directly.
- tcmf startup takes ~90s (uvicorn mounts ~40 MCP bundles before binding) while the health check grace period is 30s, so it flaps critical during every deploy. Don't misread that as a failure.
- Do NOT re-run `apps/tap-connect/sync-remotebrowser.sh` casually — it re-vendors the remotebrowser checkout into `apps/tap-connect/.remotebrowser`, and if that repo is on a different branch you will silently bundle unrelated changes into the deploy.

## Suggested next steps

1. Finish verifying whether the flyfleet `error=` change is actually running; get the real exception behind the 27 orphan skips.
2. Test the flyfleet-dev concurrency hypothesis (more machines / higher soft limit) — most likely explanation for Mode A.
3. Investigate the Tailscale/Flycast routing question on tcmf (why is same-org traffic taking a Tailscale hop at all?).
4. Consider serializing the test runs so failures stop compounding.
5. Independently, land `compression=None` in `websocket_proxy` for the confirmed ~11MB zlib retention.
6. Re-arm the tcmf watchdog.

Note: a published artifact explains the memory findings in depth, including a decision table that is now KNOWN WRONG (it proposed comparing absolute traced vs RSS; must be delta-based per the gotcha above): https://claude.ai/code/artifact/a0b06edf-0361-43aa-944a-2d80e266bbd0
