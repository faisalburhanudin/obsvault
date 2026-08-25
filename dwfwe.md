# Investigation: catch and diagnose leaked Daytona sandboxes

Repo: remotebrowser, branch `experiment/disable-ws-ping`.
All timestamps UTC, 2026-08-25. Daytona org is **Ario** (not Personal).

## Your task

1. Start a monitor that flags any live sandbox older than 5 minutes.
2. For each sandbox it catches, diagnose why it was never deleted.

Normal sandboxes die in well under 5 minutes (median 119s; `B`-prefixed median
60s), so anything crossing 5 minutes is an orphan by definition.

**This is an investigation, not a fix.** Do not change product code until one
credible mechanism explains the evidence.

## Step 1: start the monitor

Script is at `detect-old-sandboxes.py` (beside this file). Run it with the
Monitor tool, `persistent: true`, description "sandboxes older than 5 minutes".

It polls the local Daytona Watch API every 30s and prints one line per newly
detected sandbox.

**Requires `http://127.0.0.1:8000` to be up** (the local "Daytona Watch" app).
If the monitor prints `api-error`, that app is down — start it first. The script
prints errors rather than dying, so a restart of the API needs no monitor restart.

## Step 2: for each hit, diagnose

Work from cheapest falsification to most expensive:

1. **Was it ever used?** Check the record's `last_activity_at` vs `created_at`.
   An orphan that was never driven points at the creation path; one with real
   activity points at a caller that never released it.
2. **Winner or loser?** Only logs can say. The code logs
   `Best-of-N winner: <id>` and `Best-of-N: deleted losing candidate <id>`.
   Search Logfire (project `remote-browser-dev`, filter by `service_name`) for
   the bare id, e.g. `Bgky2gyk7`. This single lookup is the highest-value check
   in the whole investigation — it decides between the two suspects below.
3. **Only if still ambiguous**, inspect the sandbox itself. CDP
   `/json/list` over the signed preview URL shows whether any page was ever
   navigated (`about:blank` only => never used).

## Open question 1: why is `delete_browser` never called?

Two concrete suspects in `getgather/browsers/backend.py`, both unproven:

1. **Cleanup window is 10x shorter than create.**
   `_cleanup_losers` (`:172`) retries `range(8)` with `sleep(5)` = **40s**.
   `_create` calls `self.client.create(params, timeout=400)`
   (`daytona_browsers.py:435`). A loser whose sandbox materializes after 40s
   gets a `delete_browser` that 404s (swallowed), then the sandbox appears with
   nobody left to delete it. Note the `B` median lifetime of 60s is consistent
   with the 40s window working in the common case.

2. **Fire-and-forget cleanup task.** `:154`:
   `asyncio.create_task(_cleanup_losers(...))` retains no reference, so the task
   can be garbage-collected mid-flight and the cleanup silently dropped.