# What this branch leaves behind on `mock`

`feat/tap-connect-sidecar` was extracted from the `mock` branch to carry **the
sidecar deployment and nothing else** — the image, the boot script, the vendoring
script, the three Fly configs, and the amazon-mock repointing those configs are
useless without. `mock` had drifted well past that during the scheduled-test
investigation of 2026-08-08 → 08-10, and everything that drift produced was left
where it was.

This file is the inventory. **None of the changes below are applied here.** It
exists so that a later decision to bring one over is a deliberate act with the
context attached, and so nobody re-derives why the branch is smaller than `mock`.

Extracted from `mock` at `06bd2eab`, against `main` at `4245af26`.

## What this branch does contain

| File | Note |
| --- | --- |
| `Dockerfile.sidecar` | unchanged from `mock` |
| `start-sidecar.sh` | unchanged from `mock`, **including** the `LOGFIRE_TOKEN` re-export |
| `sync-remotebrowser.sh` | unchanged from `mock` |
| `SIDECAR.md` | unchanged from `mock` |
| `fly.mock-{flyfleet,browserbase,daytona}.toml` | unchanged from `mock`, **including** `ENVIRONMENT = 'mock-<tenant>'` |
| `src/config/amazon_us.json`, `packages/remotebrowser/src/retailers.ts` | the amazon-mock repointing — see below |

The telemetry wiring (`347c1a28`) came along deliberately: it is deployment
config rather than investigation code, it lives entirely in the boot script and
the tomls, and without it the sidecar half of every machine emits nothing at all.

## Not a gap, but read this — the amazon-mock repointing *is* here

Carried over deliberately, because the alternative was testing the sidecar
against real amazon.com:

| File | `main` | here, and on `mock` |
| --- | --- | --- |
| `apps/tap-connect/src/config/amazon_us.json` | `"domain": "amazon.com"` | `"domain": "amazon-mock.dataportrait.app"` |
| `packages/remotebrowser/src/retailers.ts` | `signinUrl: 'https://www.amazon.com/your-orders/orders'`, `targetDomain: 'amazon.com'` | both `amazon-mock.dataportrait.app` |

Three lines, and they are the reason this branch **must not be merged to
`main`** — the risk runs the other way there. Every other file here is additive
and would be harmless on `main`; these two are edits to shipped product config,
and on `main` they would point production tap-connect at the mock fixture.

> **Do not merge this branch. Deploy from it.** Same rule as `mock`: `main`
> merges *in* to pick up app changes, never the reverse.

Removing the constraint means sourcing the domain from configuration rather than
from a checked-in constant, so the mock tenants select it through their `[env]`
block like they already select a browser backend. Until that exists, the
never-merge rule is the only thing holding the line.

`SIDECAR.md`'s *Verify* block is the post-deploy check: `amazon_us domain` must
read `amazon-mock.dataportrait.app` on all three apps. If it says `amazon.com`, a
`main` merge clobbered the override and the app is hitting real Amazon.

There is a matching override in the **remotebrowser** repo's own `mock` branch
(`getgather/mcp/amazon.py` plus ~64 pattern files) which `sync-remotebrowser.sh`
vendors in — so the repointing is only half in this repo. See Gap 3.

## Gap 1 — application fixes found by the investigation

Two commits of real product fixes. Both are branch-shaped work that belongs in
its own PR against `main`, not in a deployment branch — that is why they are not
here. Neither is sidecar-specific; both were found *through* the mock deployment.

### `0c46e791` — `fix(connector): make session mutation atomic`

`connector_data` is one JSON document rewritten in full on every write. Each
`SessionManager` mutator did a read, a change and a write as two round trips, so
two concurrent callers on the same session silently discarded one change. They
overlap by design — the sign-in job advances `lastSigninStatus` while the UI
polls it. When the discarded write is the one recording `brandSigninId`, the
caller is bounced back to the credential step with a live session and correct
credentials.

Adds an optional `updateSession(clientId, mutate)` to `ConnectorSessionStore`,
routes all six mutators through it, implements it in `DbConnectorSessionStore`
with `pg_advisory_xact_lock(hashtext(session_id))` and in the in-memory store
trivially. Optional so existing implementations keep compiling.

Files: `packages/connector/src/core/session-manager.ts`,
`packages/connector/src/types/session-store.ts`,
`packages/connector/src/index.ts`,
`apps/tap-connect/src/server/connectorSessionStore.ts`,
plus `packages/connector/src/core/session-manager.test.ts` (222 lines, reproduces
the lost update and asserts the broken case too).

### `26384551` — `fix(tap-connect): stop reaping the browser mid-sync`

Stacked on the above. The capacity reaper terminated the browser of any session
whose reservation had gone stale, and `refreshSyncCapacity` was only called
*between* units of work. Until the first page landed, a reservation still read
`SIGNIN` on the 5-minute `SYNC_CAPACITY_SIGNIN_TTL_MINUTES` fuse, so a first
fetch slower than five minutes had its browser killed underneath it and every
later call in that run hit `410 Gone`.

Adds `withSyncCapacityHeartbeat` (stamps once up front, then on a timer while
work is in flight) and wraps the Amazon background sync in it. Separately, adds
`isBrowserSessionGone` so `callTool` stops retrying a released browser — that
retry turned a 2-minute CDP timeout into 4, past the caller's deadline, which is
why these surfaced as hangs with neither result nor error.

Files: `apps/tap-connect/src/server/capacityTracker.ts`,
`capacityConstants.ts`, `src/server/amazon/backgroundSync.ts`,
`packages/connector/src/core/mcp-connector.ts`, plus
`__tests__/capacityHeartbeat.test.ts` and `is-browser-session-gone.test.ts`.

## Gap 2 — `DEBUG-mock-tests.md`

1,362 lines of investigation notes, left on `mock`. It is a working document
about three specific Fly machines over three days, not documentation of the
deployment, so it does not belong on a branch aimed at `main`.

What it holds that is not recoverable from anywhere else:

- **Access recipes** — test-manager endpoints, how to pull a Playwright report by
  machine id, the psql invocation, the Logfire project (`getgather`, **not**
  `remote-browser-dev`) and how to confirm the sidecar's `LOGFIRE_TOKEN` took.
- **Seven catalogued bugs (B1–B7)** with evidence and ship status.
- **Nine theories that looked right and were wrong**, each with the measurement
  that killed it — recorded specifically so they are not re-run.
- **Three still-unexplained failures**, chiefly the `/dpage/{id}` 300s hang that
  was the sole remaining red-dashboard cause when the notes stop.

If this branch outlives `mock`, that file is the thing worth copying across —
it is the only record of the reasoning.

`SIDECAR.md` on `mock` describes it as a companion document; here that companion
does not exist.

## Gap 3 — the remotebrowser-side changes are not in this repo at all

Worth stating because it is invisible from a checkout. `sync-remotebrowser.sh`
vendors `getgather` from a **remotebrowser** checkout into `.remotebrowser/`, so
**whichever branch that repo is on is what gets deployed** — and nothing here
pins it.

That repo has a branch of this same name, `feat/tap-connect-sidecar`, extracted
the same way: it carries the amazon-mock repointing (`getgather/mcp/amazon.py`
plus 64 pattern files) and nothing else. **Vendor from that branch, not from
`main`** — the repointing here covers only the tap-connect half, and a
mismatched pair sends the sidecar at real Amazon regardless of what this repo
says. See `MOCK-OVERRIDES.md` over there.

What that branch does *not* carry, because it was left on remotebrowser's `mock`
alongside everything else, is the leak work:

| Fix | What it changed | Status when the notes stop |
| --- | --- | --- |
| Session timeout | `BROWSERBASE_SESSION_TIMEOUT: int = 900`; create body sends `timeout` alongside `keepAlive` | shipped 08-08, browserbase only |
| Local browser close | `close_local_browsers` in `browser.py`; called from `delete_browser` in a `finally` and on the 404 path | shipped 08-09 |
| Reuse + reaper | `_reusable_instance` in `get_remote_browser`; `reap_idle_browsers` on `BROWSER_LOCAL_IDLE_TTL_SECONDS` (1200s) | shipped 08-09, partial — `create_remote_browser` was missed, still ~73 instances per browser |
| Router proxy close | `websocket_proxy` `close_timeout` 7200 → 10; `finally` closing the inbound socket; explicit per-target connection close | shipped 08-10 |

So a sidecar vendored from either `main` or `feat/tap-connect-sidecar` **leaks
~300 sockets and ~284 MB per run** on the browserbase and daytona backends,
reaching ~600 MB on a 1 GB VM — past which memory pressure kills `tailscaled`,
the tailnet database goes unreachable, `/health` 500s and Fly deroutes the
machine. The flyfleet tenant sets `CHROMEFLEET_URL`, does not take the leaking
path, and is unaffected.

Those two tenants are therefore deployable but will wedge on a timescale of hours
until the leak work lands somewhere other than `mock`. **That is the sharpest
edge on this branch.**

## Not a gap

- `.gitignore` — `mock` and `main` are identical here. `.remotebrowser/` and
  `.env-*` are excluded through `.git/info/exclude`, which is local to a clone and
  travels with neither branch. A fresh clone must re-add both patterns;
  `SIDECAR.md` says why (a tracked entry would conflict on every merge from
  `main`).
- `.env-flyfleet` / `.env-browserbase` / `.env-daytona` — never tracked on any
  branch. Secrets are imported with `fly secrets import`; the files exist only on
  the machine that deploys.
