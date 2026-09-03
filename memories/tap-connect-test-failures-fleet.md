---
name: tap-connect-test-failures-fleet
description: "Dead ends ruled out for tap-connect test failures: flyfleet-dev capacity, Tailscale/Flycast routing, and the 27 orphan-teardown skips"
metadata:
  node_type: memory
  type: project
  originSessionId: fbb4db15-4e0e-4140-a05e-0c58ab759f73
  modified: 2026-08-12T08:47:03.493Z
---

**Superseded as a cause — root cause was CPU steal, see
[[tap-connect-cpu-steal-root-cause]].** Kept so these leads are not re-chased.

Failure modes seen on tcmf tests (taxonomy still accurate): `httpx.ConnectTimeout`
on `/api/v1/browsers/{id}`, `CDP WebSocket handshake timed out after 120s`,
`fastmcp ToolError`, `received 1011 keepalive ping timeout`, and rarely
`FleetError: App already exists and is deleted` (422). Tests run every 5 min but
failures take 5-8 min, so runs overlap and compound — still unfixed and worth
serializing.

Ruled out on 2026-08-12:

- **flyfleet-dev capacity/concurrency was NOT the problem.** Despite one machine
  with `soft_limit = 20`, it was near-idle during failures: **5 requests/min,
  max duration 1.12-2.09s**. It was never the bottleneck.
- **Tailscale/Flycast routing was NOT the problem.** From tcmf, 20/20 probes
  resolved and connected cleanly to a native Flycast address
  (`fdaa:40:8b11:0:1::297d`), sub-100ms, no Tailscale hop — despite tailscaled
  owning `/etc/resolv.conf` (nameserver `100.100.100.100`) and logging
  `CONNMARK revision 0 not supported` every ~5 min. That log noise is a red
  herring.
- **The "exactly 27 orphan teardown skips per reconcile" signal was the wrong
  app entirely** — it came from prod `flyfleet` (env `demo`), not flyfleet-dev,
  which had zero. See [[logfire-project-split-remotebrowser]].

**Why:** All three looked compelling and all three were wrong; the decisive
evidence came from probing `127.0.0.1` inside tcmf, which removed the network
from the picture completely.

**How to apply:** loguru -> Logfire drops `opt(exception=True)`, so pass the
exception as a kwarg (`error=f"{type(e).__name__}: {e}"`) to get a queryable
attribute. When a deployed code change seems absent from logs, check you are
querying the right Logfire project *before* suspecting a stale deploy.
