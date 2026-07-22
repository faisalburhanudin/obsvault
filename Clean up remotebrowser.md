## Doppler
- chromefleet
	- dev (empty can be deleted)
	- dev_personal (empty can be deleted)
	- stg (empty can be deleted)
	- prd (empty can be deleted)
	- ci 
	- ci_gce
- corelens (actively used)
- corelens-mcp (actively used)
- demos
	- prd
	- prd_dokku (TODO: check if machine still available)
	- prd_fly (TODO: check individual)
	- prd_lambda (TODO: check individual)
	- prd_yuxi (TODO: check individual)
- flyfleet
	- github
	- fly (daytona secret missing)
	- dev (daytona secret missing)
- grabbit (check is project still exist)
- headline-hub (check is project still exist)
	- demo
	- lambda
	- daytona
- page-turner (check is project still exist)
	- demo
	- lambda
	- daytona
- remote-browser-test (still used)
- remotebrowser 
	- demo (missing secret)
	- dev (missing secret)
	- daytona
## MCP call on services
## corelens-engineering/demos
- `packages/connector/src/core/mcp-client.ts` — `callTool` L74, L103
- `packages/connector/src/core/connector.ts` — `callTool` L109/L116
- `packages/connector-sdk/src/server/router.ts` — `callTool` L108
- `packages/connector/src/brands/wayfair/wayfair-brand.ts` — `callTool` L93

## corelens-engineering/circuit-shack
- `src/server/mcpClient.ts` — `callTool` L103
- `src/server.ts` — L123, L156, L208, L309

## corelens-engineering/grabbit
- `src/server/mcpClient.ts` — `callTool` L119
- `src/server.ts` — L317, L361, L554, L602

## remotebrowser/data-portrait
- `src/server/mcp-client.ts` — `callTool` L104
- `src/server/handlers/mcp-handler.ts` — L142, L199, L234, L272, L328, L355
- `src/server/services/mcp-service.ts` — L20

## remotebrowser/return-reminder
- `src/server/mcp-service.ts` — `callTool` L120; public methods L156, L166, L210
## Sentry

### No activity (90d)

- blinds
- bluewizard-staging
- carry-co
- dataportrait
- demorewards
- firehose
- gather-sdk
- getgather-dax
- helper-web
- lilalane
- mcp-gateway
- mcp-openweathermap
- minirewards
- nestline
- proxy-service
- python
- REDACTED
- return-reminder-mobile
- starpath
- tipsy-cellar
- twinpersona

### Active

- mcp-getgather — 2 minutes ago
- flyfleet — 15 minutes ago
- headline-hub — 45 minutes ago
- circuit-shack — 1 hour ago
- grabbit — 1 hour ago
- page-turner — 1 hour ago
- tap-connect — 1 hour ago
- inboxcart — 3 hours ago
- tap-safeway — 3 hours ago
- link4points — 2 days ago
- tap-amazon — 7 days ago
- datadash — 12 days ago
- gatherextension-browser — 20 days ago
- instacart — 27 days ago
- chromefleet — ~1 month ago
- tap-walmart — ~1 month ago
- ytboard — ~1 month ago
- dashbox — ~7 weeks ago
- return-reminder — ~2 months ago
- showroom — ~2.5 months ago
- backstage — no events yet (new service)
## Domain
## corelens.ai

DNS records (from dashboard screenshot):

- **A** `data` → 66.241.125.61
- **A** `tap-swy` → 66.241.124.186
- **AAAA** `tap` → 2a09:8280:1::f9:32c3:0
- **A** `insights` → 66.241.125.77
- **AAAA** `tap-swy` → 2a09:8280:1::11d:d73f:0
- **TXT** `_fly-ownership.clorox.core…` → app-ror8wqm
- **TXT** `_fly-ownership.connect.co…` → app-gmgx92p
- **TXT** `_fly-ownership.tap-swy.cor…` → app-32832z0
- **TXT** `google._domainkey` → v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8… (trunc)
- **AAAA** `connect` → 2a09:8280:1::11e:c299:0
- **A** `tap-gmail` → 66.241.125.184
- **AAAA** `clorox` → 2a09:8280:1::135:d3c4:0
- **A** `connect` → 66.241.125.131
- **AAAA** `data` → 2a09:8280:1::152:2b5f:0
- **CNAME** `_acme-challenge.clorox` → clorox.corelens.ai.ror8wqm.flydns.net
- **A** `clorox` → 66.241.125.222
- **CNAME** `_acme-challenge.connect` → connect.corelens.ai.gmgx92p.flydns.net
- **TXT** `_dmarc` → v=DMARC1; p=none
- **AAAA** `tap-gmail` → 2a09:8280:1::116:e11:0
- **AAAA** `insights` → 2a09:8280:1::14e:2fce:0
- **CNAME** `_acme-challenge.tap-swy` → tap-swy.corelens.ai.32832z0.flydns.net
- **A** `tap` → 66.241.124.243
- **TXT** `@` → v=spf1 include:_spf.google.com ~all

## getgather.dev

DNS records (from dashboard screenshot):

- **A** `return-reminder.all` → 136.112.242.61
- **A** `grabbit.all` → 136.112.242.61
- **A** `tipsy-cellar.all` → 136.112.242.61
- **A** `circuit-shack.all` → 136.112.242.61
- **TXT** `_acme-challenge.internal` → yTAw9pePAjgtpmK0eGNtUoM4o2GnjIWpT-_V4Kr-NnU
- **A** `internal` → 34.36.208.154
- **A** `page-turner.all` → 136.112.242.61
- **A** `carry-co.all` → 136.112.242.61
- **A** `test` → 34.134.119.183
- **A** `papertrail.all` → 136.112.242.61
- **A** `api` → 34.36.208.154
- **A** `lilalane.all` → 136.112.242.61
- **A** `proxypy.all` → 136.112.242.61
- **AAAA** `metabase` → 2a09:8280:1::102:82a0:0
- **A** `nestline.all` → 136.112.242.61
- **A** `proxy` → 100.120.112.30
- **A** `grafana` → 34.134.119.183
- **A** `twin-persona.all` → 136.112.242.61
- **A** `starpath.all` → 136.112.242.61
- **A** `mtbs` → 136.112.242.61
- **A** `test2` → 34.134.119.183
- **A** `dax` → 34.134.119.183
- **A** `metabase` → 66.241.124.123
- **A** `nginx` → 34.134.119.183
- **A** `mxxn.all` → 136.112.242.61
- **A** `mcp` → 100.92.72.79
- **A** `blinds.all` → 136.112.242.61
- **A** `qpro-submit.all` → 136.112.242.61
- **A** `dataportrait.all` → 136.112.242.61
- **A** `headline-hub.all` → 136.112.242.61
- **A** `classify.all` → 136.112.242.61
- **A** `mcp-office-proxy` → 100.92.72.79
- **TXT** `@` → google-site-verification=y1-aCe0OGkQy6zFQWC5l9CXIIvk… (trunc)
- **A** `safeline-mgmt` → 35.225.18.138

## remotebrowser.ai

DNS records (from dashboard screenshot):

- **A** `@` → 66.241.125.184
- **AAAA** `@` → 2a09:8280:1::112:16a:0
- **CNAME** `www` → remotebrowser-ai.fly.dev

## For deletion

Liveness probed from public internet: corelens.ai + remotebrowser.ai hosts all
returned HTTPS 200 (live); every getgather.dev host returned 000 (no public HTTPS
response — either decommissioned or IP-gated/VPN-only).

### Strong candidates (getgather.dev — not serving, look like scratch/demo)

- **A** `test` → 34.134.119.183 — throwaway test record
- **A** `test2` → 34.134.119.183 — throwaway test record
- **A** `blinds.all` → 136.112.242.61 — demo app (shared host)
- **A** `carry-co.all` → 136.112.242.61 — demo app (shared host)
- **A** `circuit-shack.all` → 136.112.242.61 — demo app (shared host)
- **A** `classify.all` → 136.112.242.61 — demo app (shared host)
- **A** `dataportrait.all` → 136.112.242.61 — demo app (shared host)
- **A** `grabbit.all` → 136.112.242.61 — demo app (shared host)
- **A** `headline-hub.all` → 136.112.242.61 — demo app (shared host)
- **A** `lilalane.all` → 136.112.242.61 — demo app (shared host)
- **A** `mtbs` → 136.112.242.61 — demo app (shared host)
- **A** `mxxn.all` → 136.112.242.61 — demo app (shared host)
- **A** `nestline.all` → 136.112.242.61 — demo app (shared host)
- **A** `page-turner.all` → 136.112.242.61 — demo app (shared host)
- **A** `papertrail.all` → 136.112.242.61 — demo app (shared host)
- **A** `proxypy.all` → 136.112.242.61 — demo app (shared host)
- **A** `qpro-submit.all` → 136.112.242.61 — demo app (shared host)
- **A** `return-reminder.all` → 136.112.242.61 — demo app (shared host)
- **A** `starpath.all` → 136.112.242.61 — demo app (shared host)
- **A** `tipsy-cellar.all` → 136.112.242.61 — demo app (shared host)
- **A** `twin-persona.all` → 136.112.242.61 — demo app (shared host)

### Review before deleting (getgather.dev — gated, not proven dead)

Confirm the backing Fly/GCP app is gone before removing.

- **A** `dax` → 34.134.119.183 — internal tool? confirm app exists
- **A** `nginx` → 34.134.119.183 — internal tool? confirm app exists
- **A** `grafana` → 34.134.119.183 — internal tool? confirm app exists
- **A** `metabase` → 66.241.124.123 — internal tool? confirm app exists
- **AAAA** `metabase` → 2a09:8280:1::102:82a0:0 — pairs with metabase A
- **A** `api` → 34.36.208.154 — confirm app exists
- **A** `internal` → 34.36.208.154 — confirm app exists
- **TXT** `_acme-challenge.internal` → yTAw9pe… — delete only with `internal` (cert challenge)
- **A** `safeline-mgmt` → 35.225.18.138 — SafeLine WAF console; confirm still used
- **A** `proxy` → 100.120.112.30 — Tailscale IP in public DNS — leaky
- **A** `mcp` → 100.92.72.79 — Tailscale IP in public DNS — leaky
- **A** `mcp-office-proxy` → 100.92.72.79 — Tailscale IP in public DNS — leaky
