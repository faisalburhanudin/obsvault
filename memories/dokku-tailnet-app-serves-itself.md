---
name: dokku-tailnet-app-serves-itself
description: Deploy pattern for putting a Dokku app on the tailnet — the container runs its own tailscaled + `tailscale serve`, so Dokku domains must be disabled, and each app gets its own node name via TS_HOSTNAME.
metadata:
  type: project
---

Settled 2026-09-07 on the GCE VM `fleet` (`gcloud compute ssh fleet
--project=bluewizard --zone=us-central1-c`), tailnet `pitta-pound.ts.net`.
Reuse this shape for the next apps.

The app exposes itself, not Dokku's nginx. `start.sh` starts `tailscaled
--tun=userspace-networking`, runs `tailscale up --hostname="$TS_HOSTNAME"`,
then `tailscale serve --bg http://127.0.0.1:$PORT`, and binds uvicorn to
`127.0.0.1`. The app becomes its own tailnet node at
`https://<TS_HOSTNAME>.pitta-pound.ts.net` with a real Let's Encrypt cert
from Tailscale.

So Dokku vhosts must be off:

```bash
dokku domains:clear-global
dokku domains:disable <app>
dokku config:set <app> TS_AUTHKEY=<oauth-client-secret> TS_HOSTNAME=<app>
```

**Why:** a Dokku global domain cannot work here. MagicDNS resolves only exact
node names, so `<app>.<host>.pitta-pound.ts.net` does not resolve — verified.
And with the app on `127.0.0.1` inside the container, any Dokku vhost just
returns 502, because nginx cannot reach a loopback-only listener. Chasing that
502 is the trap; the fix is to stop using nginx, not to fix it.

**How to apply:** name the tailnet node after the app, not the host, so many
apps share one VM. `TS_ADVERTISE_TAGS` defaults to `tag:fly` in this repo —
wrong on a Dokku host, and a tag the OAuth client does not own fails with
`400 requested tags ... are invalid or not permitted` (see
[[podmanfleet-target-decisions]]). Watch for duplicate nodes: an ephemeral
node re-registers on restart and Tailscale appends a suffix, so `fleet-gateway`
and `fleet-gateway-1` can both be live and serving. If the name does not open
in a browser, see [[magicdns-fails-under-browser-doh]]. Same host as
[[podmanfleet-target-decisions]]; the other Dokku host is
[[dokku-staging-access]].
