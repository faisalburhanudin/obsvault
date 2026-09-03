---
name: logfire-read-token-not-in-doppler
description: Doppler holds only Logfire write tokens; the Logfire query API needs a read token that must be created in the Logfire UI
metadata:
  type: reference
---

Doppler has no Logfire **read** token. Every `*LOGFIRE_TOKEN` secret across all
projects/configs (remotebrowser, flyfleet, page-turner, headline-hub, corelens,
demos) is a **write** token for the SDK. Passing `remotebrowser/dev`'s
`LOGFIRE_TOKEN` to the query API returns `{"detail":"Invalid token"}` (checked
2026-08-31).

To run scripts against the Logfire query API (e.g. `scripts/cdp_socket_report.py`),
create a read token in the Logfire UI under the project's settings, then store it
as `LOGFIRE_READ_TOKEN`. Related: [[logfire-project-remote-browser-dev]].
