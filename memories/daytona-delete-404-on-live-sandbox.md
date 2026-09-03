---
name: daytona-delete-404-on-live-sandbox
description: DELETE 404s on live sandboxes come from tap-connect's shared reservation sweep reaping the other deployment's fleet
metadata:
  type: project
---

`DELETE /api/v1/browsers/{id}` returning 404 while the sandbox still runs is **not** a
Daytona bug. Confirmed end-to-end 2026-08-31 (Logfire + `corelens-engineering/demos`):
`connect-browserbase` and `tap-connect-daytona` are the same app (`apps/tap-connect`)
deployed twice. They share `TAP_CONNECT_DATABASE_URL` but each has its own
`TAP_CONNECT_REMOTEBROWSERS_URL`. The 1-minute sweep in `capacityTracker.ts` claims expired
rows from `tap_connect_sync_capacity_reservations` with **no fleet predicate**
(`db.ts:1486,1500`), so either deployment can win the other's session and DELETE the
browser against its own fleet.

**Why:** `DELETE … RETURNING` is atomic, so each row is claimed by exactly one deployment
and never retried — half the sandboxes leak forever. 5-min TTL + 60-s sweep explains the
~5.5-min delay. Silent because `client.ts` treats 404 as "already gone" and
`finalizeSigninQuietly` swallows the rest.

**How to apply:** the caller is NOT in the traceback (that is our own `raise` in
`getgather/browsers/router.py`) — read the Fly header:
`regexp_match(attributes->>'http.request.headers','app=([a-z0-9-]+)')[1]`. Check status with
`scripts/browser_delete_404_report.py`. Details in
`docs/issues/02-delete-404-on-live-sandbox.md`. See [[logfire-project-remote-browser-dev]].
