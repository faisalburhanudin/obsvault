---
name: grabbit-remotebrowsers-cross-org-routing
description: "grabbit (Fly org yuxi-yao) cannot reach remotebrowser's Flycast address (org remote-browsers) — must use Tailscale for the browser backend"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9e96f3a8-4006-48b5-a757-5b5ab50cfc0e
  modified: 2026-07-23T16:35:35.283Z
---

Fly org topology for the browser-backend connection:
- **grabbit** app is in Fly org **`yuxi-yao`** (6PN prefix `fdaa:1f:35a0`).
- **remotebrowser** and **tap-connect** apps are in org **`remote-browsers`** (6PN prefix `fdaa:40:80eb`).
- `remotebrowser`'s private-ingress/Flycast address is `fdaa:40:80eb:0:1::2028`.

Fly 6PN / Flycast private addresses only route **within the owning org**. So grabbit (yuxi-yao) **cannot** reach `fdaa:40:80eb:0:1::2028` — packets black-hole and connections silently time out (~symptom: sign-in hangs at "Start sign in process" until the 600s Playwright timeout). tap-connect reaches the same address fine because it's in the same org as remotebrowser.

grabbit is meant to reach the browser backend over **Tailscale** (it carries `GRABBIT_TAILSCALE_AUTHKEY`), e.g. `http://mcp.getgather.dev` (a tailnet name, resolves to `100.92.72.79`) — NOT a cross-org Flycast/6PN address.

Regression: commit #1092 renamed `GETGATHER_URL` → `REMOTEBROWSERS_URL`. grabbit code now reads `GRABBIT_REMOTEBROWSERS_URL` (`apps/grabbit/src/server/config.ts`, used as `mcpUrl` in `apps/grabbit/src/server.ts`); `GETGATHER_URL` is dead/unreferenced. grabbit deploy **v186** (2026-07-23) activated the renamed code path pointing at the unreachable `::2028`, breaking remote-browser tests (e.g. Grabbit - Amazon CA). Fix: set `GRABBIT_REMOTEBROWSERS_URL` to a tailnet-reachable URL, or roll back to the v185 image.
