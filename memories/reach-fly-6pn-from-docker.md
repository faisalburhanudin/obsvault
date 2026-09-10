---
name: reach-fly-6pn-from-docker
description: Reaching a Fly 6PN address (fdaa::/8) from a Docker container on a tailnet host needs two separate fixes — tailscale accept-routes AND Docker IPv6
metadata:
  type: reference
---

To curl a Fly private IPv6 (e.g. `http://[fdaa:40:80eb:0:1::b124]/`) from inside a
Docker container on a tailnet host, two unrelated things must both be on. Fixing
only one gives a silent connection failure.

**1. Host route — Tailscale subnet routers.** The tailnet has per-Fly-org routers
that advertise the 6PN prefixes. As of 2026-09-10:

| node | prefix |
|---|---|
| tailscale-router-demo | `fdaa:40:80eb::/48` |
| tailscale-router-ci   | `fdaa:40:8a24::/48` |
| tailscale-router-dev  | `fdaa:40:8b11::/48` |
| tailscale-router-main | `fdaa:1f:35a0::/48` |
| tailscale-router-ario | `fdaa:9d:b084::/48` |

Routes are only used if the host opts in:

```
sudo tailscale set --accept-routes=true
```

Default is off, and `ip -6 route` shows no fdaa entry until it is on. List the
routers with `sudo tailscale debug netmap` (needs sudo, else empty output) and
look at peers whose `AllowedIPs` has more than the 2 self addresses.

**2. Container IPv6 — Docker.** Containers get no IPv6 by default, so the host
route does not help them. `/etc/docker/daemon.json`:

```json
{"ipv6": true, "fixed-cidr-v6": "fd00:dc:e400::/64", "ip6tables": true, "experimental": true}
```

plus `net.ipv6.conf.all.forwarding=1`, then restart docker. The ULA is NAT66'd
out, so Fly sees the host's tailnet address and replies fine.

Trap: `fixed-cidr-v6` must be valid hex — dockerd refuses to start and crash-loops
on something like `fd00:d0ck:...` (`k` is not hex).

Applied on the `kuma` host (100.91.247.83) — see [[uptime-kuma-host]].
