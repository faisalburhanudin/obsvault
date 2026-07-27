Add a new Fly.io deployment variant of `tap-connect` (this app: `apps/tap-connect`) that talks to a Browserbase-backed Remote Browser instead of Daytona or the default backend.

## Context

`remotebrowser/remotebrowser` stood up a new Fly app, `remotebrowser-browserbase`, in the `yuxi-yao` organization, running the `BrowserbaseBackend`. See `remotebrowser/remotebrowser` PRs #1413 and #1418.

The app is deployed and health-checked, and a real `create_browser` / `delete_browser` round trip against the live Browserbase API has been verified.

It is pinned to a single Fly machine because the backend keeps browser sessions in an in-memory dictionary. That is a concern for the `remotebrowser` repository, not this repository, but it explains why the app must not be scaled to multiple machines.

## Goal

Mirror the existing `tap-connect-daytona` deployment pattern:

- `apps/tap-connect/fly.daytona.toml`
    
- `.github/workflows/deploy-fly-daytona.yml`
    

However:

- Name the new Fly app `connect-browserbase`, matching the `connect-clorox` naming style rather than the `tap-connect-<variant>` style.
    
- Point it to `remotebrowser-browserbase` instead of `remotebrowser-daytona`.
    

Before making changes, inspect the existing files and verify that the assumptions in this prompt are still correct. Adjust the implementation when the repository’s current structure differs from this prompt.

## Steps

### 1. Create the Fly configuration

Create:

`apps/tap-connect/fly.browserbase.toml`

Copy the structure of `apps/tap-connect/fly.daytona.toml` and set:

```toml
app = 'connect-browserbase'
org = 'yuxi-yao'
```

Keep everything else—including the build configuration, deployment strategy, `http_service`, and VM configuration—identical to `fly.daytona.toml` unless there is a concrete reason to diverge.

### 2. Create the deployment workflow

Create:

`.github/workflows/deploy-fly-browserbase.yml`

Copy `.github/workflows/deploy-fly-daytona.yml` and replace the Daytona-specific references with Browserbase-specific references, including:

- Workflow name
    
- Comment header
    
- `filter_file: "fly.browserbase.toml"` in the change-detection step
    
- Concurrency group names, such as `deploy-browserbase-...`
    
- Deployment configuration:
    

```bash
--config apps/${{ matrix.app }}/fly.browserbase.toml
```

Keep the same secrets-management approach used by the Daytona deployment: secrets must be managed manually using `flyctl secrets set`, not synchronized through Doppler. Review the comment in `deploy-fly-daytona.yml` for the rationale.

Ensure the workflow is valid YAML and follows the current conventions used by the other Fly deployment workflows in the repository.

### 3. Create the Fly app

Create the Fly app before attempting to deploy it. `flyctl deploy` does not create missing applications.

Run:

```bash
fly apps create connect-browserbase --org yuxi-yao
```

If the application already exists, verify that it belongs to the correct organization and continue without attempting to recreate it.

### 4. Configure secrets

Inspect the secret names currently configured on the Daytona variant:

```bash
fly secrets list --app tap-connect-daytona
```

Only the secret names will be visible. Do not attempt to infer, extract, or guess their values.

The Browserbase deployment should use:

```env
TAP_CONNECT_TENANT=browserbase
TAP_CONNECT_REMOTEBROWSERS_URL=https://remotebrowser-browserbase.fly.dev
```

`browserbase` is only an environment label. It is not currently in the `TENANTS` map in `src/config/tenants.ts`, so it should fall back to the default branding, matching the current behavior of the Daytona tenant.

The remaining secrets should generally mirror the values used by `tap-connect-daytona`, unless there is a specific reason for the Browserbase deployment to use different values—for example, a distinct app key scoped to the Browserbase backend.

Expected secret keys may include:

- `TAP_CONNECT_REMOTEBROWSERS_APP_KEY`
    
- `TAP_CONNECT_DATABASE_URL`
    
- `TAP_CONNECT_QUESTIONPRO_JWT_SECRET`
    
- `TAP_CONNECT_TAP_RESEARCH_API_TOKEN`
    
- `TAP_CONNECT_WHITELISTED_EMAILS`
    
- `TAP_CONNECT_CINT_CALLBACK_TOKEN`
    

Check `.env.example` and the current application configuration for the authoritative full list.

**Do not guess any secret values. When the secrets are required, stop and let me know exactly which values are needed. I will provide an `.env` file containing them.**

After I provide the `.env` file:

1. Inspect it and map only the required variables to the new Fly app.
    
2. Do not print secret values in logs, comments, commit messages, pull request descriptions, or the final response.
    
3. Set the secrets using `flyctl secrets set --app connect-browserbase`.
    
4. Do not commit the `.env` file or any secret values to Git.
    
5. If the supplied `.env` file is missing a required value, tell me which variable is missing instead of guessing.
    

### 5. Deploy and verify

Deploy the application:

```bash
flyctl deploy \
  --config apps/tap-connect/fly.browserbase.toml \
  --app connect-browserbase
```

Verify the health endpoint:

```text
https://connect-browserbase.fly.dev/health
```

Then verify that `connect-browserbase` can reach `remotebrowser-browserbase`.

Prefer an end-to-end retailer-linking flow when practical. At minimum, confirm that:

- The application starts successfully.
    
- The health endpoint succeeds.
    
- The application does not report startup or connection errors related to `TAP_CONNECT_REMOTEBROWSERS_URL`.
    
- The Remote Browser endpoint is reachable from the deployed Fly application.
    
- Relevant Fly logs do not contain configuration, authentication, or networking errors.
    

Do not treat a successful health check alone as proof that the Remote Browser integration works.

## Finalization

Review the final diff and confirm that it contains only the intended deployment configuration and workflow changes.

Commit and push the changes to `main` once the workflow file exists, so future changes touching `fly.browserbase.toml` automatically deploy the Browserbase variant, matching the behavior of the other tenant variants.

In the final report, include:

- Files created or modified
    
- Fly app creation result
    
- Names of secrets configured, without their values
    
- Deployment result
    
- Health-check result
    
- Remote Browser connectivity verification
    
- Any assumptions, divergences, or unresolved issues
    
- The commit hash pushed to `main`