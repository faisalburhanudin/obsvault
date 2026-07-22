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
