---
name: aiohttp-sidecar-test
description: In-progress work — testing browser-trace v0.3.3 aiohttp recording sidecar via a scratchpad Docker harness
metadata: 
  node_type: memory
  type: project
  originSessionId: ec25c13b-b239-44a9-ba77-34c66df5be52
---

Recording API was migrated from a hand-rolled asyncio HTTP handler to **aiohttp**
(for HTTP Range / video seeking) on branch `feat/session-recording` (PR #2).
Latest release is **v0.3.5**. Version history: v0.3.3 = aiohttp migration;
v0.3.4 = dropped S3/Tigris backend (local storage only); v0.3.5 = recording is
now **always-on** (RECORD flag removed) and the HTTP port is **hardcoded to 8088**
(`_HTTP_PORT`, BROWSER_TRACE_PORT removed). Only BROWSER_ID and RECORDING_DIR stay
configurable. PR diff was also trimmed (formatter reflows reverted, .gitignore
entry dropped). All released binaries live (`browser-trace-linux-amd64`/`-arm64`).

Endpoints served by aiohttp: `GET /recordings` (JSON list) and
`GET /recordings/{id}` (MP4 via `web.FileResponse`, Range-capable). Server binds
`::` dual-stack on port 8088 (`BROWSER_TRACE_PORT`) for Fly 6PN. Verified working
in the frozen linux/arm64 binary (logged `HTTP server listening on [::]:8088`).

**chrome-live** (`/Users/faisal/workspace/src/github.com/mcp-getgather/chrome-live`)
is the sidecar consumer — its Dockerfile downloads the released browser-trace
binary and launches the browser with `--remote-debugging-port=9221`; sidecar
config `browser-trace.conf` sets `CDP_PORT=9221 RECORD=1`. We briefly edited it
(google-chrome→chromium via `ppa:xtradeb/apps`, URL bump to v0.3.3) to build on
Apple Silicon, then **reverted it** — chromium≠chrome for production, so those
edits must NOT be committed. Testing moved to the scratchpad harness instead.

**TESTED & PASSING** (native arm64 podman build, chromium harness): built
`bt-test` from `Dockerfile.test`, ran with an animated `data:` URL as START_URL
(static pages emit 0 screencast frames → recording discarded, so an animated
page is required), killed chromium to finalize. Result: valid MP4 recorded
(h264 780x436 5.4s, 27 frames) and the aiohttp API served it correctly —
`GET /recordings` lists it, full `GET /recordings/{id}` → 200 video/mp4 with
Accept-Ranges, `Range: bytes=0-99` → 206 Content-Range, unknown id → 404.

**Multi-tab verified:** 3 tabs → 3 distinct recordings/target_ids → 3 MP4 files,
all listed and served by the API. Recording is per CDP session/target, so each
tab records independently. To test multiple tabs, chromium MUST run **headful
under Xvfb** — `--headless=new` rejects it with "Multiple targets are not
supported in headless mode". chrome-live runs headful under X anyway, so the
harness now does too (Xvfb + `TABS=N` env var in Dockerfile.test).

**Key gotcha — the server binds IPv6-only.** asyncio `create_server` sets
`IPV6_V6ONLY=1` on a `::` bind, so IPv4 `127.0.0.1`/podman `-p` (IPv4) can't
reach it; curl over `[::1]` works. This is NOT a regression (v0.3.2 manual server
was identical) and fine in prod (Fly 6PN is IPv6-only). For local podman tests,
hit it over IPv6, e.g. `podman exec <ctr> curl "http://[::1]:8088/recordings"`.

Commands: `podman build --platform linux/arm64 -t bt-test -f Dockerfile.test .`
then `podman run -d --name bt-test-run -e START_URL="<animated data url>" -p
8088:8088 -v ./recordings:/recordings bt-test`. User uses **podman**, not docker.
