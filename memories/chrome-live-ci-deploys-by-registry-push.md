---
name: chrome-live-ci-deploys-by-registry-push
description: chrome-live CI never runs fly deploy; it pushes an image to each Fly app's registry, which is why the fleet runs many different digests at once.
metadata:
  type: project
---

`.github/workflows/publish.yml` builds, pushes to ghcr, then calls
`remotebrowser/shared-github-actions/push-fly-image@v1` per app via matrix
(`keep-chrome-live` / `-dev` / `-ci`). That action does only:

```bash
flyctl auth docker
docker tag <image> registry.fly.io/<app>:latest
docker push registry.fly.io/<app>:latest
```

There is **no `fly deploy` and no `fly machine update` anywhere in CI.** The
`keep-chrome-live*` apps are image holders and normally run zero machines;
flyfleet creates new `chrome-*` apps from `CONTAINER_IMAGE`
(`registry.fly.io/keep-chrome-live-dev:latest` for dev).

Consequence: existing machines keep whatever digest they were created with, so at
any moment the fleet spans many builds. Measured 2026-08-18: **7 distinct digests
live across ~110 `chrome-*` apps**, with baked blocklists dating from 2026-05-13
through 2026-08-17 (430,928–464,299 entries). Practical impact on ad coverage was
small — only 2 of 74 observed hosts differed between oldest and newest.

To roll the dev pool onto a new image:
`fly deploy -a keep-chrome-live-dev --build-only --push --image-label latest`
then `POST http://flyfleet-dev.flycast/api/v1/admin/upgrade` (recycles *standby*
apps only; already-assigned browsers keep their old image).

See [[build-keep-chrome-live-dev]].
