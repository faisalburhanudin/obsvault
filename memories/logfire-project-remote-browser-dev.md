---
name: logfire-project-remote-browser-dev
description: Browser/Daytona telemetry lives in the Logfire project remote-browser-dev, shared by three services; remote-browser-pro is nearly empty
metadata:
  type: reference
---

All browser and Daytona telemetry is in Logfire project `remote-browser-dev`
(id `54787524-bd54-4d85-bd44-64a2bd5d4d8b`, org `getgather`). `remote-browser-pro`
looked like the production project but held only 12 records in 24h — do not use it.

Three services share `remote-browser-dev`, so always filter on `service_name`:
- `remote-browser` — our getgather server, the one that creates Daytona sandboxes
  (`AsyncDaytona.create`, `AsyncSandbox.delete`). CDP relay span is `HTTP /cdp/{browser_id}`.
- `fleet-gateway-dev` / `daytona-fleet-dev` — separate stack, own Daytona sandboxes.
  Its relay span is `HTTP /api/v1/browsers/{browser_id}/cdp`.
- `flyfleet` — third stack.

Attributing cost to "us" requires the service filter: on 2026-08-24 the single most
expensive sandbox (854 min, 34% of the day) was created by `daytona-fleet-dev`, not us.
Identify the creator by the `AsyncDaytona.create` span whose duration brackets the audit
create time -- `fleet-gateway-dev` only proxies CDP for it later, so the relay span names
the wrong service. Note `daytona-fleet-dev` reports `deployment_environment='local'` but
creates sandboxes around the clock, so that label does not mean a laptop.

The Daytona SDK is instrumented, but the spans carry only `{component, method}` —
no sandbox id and no browser_id. See [[daytona-uuid-to-browser-id-mapping]].
Only `remote-browser` emits per-message websocket spans via the other services;
our own relay does not, so use `[probe]` log lines for relay open/close instead.
