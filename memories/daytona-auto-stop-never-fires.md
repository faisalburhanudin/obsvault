---
name: daytona-auto-stop-never-fires
description: Daytona auto_stop_interval does not stop abandoned sandboxes; cause found 2026-09-07 — the CDP relay's own 60s websocket ping
metadata:
  type: project
---

`AUTO_STOP_MINUTES = 15` does not stop an abandoned sandbox. Seen 2026-08-31 on browser
`Bhadhd6u2` (ran 94 min after its client left, ~85 past the idle deadline) and again
2026-09-07 on `Egau2d7t` (abandoned 21:33, still alive 05:06 next day, no DELETE ever
logged). `auto_delete` never applies either — it counts continuously-*stopped* time.
Written up as `docs/issues/04-auto-stop-never-fires.md`.

**Cause found 2026-09-07: the leaked CDP relay socket pings Daytona every 60s.** See
[[cdp-websocket-leak-findings]] for the evidence and the three Logfire signatures. The old
open question — whether Daytona's idle clock counts activity *inside* the sandbox or only
at its API/exec/preview-proxy boundary — is answered: the boundary is enough, no
inside-sandbox theory is needed. The `[cdp-log] tab_traffic` lines from inside were a red
herring; they stop while the socket stays open.

**Why:** this is the backstop for every teardown bug. With it working, a missed DELETE
costs 15 minutes; without it, hours. It is why [[daytona-delete-404-on-live-sandbox]] got
expensive.

**How to apply:** fix the leak, not the ping — `ping_interval` is also dead-peer detection.
The uncovered path is `remote_zen_dpage_with_action`; `ffc1997` closed only `post_dpage`.
`daytona-fleet` carries the same `ping_interval=60`, so the migration does not fix this.
`getgather/browsers/daytona_probe.py` (commit 86b4ec7) has emitted nothing since
2026-08-25 06:36 and is no longer needed to answer the cause. Note its `[probe]` lines read
process-local state only, so they are never evidence a sandbox is alive. See also
[[live-view-dashboard-keeps-sandboxes-alive]] for the smaller, separate leak.
