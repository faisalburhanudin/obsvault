---
name: logfire-project-split-remotebrowser
description: Which Logfire project each remotebrowser/flyfleet deployment logs to — the two halves of a tcmf request are split across two projects
metadata: 
  node_type: memory
  type: reference
  modified: 2026-08-12T08:46:44.195Z
  originSessionId: e758bd30-1f9e-40e3-aa5b-3d39a87d4f58
---

Logfire telemetry for these services is split across projects, and the two
halves of a single tcmf request land in *different* ones:

| service_name | deployment_environment | Logfire project |
|---|---|---|
| `remote-browser` | `mock-flyfleet` (the tcmf sidecar) | `getgather` |
| `flyfleet` | `demo` (prod app `flyfleet`, org remote-browsers) | `getgather` |
| `flyfleet` | `dev` (app `flyfleet-dev`) | `remote-browser-dev` |
| `tap-connect` | `production` | both `getgather` and `remote-browser-dev` |

Filter by `deployment_environment`, never by `service_name` alone — `flyfleet`
appears in both projects as two different deployments.

**Why:** This cost hours. The "Orphan teardown skipped, exactly 27 per
reconcile" signal was read as evidence about `flyfleet-dev`, but it came from
the **prod** `flyfleet` app (env `demo`, `vcs...revision: main`).
`flyfleet-dev` had **zero** orphan skips. A code change deployed to
flyfleet-dev could never have shown up in the project being queried, which
also produced a false "the deploy didn't take" conclusion.

**How to apply:** Confirm which instance you are looking at before drawing
conclusions: `SELECT DISTINCT service_instance_id, deployment_environment,
otel_resource_attributes->>'vcs.repository.ref.revision' ...`. tcmf's sidecar
sets `ENVIRONMENT=mock-flyfleet`; `CHROMEFLEET_URL=http://flyfleet-dev.flycast`.
Related: [[tap-connect-cpu-steal-root-cause]].
