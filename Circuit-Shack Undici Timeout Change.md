Goal: increase the effective caller-side timeout from 5 minutes to 10 minutes in `circuit-shack`.

Background:

- `debug-recap-2026-03-27.md` concludes the `301s` failure is caller-side.
- The error was `HeadersTimeoutError`, which matches Undici waiting for response headers.
- `circuit-shack` uses `@modelcontextprotocol/sdk` via `@ario/connector`.
- In `circuit-shack`, the MCP transport is created without a custom fetch or dispatcher, so it inherits Undici defaults.

Relevant files:

- `/Users/faisal/workspace/src/github.com/gather-engineering/demos/apps/circuit-shack/src/server.ts`
- `/Users/faisal/workspace/src/github.com/gather-engineering/demos/apps/packages/connector/src/core/mcp-connector.ts`

Recommended fix:

Patch `circuit-shack/src/server.ts` so the Node process uses a 10-minute Undici dispatcher. This is the least invasive app-local fix and should cover the MCP connect/call path that currently inherits the 5-minute default.

Suggested patch in `src/server.ts`:

```ts
import { trace } from '@opentelemetry/api';
import { Agent, setGlobalDispatcher } from 'undici';
```

Insert near the top-level constants, after `__dirname` is defined:

```ts
const MCP_REQUEST_TIMEOUT_MS = 10 * 60 * 1000;

setGlobalDispatcher(
  new Agent({
    headersTimeout: MCP_REQUEST_TIMEOUT_MS,
    bodyTimeout: MCP_REQUEST_TIMEOUT_MS,
  })
);
```

Why this location:

- `src/server.ts` is the server entrypoint for `circuit-shack`.
- The MCP client is constructed in this process:
  - `const connector = new Connector({ ... })`
- The shared connector package eventually creates `StreamableHTTPClientTransport` in:
  - `/Users/faisal/workspace/src/github.com/gather-engineering/demos/apps/packages/connector/src/core/mcp-connector.ts`
- That transport currently does not provide a custom `fetch`, so Node/Undici defaults apply.

Alternative fix:

Instead of setting a global dispatcher, patch `packages/connector/src/core/mcp-connector.ts` to pass a custom `fetch` into `StreamableHTTPClientTransport` using an Undici `Agent` with:

```ts
headersTimeout: 600_000
bodyTimeout: 600_000
```

That is more targeted, but it touches the shared package rather than only `circuit-shack`.

Verification notes:

- I confirmed `circuit-shack/src/server.ts` currently has no Undici import or dispatcher setup.
- A plain `npm run typecheck` in `circuit-shack` is already failing for unrelated workspace resolution issues, so typecheck is not a reliable signal for this specific change in the current environment.

Expected outcome:

- MCP connect/call requests from `circuit-shack` should stop failing at the default ~300 second Undici headers timeout and instead allow up to 10 minutes.
