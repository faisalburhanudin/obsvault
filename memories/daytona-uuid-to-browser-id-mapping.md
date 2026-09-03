---
name: daytona-uuid-to-browser-id-mapping
description: Daytona sandbox UUID maps to our browser_id only by matching audit-log create time against relay-open time
metadata:
  type: reference
---

The Daytona billing dashboard reports sandbox **UUIDs**. Our code names sandboxes
`chromium-<browser_id>`. There is no direct lookup between the two:

- Logfire **never** logs the sandbox UUID (verified by full-text search over all records).
- The Daytona audit log **never** logs the sandbox name — `metadata` is always null.
- `GET /api/sandbox/{uuid}` 404s once the sandbox is auto-deleted (TTL 60 min after stop),
  so live lookup only works for sandboxes still alive.

Working method: **correlate on create timestamp.** The audit log `create` event time
matches the Logfire relay-open / `cdp websocket connect` time for the same sandbox to
within a second, which is unique enough to map them one-to-one.

Audit API notes beyond what the research doc says:
- `from` / `to` ISO params work and are the right way to scope the pull
  (`?from=...&to=...&page=N&limit=100`). `targetId` and `action` filters return 400.
- `limit=250` returns 400; use `limit<=100`. Paging past the real page count returns 500.
- Daytona's own **auto-stop and auto-delete emit no audit events** — only API calls made
  by our SDK appear. This is why pairing create->delete in the audit log undercounts
  long-lived sandboxes, on top of the window-truncation problem already documented.

Related: [[logfire-project-remote-browser-dev]], [[daytona-lifetime-baseline]].
