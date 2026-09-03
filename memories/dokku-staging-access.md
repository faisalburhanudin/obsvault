---
name: dokku-staging-access
description: "How to SSH into the Dokku staging host to run dokku commands (config, apps, etc.)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: aee352da-5ab9-4748-917b-2dfcf3567217
---

The Dokku staging host for `remotebrowser` is the Tailnet node `lambda-remotebrowser` at `100.97.220.119`, SSH on port 2222 as user `dokku`. The app name is `remotebrowser`.

Authenticate with the dedicated key `~/.ssh/dokku_lambda` (generated for this; pubkey registered on the host via `dokku ssh-keys:add faisal`).

Shell alias in `~/.zshrc`: `dokku-lambda` expands to the full ssh command, so you can run e.g. `dokku-lambda config:show remotebrowser`.

Run dokku commands like:

```bash
ssh -i ~/.ssh/dokku_lambda -o IdentitiesOnly=yes dokku@100.97.220.119 -p 2222 apps:list
ssh -i ~/.ssh/dokku_lambda -o IdentitiesOnly=yes dokku@100.97.220.119 -p 2222 config:show remotebrowser
ssh -i ~/.ssh/dokku_lambda -o IdentitiesOnly=yes dokku@100.97.220.119 -p 2222 config:set remotebrowser KEY=value
```

Staging runtime config is set directly via `dokku config:set` — NOT Doppler (Doppler is only used by the Fly.io deploy path in `deploy-fly.yml`). The `deploy-staging.yml` workflow only git-pushes to this host over Tailscale using GitHub secrets.
