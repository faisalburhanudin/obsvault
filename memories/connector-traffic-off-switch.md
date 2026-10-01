---
name: connector-traffic-off-switch
description: How to stop and restart tap-connect (connector) sync traffic by setting max sync capacity in the prod DB
metadata:
  type: reference
---

Turn connector traffic off or on with one DB row. No deploy is needed. The app reads it on every request.

- DB: `grabbit` on `100.103.204.49:5432`, user `postgres` (Tailscale; creds in `~/.pgpass`). This is prod, so confirm first: [[feedback_confirm_before_db_commands]].
- Row: `tap_connect_runtime_settings` where `key = 'tap_connect_max_sync_capacity'`.
- Off: `value = '0'`. On: `value = '20'` (normal value and code default).
- Check: `curl -s https://connect.corelens.ai/health`. `availableCapacity` = max − active syncs, so 20 means idle and 0 means off.
- To stop traffic without cutting active syncs, wait until `availableCapacity` is 19 or more, then set it to 0. Syncs that already have a reservation keep it until they finish or expire (10 min at most).
- Done on 2026-10-01: off at 02:50 UTC, back on at 02:57 UTC, using a curl watcher plus `safe-write.sh --expect 1`.
