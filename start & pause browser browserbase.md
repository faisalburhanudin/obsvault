Add Browserbase as a third backend to flyfleet, so that `POST /api/v1/browsers/{browser_id}` (start / create-or-get) and `POST /api/v1/browsers/{browser_id}/resume` work against Browserbase.

## Context you need before editing

There is currently NO Browserbase code, dependency, or string anywhere in this repo — this is a from-scratch backend, not an extension of an existing one.

Backend selection is via `settings.BACKEND`, NOT the `MODE` env var. `CLAUDE.md` is stale on this point (it documents `MODE=direct|pool` and a Fly-based `direct` mode plus a `ProxyFleet`); trust the code, not `CLAUDE.md`. Current state:

- `src/settings.py:14` — `Backend = Literal["fly", "daytona"]`, `BACKEND: Backend = "fly"` (line 20)
- `src/settings.py:37-46` — `validate_settings` model_validator requires `CONTAINER_IMAGE`/`FLY_API_TOKEN`/`FLY_ORG_SLUG` when `BACKEND == "fly"`, else the Daytona keys. It is a two-branch if/else, so a third backend needs restructuring, not just an added elif.
- `src/fleet.py:33-42` — `create_fleet()` dispatches: `BACKEND == "daytona"` → `DirectFleet` (stateless, no DB), otherwise → `PoolFleet(session_factory=...)`. This is also a two-branch fallthrough where "not daytona" silently means Fly.
- `src/app.py:25` — `create_app(create_fleet())` is the only caller.

Existing backends map to modes like this:

| BACKEND | Fleet impl | Backend package |
|---|---|---|
| `fly` | `PoolFleet` (`src/pool/manager.py`) — pre-warmed pool, SQLite/Postgres state | `src/fly/` |
| `daytona` | `DirectFleet` (`src/direct/manager.py`) — on demand, stateless | `src/daytona_/` |

## What to implement

Everything must satisfy the `Fleet` protocol in `src/fleet.py:7-30` — it is `@runtime_checkable` and `src/app.py` + `src/cdp.py` depend only on it. Full surface: `startup`, `shutdown`, `get_app`, `stop_app`, `list_apps`, `suspend_app`, `resume_app`, `upgrade`.

Even though the ask is start + resume, a partial implementation will break the app: `src/cdp.py:160` calls `list_apps()` for the `/devtools/{path}` websocket proxy, and `src/app.py` wires every route unconditionally. Implement the whole protocol; raise an explicit `FleetError` for anything Browserbase genuinely cannot do rather than leaving a method missing or silently returning a fake success.

Reference the two existing implementations for the expected shapes:

- **start / create-or-get** — `get_app` is really *ensure*. `src/direct/manager.py:31-35` derives a deterministic sandbox name from `browser_id`, creates if absent, starts if not running, all under a per-`browser_id` `asyncio.Lock` (`_locks`) so concurrent POSTs don't double-create. `src/pool/manager.py:123-145` instead claims a pooled app, assigns the id, backfills, and tears down on failure. The client supplies the id in the path; there is no collection-level create route.
- **resume** — `src/daytona_/sandbox.py:98-101` (state-guarded `start()`) and `src/fly/fly_app.py:158-161` (`machine.resume()`).
- **return shape** — `get_app` returns an info dict with `hostname`, `ip_address`, `cdp_url` (+ a vnc/liveview url); see `src/daytona_/sandbox.py:79-95` and `src/fly/fly_app.py:163-171`. Lifecycle methods return flat `{"status": "..."}` dicts.

Browserbase's model differs from both: sessions are created via its API and connect over a `wss://` CDP endpoint with the API key, sessions are not addressable by a caller-chosen name, and there is no suspend/resume in the Fly/Daytona sense. Decide and state explicitly how you map a caller-supplied `browser_id` to a Browserbase session id (persisted mapping vs. Browserbase session metadata/userMetadata), because the deterministic-name trick `DirectFleet` relies on will not work. Do not invent Browserbase API details — check the current Browserbase docs/SDK for session create/retrieve/list/release and the CDP connect URL before coding.

## Known inconsistencies — do not copy these, and match the better behavior

1. `PoolFleet.suspend_app`/`resume_app` (`src/pool/manager.py:183-197`) resolve via `App.get_app_by_browser_id(browser_id)` without `raise_if_not_found=False`, so an unknown/deleted id raises — while `DirectFleet` no-ops and `PoolFleet.stop_app` (`:172-175`) returns `{"status": "not found"}`. Pick the soft `{"status": "not found"}` behavior for Browserbase and note the divergence.
2. `FlyApp.suspend` (`src/fly/fly_app.py:153-156`) is `asyncio.create_task(machine.suspend())` fire-and-forget: it returns `{"status": "suspended"}` before the machine suspends, swallows exceptions, and the task isn't retained so it can be GC'd. Await your Browserbase calls; don't replicate this.
3. `POST /api/v1/browsers/{id}` and `GET /api/v1/browsers/{id}` are byte-identical handlers (`src/app.py:79-89`) both calling `get_app`, and both accept an unused `request: Request`. There is no auth on any route. Keep scope — do not add auth as a drive-by — but don't assume any exists.

## Also update

- `env.template` — add the Browserbase vars alongside the existing `BACKEND=fly` and the Fly/Daytona blocks.
- `.env.test` if the new backend needs test config (`pytest.ini` sets `ENV_FILE`).
- `pyproject.toml` — add the Browserbase SDK if you use it (`daytona>=0.183.0` is at line 36); a thin httpx client is also acceptable, say which you chose and why.
- `CLAUDE.md` — it is already wrong about `MODE` vs `BACKEND` and about `direct` being Fly-based. Fix those lines while adding Browserbase so the doc stops misleading.

## Tests

Mirror the existing per-backend layout: `tests/test_app_direct.py` and `tests/test_app_pool.py` cover the HTTP routes (see `test_suspend_and_resume_app` at `:71` and `:109`), `tests/test_direct.py:87` covers fleet methods directly, and the pool test polls real state with `wait_for_app_state` (`tests/utils.py:98`) because of the fire-and-forget bug above. Check `tests/conftest.py` for how `server`/`browser_id`/`generate_tracked_browser_id` fixtures are built and whether existing tests hit live APIs or mocks — follow whichever pattern is already there rather than introducing a new mocking style.

## Verify before reporting done

```bash
uv run pytest              # or: uv run pytest -n0 -s tests/<file> for one file
uv run pyright .           # strict
uv run ruff check . && uv run ruff format .
```

Report actual command output. If a test needs live Browserbase credentials you don't have, say so explicitly rather than marking the work complete.
