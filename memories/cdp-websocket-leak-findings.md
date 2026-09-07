---
name: cdp-websocket-leak-findings
description: A leaked CDP relay websocket keeps a Daytona sandbox alive forever via its own 60s ping; confirmed on browser Egau2d7t
metadata:
  type: project
---

An abandoned sign-in leaves the CDP relay socket open, and that socket alone keeps the
sandbox alive. Confirmed 2026-09-07 on browser `Egau2d7t` (Logfire `remote-browser-dev`,
trace `9f45728e6a792145c8174431d5bf1c8f`).

Mechanism: `getgather/browsers/router.py:157` opens the relay's socket to the Daytona
preview proxy with `ping_interval=60, ping_timeout=30`. While open it pings every 60s —
traffic at Daytona's API boundary, well inside the 15-min auto-stop, and it writes no logs.
`daytona-fleet/daytonafleet/cdp.py:305,506` has the same setting, so the migration does
**not** fix it.

Which connection leaks: the one opened by `remote_zen_dpage_with_action` on the MCP
tool-call path. It returns "Continue with sign in at …" and leaves the browser open on
purpose so the user can finish. Nothing closes it if the user never returns. `ffc1997`
(*fix: close cdp connection*, #1473) added `close_remote_browser()` only in `post_dpage`,
so it misses this path.

Timeline: sandbox created 21:07 (UTC+7), user abandoned the Amazon `transactionapproval`
page at 21:33, sandbox still alive and gettable at 05:06 next day. No DELETE ever logged.

**Why:** this is the missing cause in [[daytona-auto-stop-never-fires]]. No
inside-the-sandbox theory is needed — the ping is at the boundary Daytona counts.

**How to apply:** three signatures identify a leaked relay in Logfire.
1. The relay span (parent of the `[CDP]` / `[cdp-log]` lines) has **no row** in `records`.
   A span exports on close, so a missing parent with exported children means still open.
   Caveat: a killed or redeployed process also loses the parent.
2. **No `[CDP] Client disconnected`** for that browser id. A healthy browser logs one after
   every connect.
3. `[cdp-log] tab_traffic` stopping is **not** the socket closing. Those come from
   browser-trace inside the sandbox and only fire when the tab has network traffic; a
   static error page produces none.

To prove it, use [[local-cdp-leak-test-setup]]: count open relay sockets and watch
`sandbox.last_activity_at` over a 20-min idle window. Advancing in 60s steps with no other
traffic confirms the ping. Do not disable `ping_interval` as the fix — it is also the
dead-peer detection.

Related: [[live-view-dashboard-keeps-sandboxes-alive]] (a smaller, separate leak),
[[daytona-delete-404-on-live-sandbox]], [[logfire-project-remote-browser-dev]]
