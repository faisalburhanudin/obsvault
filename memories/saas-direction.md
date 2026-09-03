---
name: saas-direction
description: Strategic goal to sell the remotebrowser stack as raw browser infrastructure SaaS (self-serve/PLG)
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a057734-e911-495f-89d9-69d62c53cd39
---

As of 2026-06-28, the goal is to commercialize the stack (getgather + flyfleet + chrome-live) as a **raw remote-browser infrastructure** SaaS, **self-serve / PLG**, competing head-on with Browserbase and Steel Cloud (NOT primarily selling the extraction/MCP layer — that's a Phase 2 premium upsell).

**Why:** funded commodity market; chosen edges are dedicated-VM isolation (already built in flyfleet — one Fly app per browser_id), self-host↔cloud continuity, and the extraction moat as an upsell.

**How to apply:** Roadmap lives in `research/saas-roadmap.md`; feature parity in `research/feature-gaps.md`. Hard pre-launch blockers (Phase 0): flyfleet has NO auth and a flat un-scoped browser_id namespace (`flyfleet/src/app.py`, `models.py`) → need API keys, tenant isolation, usage metering, quotas, billing, self-serve UI before any feature work. Competitor research: keep Steel/Browserbase analysis competitor-only per [[competitor-research-steel-only]].
