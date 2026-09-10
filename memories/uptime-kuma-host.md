---
name: uptime-kuma-host
description: uptime-kuma runs in Docker on the tailnet host kuma (100.91.247.83); it has no write API — monitors are created over Socket.IO only
metadata:
  type: project
---

Set up 2026-09-10. Debian 12 host `kuma`, tailnet IP `100.91.247.83`.
Web UI: http://100.91.247.83:3001

```
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data \
  --name uptime-kuma louislam/uptime-kuma:2
```

Docker was installed via get.docker.com. `kuma` has passwordless sudo
(`/etc/sudoers.d/kuma`) and is in the `docker` group.

**No REST API for monitors.** Checked the routes in v2.5.3
(`/app/server/routers/`): the only HTTP endpoints are read-only —
`/api/badge/...`, `/api/status-page/...`, `/api/entry-page`, and `/metrics`
(Prometheus, needs an API key). Every write — add/edit/delete a monitor —
goes over **Socket.IO** with an admin login. So "add a monitor by API" means
writing a socket.io client, not curl. The v2 "API key" feature only unlocks
`/metrics`; it does not grant CRUD.

To monitor Fly 6PN targets from this container, see
[[reach-fly-6pn-from-docker]].
