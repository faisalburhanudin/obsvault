---
name: chrome-live-hosts-layer-is-inert
description: chrome-live's /etc/hosts ad-block layer never runs; --proxy-server makes Chrome delegate DNS, so only the tinyproxy fnmatch filter blocks anything.
metadata:
  type: project
---

The `/etc/hosts` layer appended by `entrypoint.sh:11` (~458k `0.0.0.0` lines) is
inert for all browser traffic. Cause, in order of importance:

1. `--proxy-server=http://127.0.0.1:8119` (`chromium/run`) makes Chrome use
   **proxy-side DNS**: it never calls getaddrinfo for the target, it writes the
   hostname as a string (`CONNECT host:443`). True since that flag was added.
2. The deploy-time-injected `Upstream http <creds>@pr.oxylabs.io:7777` in
   `/app/tinyproxy.conf` (NOT in the repo copy) means tinyproxy resolves only
   `pr.oxylabs.io` and forwards the hostname too. Nothing in the chain resolves
   an ad domain.

So 100% of ad blocking is the `Filter`/`FilterType fnmatch` list at
`/home/user/tinyproxy-filter.txt`.

Traps found while verifying:
- `getent hosts doubleclick.net` returns the REAL IPv6 and looks like a broken
  hosts file. It isn't — `getent ahostsv4` returns 0.0.0.0. hblock writes only
  IPv4 lines, so an AAAA-specific lookup falls through to DNS.
- If hosts entries *were* honored, `0.0.0.0` means "this host" on Linux, so a
  blocked request lands on the container's own noVNC server on :80 and returns
  HTTP 200 with an HTML page instead of failing.
- A filtered request is unambiguous only over plain HTTP: tinyproxy answers
  `HTTP/1.1 403 Filtered`. Over HTTPS/CONNECT it is indistinguishable from an
  Oxylabs upstream failure (both `ERR_TUNNEL_CONNECTION_FAILED`) — always
  classify with a plain-HTTP probe.
