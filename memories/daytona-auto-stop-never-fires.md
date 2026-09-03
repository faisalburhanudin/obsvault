---
name: daytona-auto-stop-never-fires
description: Daytona auto_stop_interval does not stop abandoned sandboxes; the probe built to explain it is not running
metadata:
  type: project
---

`AUTO_STOP_MINUTES = 15` does not stop an abandoned sandbox. Confirmed 2026-08-31: browser
`Bhadhd6u2` ran 94 min after its client left, ~85 of them past the idle deadline, with
`browser-trace` emitting `[cdp-log] tab_traffic` from inside every 1-4 min. `auto_delete`
never applies either — it counts continuously-*stopped* time. Written up as
`docs/issues/04-auto-stop-never-fires.md`. **Cause not established.**

**Why:** this is the backstop for every teardown bug. With it working, a missed DELETE costs
15 minutes; without it, hours. It is why [[daytona-delete-404-on-live-sandbox]] got expensive.

**How to apply:** the open question is whether Daytona's idle clock counts activity *inside*
the sandbox or only at its API/exec/preview-proxy boundary — different causes, different
fixes. `getgather/browsers/daytona_probe.py` (commit 86b4ec7) was built to answer it but has
emitted nothing since 2026-08-25 06:36; turn it back on first. Note its `[probe]` lines read
process-local state only, so they are never evidence a sandbox is alive. See also
[[live-view-dashboard-keeps-sandboxes-alive]].
