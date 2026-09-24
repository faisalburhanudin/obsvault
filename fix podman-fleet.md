stop leaking browser containers.

## Problem
Real incident (Logfire project `getgather`, service `podman-fleet`, 2026-09-23 and 2026-09-24):
- fleet-gateway calls `POST /api/v1/browsers` with a 60s timeout.
- When the host was overloaded, `launch_browser` in `podmanfleet/api_router.py` took much longer. Some calls returned 200 after 3,715s and 12,124s.
- The client had already given up, so nobody got the `browser_id` and nobody ever sent DELETE. podman-fleet has no idle cleanup, so these containers stay forever.

## What to build

### 1. Clean up a launch the client stopped waiting for
In `launch_browser`, after `launch_container()` / `configure_browser()` finish, check if the client is still connected (`await request.is_disconnected()`). If the client is gone, call `podman_browsers.terminate_browser(browser_id)` and log a warning with the browser_id and how long the launch took.
- Also handle cancellation: if the request task is cancelled while a container is being created, make sure the container is removed if it exists (try/finally or shielded cleanup). Check how uvicorn/Starlette behaves on client disconnect before choosing the approach, and note the finding in a short comment.
- a server-side launch deadline (setting, e.g. `LAUNCH_TIMEOUT_SECONDS`, default ~90) after which the server gives up and removes the half-made container.

### 2. `MAX_BROWSERS` check is not atomic
`launch_browser` counts running browsers, then launches. Many concurrent launches can all pass the check and go over the cap. Use an `asyncio.Lock` or a counter of in-flight launches so in-flight launches count toward the cap.

## Constraints (from AGENTS.md)
- Python 3.11+, annotate return types, loguru for logging, settings via pydantic-settings.
- Keep comments short. Explain why, not what. Use simple English.
- Follow the existing code style in `podman_browsers.py` and `api_router.py`.