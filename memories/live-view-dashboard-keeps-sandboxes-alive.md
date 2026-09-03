---
name: live-view-dashboard-keeps-sandboxes-alive
description: The live-view dashboard keeps Daytona sandboxes alive indefinitely; its own idle-gate probe counts as sandbox activity
metadata:
  type: project
---

Root cause of long-lived Daytona sandboxes (investigated 2026-08-25).

An open live-view dashboard keeps every live sandbox alive for as long as the tab
stays open. Two paths, same root:

1. `GET /live/{id}` -> `get_live_view_url()` -> `_get_last_activity()` ->
   `sandbox.process.exec(cp History && sqlite3 ...)`. A toolbox exec IS Daytona
   activity, so the gate meant to prevent live views from extending life is the
   thing extending it.
2. The returned signed preview URL streams noVNC on port 8080 straight from the
   viewer's browser to Daytona. That traffic never touches our services, so it
   produces NO logs while still counting as activity.

Consequence: idle never passes ~60s -> `auto_stop_interval` (15 min) never fires ->
`auto_delete_interval` (60 min *continuously stopped*) never starts counting.

Signature in the Watch API: sandboxes created minutes apart share `last_activity_at`
to within ~1s, then all go idle in the same second and are reaped together when the
tab closes.

`LIVE_VIEW_MAX_IDLE_SECONDS = 3600` does not help - an hour is far longer than the
15-min auto-stop, so the gate never blocks. Note `_get_info` already avoids this
exec on purpose ("Status polling must not extend the sandbox lifecycle");
`get_live_view_url` was not given the same treatment.

**Why:** explains the cost in [[daytona-lifetime-baseline]] (85% from long-lived sandboxes).
**How to apply:** when measuring sandbox lifetime, close the dashboard first, or the
measurement creates the leak. Related: [[daytona-watch-api-deleted-at-artifact]]
