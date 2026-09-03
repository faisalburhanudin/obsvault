---
name: liveview-poc
description: "browser-trace POC — chromium Docker image exposing single-screencast live view + recording HTTP surface, built & verified"
metadata: 
  node_type: memory
  type: project
  originSessionId: 76af7e22-311f-4725-baf8-193eb805374a
  modified: 2026-07-19T13:51:18.915Z
---

Built the POC from `docs/live-view-recording-research.md`: one CDP screencast per
tab feeds BOTH the recorder (MP4) and an interactive live view (WS), no VNC.

Current merged HEAD had **no HTTP server at all** (pyproject deps were only
websockets+logfire; the aiohttp/8088 work in [[aiohttp-sidecar-test]] was an
UNMERGED branch). So the POC added it fresh.

**New files:** `liveview.py` (aiohttp app), `poc/Dockerfile`, `poc/entrypoint.sh`,
`poc/browser-trace.conf`, `poc/README.md`. **Modified:** `main.py` (3rd asyncio
task `liveview.serve("0.0.0.0", http_port)`; frame tee in handle_event after
rec.handle_screencast_frame → `await liveview.broadcast_frame`; set_cdp/clear_cdp
in connect_cdp; `http_port` Config field from BROWSER_TRACE_PORT default 9223),
`pyproject.toml` (+aiohttp, ran `uv lock`).

Endpoints on 9223 (bound 0.0.0.0 → host-reachable via `-p`): `/` dashboard,
`/healthz`, `/targets`, `/view/{target_id}` (HTML viewer), `/live/{target_id}`
(WS: binary JPEG down, JSON input up), `/recordings`, `/recordings/{id}` (mp4).
Input coords normalized 0..1 → CSS px via last frame's deviceWidth/Height.

**Docker:** `debian:bookworm-slim` + real `chromium` deb (Google Chrome has no
arm64/mac build; Ubuntu chromium is a snap that won't run in a container).
Chromium headful under bare Xvfb, `--no-sandbox --remote-allow-origins=*
--remote-debugging-port=9222`. browser-trace built from local source via uv.

**GOTCHA — signal forwarding:** entrypoint must `exec /app/.venv/bin/python -u
main.py cdp ...`, NOT `exec uv run`. `uv run` stays PID 1 and doesn't forward
SIGTERM, so `podman stop` SIGKILLs before rec.stop_all() can encode → no MP4.
Direct-python exec fixed it.

**Podman-on-mac:** VM doesn't mount /tmp; use a repo-relative volume dir
(`-v "$PWD/poc-recordings:/recordings"`). `docker` is aliased to podman.

**VERIFIED end-to-end** (2026-07-17): built arm64 image, ran container, opened
localhost:9223 in local Chrome — dashboard listed the live tab, live view
rendered Wikipedia in real time, and typing a URL in the viewer's bar drove
Page.navigate (input-up proven). Graceful stop encoded a valid 38KB MP4 +
sidecar JSON (6 frames, 22.4s) served by /recordings.

**GOTCHA — blank-on-attach (static pages):** CDP screencast is change-driven;
a page that already finished painting emits ZERO frames (same reason static
pages record 0 frames per [[aiohttp-sidecar-test]]). So a viewer attaching to
the SHARED screencast gets nothing until the page repaints. Fix: on WS attach,
grab a one-shot `Page.captureScreenshot` and send it as the first frame, then
stream screencast frames on change. This required adding `send_cdp_await` +
`_result_futures` to main.py (the existing send_cdp is fire-and-forget; screenshot
needs the result). set_cdp now passes both send_cdp and send_cdp_await to liveview.

**vs steel-browser** (`api/src/plugins/browser-socket/casting.handler.ts`):
steel runs a SEPARATE per-viewer CDP session + its OWN Page.startScreencast per
cast connection (not a shared tee) — so it gets the first frame for free
(startScreencast emits current frame) plus bringToFront + setDeviceMetricsOverride
force a repaint, and it forces 1:1 sizing to skip coord mapping. browser-trace's
goal is explicitly ONE shared screencast feeding recorder+liveview, so we keep the
tee and solve first-frame via captureScreenshot instead of a per-viewer screencast.
Borrowed steel's richer input fields: mouse `buttons` bitmask,
key `unmodifiedText`/`nativeVirtualKeyCode`.

Build/run: `podman build --platform linux/arm64 -t browser-trace-poc -f
poc/Dockerfile .` then `podman run --rm -p 9223:9223 -e START_URL=... -v
"$PWD/poc-recordings:/recordings" browser-trace-poc`. Related:
[[live-view-recording-initiative]].

**DEPLOYED TO FLY** (2026-07-19) for peer demo: app `liveview-cdp` in org
`remote-browsers-dev` (slug, region sjc), https://liveview-cdp.fly.dev.
`fly.toml` at repo ROOT (build context = root so poc/Dockerfile can COPY the
source); `[build] dockerfile="poc/Dockerfile"`, `[http_service] internal_port
9223` + `/healthz` check, one warm 2gb machine (auto_stop off, min 1). Deploy:
`fly deploy --config fly.toml --ha=false`. Verified: /healthz 200, /targets
lists the HN boot tab, live frame streams over wss (32KB jpeg).

**GOTCHA — dual-stack bind (this broke the first deploy):** aiohttp's `::`
bind sets IPV6_V6ONLY, so the listener is IPv6-only and Fly's **IPv4** health
check got "connection refused" (check froze, deploy timed out). Fix:
`liveview.serve` now binds BOTH `::` and `0.0.0.0` (bind :: first; the 0.0.0.0
add is skipped if the platform already gave :: a dual-stack socket). Same bug
would bite podman's IPv4 -p mapping. `fly logs`/`fly machine restart` hung in
this env; diagnose with `fly ssh console -C "..."` (image has no `ss`; read
/proc/net/tcp6 — 9223=0x2407 — and curl localhost inside).
