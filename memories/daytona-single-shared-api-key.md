---
name: daytona-single-shared-api-key
description: One personal Daytona API key (bin.jiang, dtn...29b) is used by every service and by developer laptops, so billing cannot be attributed
metadata:
  type: project
---

As of 2026-08-25, the whole Daytona org runs on **one API key**: `dtn...29b`, owned by
`bin.jiang@heyario.com`. In a 2026-08-24 audit pull, 4188 of 4188 events and all 937
sandbox creates carried that single actor and key. There is no second credential.

That one key is used from 7 source IPs, covering both servers and laptops:
- `79.127.255.249` (492 creates), `79.127.185.46` (95), `79.127.255.232` (42),
  `79.127.185.35` — deployed hosts.
- `204.93.239.41` (171) — separate host.
- `182.2.45.193`, `182.8.195.186` — Indonesian residential, i.e. developer machines.
Logfire corroborates: `deployment_environment='local'` emits real
`AsyncDaytona.create` / `AsyncSandbox.delete` (services `daytona-fleet-dev`,
`daytona-fleet-local`).

**Why:** Daytona attributes cost to the API key, so with one key the billing dashboard
cannot separate production from dev from a laptop. Source IP is the only discriminator,
and it is not in the billing table — it is only in the audit log.

**How to apply:** Before trusting any per-service Daytona cost number, join the billing
UUID to the audit log and split by `ipAddress` (see
[[daytona-uuid-to-browser-id-mapping]]). The real fix is a separate API key per
environment and service. Also note local dev spends the same budget, so a laptop left
running costs production money. Related: [[daytona-lifetime-baseline]],
[[logfire-project-remote-browser-dev]].
