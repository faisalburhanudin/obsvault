# tap-connect + remotebrowser sidecar (experiment)

Runs `remotebrowser` (FastAPI, `:23456`) and the tap-connect Express server
(`:3001`) in the same Fly machine, so `TAP_CONNECT_REMOTEBROWSERS_URL` is
`http://127.0.0.1:23456` and the tap-connect → remotebrowser API hop never
leaves the machine.

**What this does and does not remove:** only the *API* hop is collapsed. The
browsers themselves still live in Daytona / Browserbase / an upstream Chrome
Fleet, so the CDP websocket is still a remote connection. Removing that hop
would need `BROWSER_BACKEND=podman`, which needs podman-in-Fly and a much
bigger VM — out of scope here.

## Files

| File | Purpose |
| --- | --- |
| `sync-remotebrowser.sh` | Vendors `pyproject.toml` / `uv.lock` / `getgather` from a remotebrowser checkout into `.remotebrowser/` (gitignored) so it lands in the build context |
| `Dockerfile.sidecar` | Three stages: remotebrowser venv, tap-connect pnpm build, and a `python:3.13-slim` runtime with Node 22 grafted in |
| `start-sidecar.sh` | Boots Tailscale (optional), uvicorn, then the Node server; exits if either dies |
| `fly.mock-flyfleet.toml` | Fly app `tap-connect-mock-flyfleet` — upstream Chrome Fleet via `CHROMEFLEET_URL` |
| `fly.mock-browserbase.toml` | Fly app `tap-connect-mock-browserbase` — `BROWSER_BACKEND=browserbase` |
| `fly.mock-daytona.toml` | Fly app `tap-connect-mock-daytona` — `BROWSER_BACKEND=daytona` |

All three are org `remote-browsers-dev` and share `Dockerfile.sidecar`; they
differ only in which browser backend remotebrowser is pointed at.

The Node app lives at `/srv/app/apps/tap-connect`; `/app` is remotebrowser's
(`getgather`, `.env`, `data/`) because the venv holds an editable install
pointing there.

## Syncing with main

Both repos deploy from a `mock` branch, not `main` — `mock` carries the sidecar
files *and* repoints Amazon at `amazon-mock.dataportrait.app` (demos:
`src/config/amazon_us.json`, `packages/remotebrowser/src/retailers.ts`;
remotebrowser: `getgather/mcp/amazon.py` plus ~64 pattern files). **Never deploy
`main` directly** — it silently sends these apps at the real amazon.com. Merge
`main` into `mock` instead.

```sh
DEMOS=~/workspace/src/github.com/corelens-engineering/demos
RB=~/workspace/src/github.com/remotebrowser/remotebrowser

# 1. App code
cd "$DEMOS"
git checkout mock && git fetch origin && git merge origin/main

# 2. Sidecar code
cd "$RB"
git checkout mock && git fetch origin && git merge origin/main

# 3. Confirm the mock overrides survived the merge (each must print a match)
cd "$DEMOS"
rg -n 'amazon-mock\.dataportrait\.app' \
  apps/tap-connect/src/config/amazon_us.json packages/remotebrowser/src/retailers.ts
rg -n 'amazon-mock\.dataportrait\.app' "$RB/getgather/mcp/amazon.py"

# 4. Re-vendor and deploy all three
./apps/tap-connect/sync-remotebrowser.sh "$RB"
for t in flyfleet browserbase daytona; do
  fly deploy -c apps/tap-connect/fly.mock-$t.toml
done
```

If step 3 prints nothing, the merge took `main`'s side — fix it before
deploying. See the Verify section below for the post-deploy check that catches
the same mistake.

## Deploy

```sh
cd ~/workspace/src/github.com/corelens-engineering/demos

# 1. Vendor the remotebrowser sources (re-run whenever that repo changes)
./apps/tap-connect/sync-remotebrowser.sh ~/workspace/src/github.com/remotebrowser/remotebrowser

# 2. Create the app (pick one tenant)
fly apps create tap-connect-mock-flyfleet -o remote-browsers-dev

# 3. Secrets. Each .env-* file holds only TAP_CONNECT_* plus that backend's
#    credentials — nothing that would shadow the [env] block.
fly secrets import -a tap-connect-mock-flyfleet --stage < apps/tap-connect/.env-flyfleet

# 4. Deploy (Fly's remote builder; build context is the workspace root)
fly deploy -c apps/tap-connect/fly.mock-flyfleet.toml
```

The other two tenants follow the same four steps:

| App | Config | Secrets |
| --- | --- | --- |
| `tap-connect-mock-flyfleet` | `fly.mock-flyfleet.toml` | `.env-flyfleet` |
| `tap-connect-mock-browserbase` | `fly.mock-browserbase.toml` | `.env-browserbase` |
| `tap-connect-mock-daytona` | `fly.mock-daytona.toml` | `.env-daytona` |

Verify:

```sh
for app in tap-connect-mock-flyfleet tap-connect-mock-browserbase tap-connect-mock-daytona; do
  echo "=== $app"
  curl -s "https://$app.fly.dev/health"; echo
  fly ssh console -a "$app" -C "/opt/venv/bin/python -c \"
import urllib.request
from getgather.config import settings
from getgather.mcp.amazon import AMAZON_US
print('  backend:', settings.CHROMEFLEET_URL or settings.BROWSER_BACKEND)
print('  amazon_us domain:', AMAZON_US.domain)
print('  rb loopback:', urllib.request.urlopen('http://127.0.0.1:23456/health', timeout=5).read())
\""
done
```

`amazon_us domain` must read `amazon-mock.dataportrait.app` on all three. If it
says `amazon.com`, a `main` merge clobbered the override and the app is hitting
real Amazon.

Health can take ~90s after `fly deploy` returns — uvicorn mounts ~40 MCP bundles
before it binds, so poll rather than checking once.

**Do not use `fly deploy --local-only` on Apple silicon.** Fly is amd64; cross
building the client bundle under emulation kills esbuild mid-run
(`The service was stopped: write EPIPE` after a Go runtime dump). The remote
builder is native amd64 and takes ~2 min.

## Build and run locally

```sh
podman build -f apps/tap-connect/Dockerfile.sidecar -t tap-connect-sidecar:local .
podman run --rm -p 3001:3001 --env-file apps/tap-connect/.env \
  -e BROWSER_BACKEND=browserbase -e BROWSERBASE_API_KEY=... \
  localhost/tap-connect-sidecar:local
```

`curl localhost:3001/health` hits tap-connect; remotebrowser's `/health` is on
`127.0.0.1:23456` inside the container only (never published).

## Backend selection

remotebrowser reads its own settings from **unprefixed** env names, so each
tenant differs only in these:

| Tenant | `[env]` in the toml | Credentials in the `.env-*` file |
| --- | --- | --- |
| flyfleet | `CHROMEFLEET_URL = 'http://flyfleet-dev.flycast'` | — |
| browserbase | `BROWSER_BACKEND = 'browserbase'` | `BROWSERBASE_API_KEY` |
| daytona | `BROWSER_BACKEND = 'daytona'` | `DAYTONA_API_KEY`, `DAYTONA_SNAPSHOT` |

Which one actually loaded:

```sh
fly ssh console -a <app> \
  -C "/opt/venv/bin/python -c \"from getgather.config import settings; print(settings.CHROMEFLEET_URL or settings.BROWSER_BACKEND)\""
```

Gotchas:

- **`PORT` is shared.** Fly's `[env] PORT = '3001'` would otherwise be picked up
  by `getgather.config.Settings`; `start-sidecar.sh` scopes `PORT` per process,
  so change remotebrowser's port via `REMOTEBROWSER_PORT`, never `PORT`.
- `CHROMEFLEET_URL` is the first branch in `create_backend()`, so any value
  **overrides** `BROWSER_BACKEND` silently. Keep it out of the browserbase and
  daytona secrets.
- Fly secrets override `[env]`. A secret named `TAP_CONNECT_REMOTEBROWSERS_URL`
  or `CHROMEFLEET_URL` would defeat the toml with no error — the `.env-*` files
  are kept clean of both.
- `BROWSER_BACKEND=daytona` fails validation at import time if `DAYTONA_API_KEY`
  or `DAYTONA_SNAPSHOT` is missing — the machine crash-loops, it does not degrade.
- `BROWSER_BACKEND=podman` is remotebrowser's default and will not work in this
  image (no podman installed). Always set it explicitly.
- Tailscale only starts when `TAP_CONNECT_TAILSCALE_AUTHKEY` is set.
- Fly creates 2 machines by default with `min_machines_running = 1`; each runs
  its own remotebrowser. `fly scale count 1` for a clean latency measurement.
