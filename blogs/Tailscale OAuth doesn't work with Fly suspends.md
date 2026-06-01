
I run a JVM-based service on Fly.io that connects to a Postgres database over Tailscale. To cut costs, I decided to switch from `auto_stop_machines = "stop"` to `"suspend"`. Suspend freezes the machine's RAM state instead of shutting it down completely, so it resumes in seconds rather than waiting for a cold JVM startup.

```toml
[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = "suspend"
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]
```

**The problem**

After the first suspend cycle, the service came back up but couldn't reach the database. The logs pointed at Tailscale:

```
2026-06-01T04:23:52Z app[90803249cd50e8] ord [info] Received error: PollNetMap: initial fetch failed 404: node not found
2026-06-01T04:23:58Z proxy[90803249cd50e8] sin [error][PR04] could not find a good candidate within 40 attempts at load balancing
2026-06-01T04:23:59Z app[90803249cd50e8] ord [info] open-conn-track: timeout opening (TCP 100.113.233.32:43332 => 100.103.204.49:5432) to node [TSA3X]; online=yes, lastRecv=16m24s
2026-06-01T04:24:10Z app[90803249cd50e8] ord [info] Received error: PollNetMap: initial fetch failed 404: node not found
```

**The diagnosis**

I checked the Tailscale admin console and the machine's node had disappeared from the tailnet entirely. The clue was `404: node not found`: the node wasn't just offline, it was gone.

It turns out that OAuth auth keys create ephemeral nodes by default. Ephemeral nodes are designed for short-lived workloads: Tailscale automatically garbage-collects them once the machine goes offline. That's fine for a stopped machine, but it breaks suspend. The machine is meant to come back, and when it does, its Tailscale node no longer exists.

**The fix**

I updated the Tailscale startup command in the Docker entrypoint to force a non-ephemeral node:

```sh
/app/tailscale up \
  --authkey="${TAILSCALE_AUTHKEY}?ephemeral=false&preauthorized=true" \
  --hostname="metabase" \
  --advertise-tags="tag:fly" \
  --accept-routes &
```

Two query params matter here:
- `ephemeral=false`: the node persists in the tailnet while the machine is suspended, so it can reconnect cleanly on resume.
- `preauthorized=true`: skips the manual approval step in the Tailscale admin console on each new node registration.