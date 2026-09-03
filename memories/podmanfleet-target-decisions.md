---
name: podmanfleet-target-decisions
description: How the podmanfleet target is wired — Lima VM "fleet", Doppler fleet/prd_podmanfleet, tag:podman-fleet, private repo cloned with a token passed via git env config.
metadata:
  type: project
---

Settled 2026-08-28, deployed and verified:

- The Lima VM is named `fleet`, not `podmanfleet`: Ansible warns when a host and
  a group share a name, and the group is `podmanfleet`.
- Secrets live in Doppler project `fleet`, branch config `prd_podmanfleet` under
  `prd`. The project is shared with the other `*-fleet` services, so the branch
  config is what keeps them separate. It holds `TS_OAUTH_SECRET` and
  `GITHUB_TOKEN`.
- The tailnet tag is `tag:podman-fleet`, set in
  `inventory/group_vars/podmanfleet.yml`. The OAuth client in that Doppler
  config owns only that tag; the role's `tag:remotebrowser` default fails with
  `400 requested tags ... are invalid or not permitted`.
- `podman-fleet` is private, so the clone authenticates with
  `http.https://github.com/.extraheader` supplied through `GIT_CONFIG_COUNT`
  env vars — a tokenized remote URL would persist the token in the host's
  `.git/config`.
- `ghcr.io/remotebrowser/chrome-live` pulls without a registry login.

**Why:** none of this is derivable from the repo, and two of the values were
found only by a failed deploy.

**How to apply:** `tailscale up` runs under `no_log: true`, so an auth failure
is censored; probe it with `tailscale up --auth-key file:<path>` to see the real
message. See [[podman-backend-being-removed]] for why the sibling
`remotebrowser` role still installs no podman.
