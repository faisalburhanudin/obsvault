---
name: podman-backend-being-removed
description: The Ansible role deliberately omits podman; the podman browser backend is slated for removal upstream.
metadata:
  type: project
---

The `remotebrowser` Ansible role installs no podman, no `podman.socket`, and no
`CONTAINER_HOST` on purpose (stated 2026-08-24). The podman browser backend is
being removed from remotebrowser, so provisioning it would be work thrown away.

**Why:** `BROWSER_BACKEND` still defaults to `podman` in
`getgather/browsers/settings.py`, so the gap looks like an oversight when
auditing the role against CI's `container.yml` job — it isn't.

**How to apply:** Don't propose podman install, socket setup, `chrome-live`
image pre-pull, or the `machine.slice` cgroup limits from `deploy-dokku.md`.
Treat the podman-only settings (`CONTAINER_HOST`, `MAX_IDLE_MINUTES`,
`MASSIVE_*`/`OXYLABS_*`, `MAXMIND_*`) as out of scope for
[[remotebrowser-app-config-gap]] too.

This is about the `remotebrowser` role only. The separate `podmanfleet`
role installs podman on purpose — podman-fleet *is* the container fleet
manager. See [[podmanfleet-target-decisions]].
