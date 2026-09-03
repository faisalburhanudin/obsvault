---
name: build-keep-chrome-live-dev
description: How to build and publish the chrome-live image to keep-chrome-live-dev, and why a local amd64 podman build does not work.
metadata:
  type: project
---

## Use Fly's remote builder, not a local build

`fly.toml` has no `app` key, so `-a` is always required.

The Dockerfile does **not** fetch custom-chromium itself. `Dockerfile:118`
bind-mounts the 173 MB tarball out of the build context and **hard-fails**
(`FATAL: ... not found in build context`) on amd64 without it. It is
`.gitignore`d, so a fresh worktree does not have it. CI works because
`publish.yml` curls it from this repo's public GitHub Release (tag
`custom-chromium-<version>`, asset + `.sha256`) into the context *before*
building — that release fetch is a CI step, not a Dockerfile step.

For a local dev-only build, either hardlink the tarball in from another
checkout, or comment the block out: `root/etc/s6-overlay/s6-rc.d/chromium/run`
falls back to Chrome when `custom-chrome` is missing and `switch-browser custom`
fails cleanly, so the image still boots. Never commit that comment-out — CI
needs the block live.

```bash

# publish :latest WITHOUT creating machines  <-- what flyfleet consumes
fly deploy -a keep-chrome-live-dev --build-only --push --image-label latest

# or build+run machines on the app itself (for direct poking)
fly deploy -a keep-chrome-live-dev --remote-only
```

**Never put the 173 MB tarball in the build context.** It made `transferring
context` take 25+ min on a ~25 KB/s uplink and the run died with
`error releasing builder: deadline_exceeded`. Fetched on the builder instead it
is 21.5 s including the sha256 check. Also note flyctl gives no progress output
if you pipe it through `tail`.

**Use `--build-only --push`.** Plain `fly deploy` creates two HA machines on an app
that normally has **zero** — `keep-chrome-live*` apps exist only to hold an image
in the Fly registry (CI never deploys, it only pushes; see
[[chrome-live-ci-deploys-by-registry-push]]). Plain `fly deploy` also tags
`deployment-<id>`, not `:latest`, so flyfleet would not pick it up.

## Local podman amd64 does NOT work

- `RUN uv sync --frozen --group dev` in the `browser-trace-builder` stage dies with
  `qemu: uncaught target signal 11`. `uv` is a Rust binary QEMU mistranslates.
- Rosetta is not usable for builds: `podman machine inspect` reports
  `Rosetta: true`, but the VM's `/proc/sys/fs/binfmt_misc/` registers only
  `qemu-x86_64-static`. Everything goes through QEMU.
- Workaround that did build: drop the builder stage and stub the binary, since
  `browser-trace` is the `tinyproxy-log` consumer and removing it outright
  swallows tinyproxy's log output:
  `#!/bin/sh` / `if [ "$1" = "tinyproxy" ]; then exec cat; fi` / `exec sleep infinity`
  Also neuter the CloakBrowser and custom-chromium blocks with `if false`.
  Even then Chrome is far too slow under QEMU to load a real page.
- arm64 has no browser at all: Google Chrome is amd64-only, and Ubuntu 24.04 has
  no usable Chromium deb (`chromium` has no candidate, `chromium-browser` is the
  snap transition stub `2:1snap1-0ubuntu2`).

## Reaching a running machine

noVNC binds `127.0.0.1:80` and Chrome binds `127.0.0.1:9221`, so neither is
reachable over 6PN directly. Use the forwarders — `socat` on **8080**, `cdp-proxy`
on **9222** — and pin to one machine's private IPv6 or `fly proxy` will
round-robin:

```bash
fly proxy 6080:8080 '<machine-ipv6>' -a keep-chrome-live-dev   # noVNC
fly proxy 9223:9222 '<machine-ipv6>' -a keep-chrome-live-dev   # CDP
curl -X PUT "http://127.0.0.1:9223/json/new?<urlencoded-url>"  # open a tab
```

`flyfleet-dev` has no public DNS; reach it at `http://flyfleet-dev.flycast/`
(port 80, not 8300). Its `CONTAINER_IMAGE` secret resolves to
`registry.fly.io/keep-chrome-live-dev:latest`.

## Reaching `flyfleet-dev`

`flyfleet-dev.flycast` is reachable **directly** — no `fly proxy` needed:

```bash
curl http://flyfleet-dev.flycast/health                       # -> OK <ts> GIT_REV: ...
curl -X POST http://flyfleet-dev.flycast/api/v1/admin/upgrade # -> {"marked_outdated":N,"pool_size":M}
curl http://flyfleet-dev.flycast/api/v1/browsers              # -> ["Fihv2zenj",...]
```

Full route set (`GET /openapi.json`): `GET|POST /api/v1/browsers`,
`POST|DELETE|GET /api/v1/browsers/{id}`, `.../liveview`, `.../suspend`,
`.../resume`, `POST /api/v1/admin/upgrade`, `GET /live/{id}`.

Create a browser and drive its CDP (no body; ~15s):

```bash
curl -X POST http://flyfleet-dev.flycast/api/v1/browsers
# -> {"browser_id":"Fx…","hostname":"chrome-abc123.flycast","app_state":"started",…}
# CDP is NOT proxied by flyfleet - go direct to the browser app on :9222.
# Chrome rejects any Host that is not an IP/localhost, so override it:
curl -H 'Host: localhost' http://chrome-abc123.flycast:9222/json/list
curl -H 'Host: localhost' -X PUT "http://chrome-abc123.flycast:9222/json/new?<urlenc>"
```

browser-trace's HTTP API (`/logs`, `/traffic`, `/recordings`) binds `0.0.0.0:8088`
but **8088 is not a service port** - the machine exposes only 80 and 9222 - so
neither `.flycast` nor 6PN reaches it. Hit it from inside instead:
`fly ssh console -a chrome-<id> -C "curl -s http://127.0.0.1:8088/logs"`.
6PN direct (`http://[<private-ipv6>]:9222/...`) does work for CDP.

Gotchas that cost real time: the **page-level** websocket
(`ws://…:9222/devtools/page/<id>`) 500s at the cdp-proxy - only `/json/*` works
remotely, so page CDP must be spoken inside the container to `127.0.0.1:9221`,
and that image has **no** websocket lib (no `websockets`, node is 18). Machines
**auto-suspend** and SSH traffic does not count as activity, so keep the
published port warm during long work. `chromefleet/` in the workspace is the
*docker* fleet, not this service - its routes do not apply.

flyfleet provisions each browser as **1 performance vCPU / 4 GB**, NOT the
`cpus = 4` shared / 2 GB in `chrome-live/fly.toml`. Read `fly machines list -a
chrome-<id> --json`, never that file. See `bench/ffmpeg-encode/` in the repo for
the encode-cost harness built on all of this.

There is no status/metrics endpoint (`/api/v1/admin/status`, `/metrics`, `/api/v1/pool`
all 404). Observed 2026-09-02: `{"marked_outdated":25,"pool_size":25}`, then the 25
standby machines still sat on the **old** digest 25 min later while only ~10
machines ran the new one. Outdated standbys are not eagerly recreated — but a
`POST /api/v1/browsers` right after the upgrade did come up on the new digest,
so a fresh browser is the reliable way to get the new image.

`marked_outdated` is **not** a progress meter — it counts what this call
marked, and it climbs again as the pool drains and refills (observed 4 -> 1 -> 5).
Verify a roll by reading digests instead:

`GET /api/v1/browsers` returns `[]` when nothing is assigned, so it does not show
the pool. Read digests across every `chrome-*` app instead — `fly apps list`, then
`fly machines list -a <app> --json` per app (188 apps; thread it). Interpreting the
histogram: `keep-chrome-live:latest` machines are the **prod** pool and are not part
of a dev roll, ~100 `chrome-*` apps are empty husks with no machines, and a roll in
progress shows dev apps split across the old and new digest.

Assigned browsers keep their old digest; only standby apps recycle.

If you ever do need a tunnel, `fly proxy ... -a flyfleet-dev` resolves
`flyfleet-dev.internal` (machine 6PN) and bypasses fly-proxy, so `:80` never
connects and `:8300` is reset — you must pass the private-ingress IP from
`fly ips list -a flyfleet-dev` explicitly.

## Dockerfile pins each browser-trace module by name

`Dockerfile:14` COPYs `browser-trace/*.py` one file at a time, not a directory.
Adding or renaming a module there breaks the remote build with
`failed to calculate checksum ... not found` — hit when `events.py` became
`logs.py`. Update that COPY line in the same commit as the rename.
