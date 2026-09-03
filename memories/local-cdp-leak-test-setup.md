---
name: local-cdp-leak-test-setup
description: How to reproduce and measure a CDP socket leak locally against the fly dev fleet
metadata: 
  node_type: memory
  type: project
  originSessionId: d0d5835e-22e1-4a08-b96a-09db445880e9
  modified: 2026-08-31T15:04:08.465Z
---

To see a CDP websocket leak from the local server log (no Logfire), instrument the
**client** side in `getgather/browser.py` — track each `zd.Browser` returned by
`_create_browser_from_cdp_websocket` and poll `connection.websocket.state.name == "OPEN"`
from a background reporter task started in `getgather/main.py`'s lifespan. Log
`[CDP-DEBUG] cdp OPEN/CLOSE` plus a periodic `open cdp browsers: N`.

Do **not** instrument `websocket_proxy` in `getgather/browsers/router.py`: with
`CHROMEFLEET_URL` set the backend is `FleetBackend`, zendriver connects straight to the
fleet, and the local relay is never entered.

Traps:
- `Settings` uses `env_ignore_empty=True`, so `CHROMEFLEET_URL= uv run ...` does **not**
  unset it — the `.env` value wins and you get `FleetBackend`. To force the podman
  self-relay topology you must move `.env` aside.
- Do not make `_traced_websocket_connect` an `async def`. The monkeypatch is process-wide
  and `websocket_proxy` uses it as `async with`.
- `setsid` does not exist on macOS. Launch the server and the driver in separate quick
  Bash calls with `nohup ... &` + `disown`, or the tool's 120s timeout kills the whole
  process group.

Driving `dpage_check`: `POST /api/v1/browsers`, `GET /api/v1/browsers/{id}/pages` (ids come
back namespaced as `<browser_id>@<target_id>` — strip the prefix), build
`<browser_id>--<target_id>` (delimiter is `--`), then `tools/call check_signin` on `/mcp/`.
It polls 120 ticks and reconnects each tick, so the leak shows as a monotonic climb.

See [[cdp-websocket-leak-findings]].
