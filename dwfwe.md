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

