---
name: daytona-watch-api-deleted-at-artifact
description: Watch API deleted_at equals observed_at, so it is poll-detection time, not real deletion time; use last_activity_at instead
metadata:
  type: reference
---

In the local Daytona Watch API (`http://127.0.0.1:8000/api/sandboxes`), `deleted_at`
is always exactly equal to `observed_at`. It records when the poller *noticed* the
sandbox was gone, not when it died. Clusters of identical `deleted_at` values
(e.g. 10 sandboxes sharing one microsecond timestamp) are poll batches, not bulk
deletes.

Also: `state` goes stale after deletion (stays `started`), and `auto_stop_interval`
is not in the payload at all — reading it returns None, which is not evidence that
auto-stop is disabled.

Measure real lifetime with `created_at` -> `last_activity_at`. Treat
`deleted_at - last_activity_at` (~90-100s observed) as poll lag.

Related: [[daytona-uuid-to-browser-id-mapping]], [[daytona-lifetime-baseline]]
