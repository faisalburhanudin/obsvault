# Task: replace in-container Tigris credentials with pre-signed S3 upload URLs

Rework how chrome-live recordings reach object storage. Today the container holds bucket
credentials and uploads with boto3. Instead, the container should hold **no credentials**:
the control plane (remotebrowser or flyfleet) generates a pre-signed PUT URL and invokes the
upload inside the container over `podman exec` or `fly ssh console -C`.

The upload itself is just a PUT:

```sh
curl -X PUT -T /tmp/recordings/<recording_id>.mp4 -H "Content-Type: video/mp4" "<S3_URL>"
```

The caller mints `<S3_URL>` like this (Tigris, S3-compatible):

```python
import boto3

s3_client = boto3.client(
    "s3",
    endpoint_url="https://t3.storage.dev",
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
)

url = s3_client.generate_presigned_url(
    ClientMethod="put_object",
    Params={
        "Bucket": AWS_BUCKET,
        "Key": "<folder/file>",
        "ContentType": "video/mp4",
    },
    ExpiresIn=3600,
)
```

## Repos

- **chrome-live** — `/Users/faisal/workspace/src/github.com/remotebrowser/chrome-live`,
  branch `feat/recording-upload-toggle`, draft PR #34. Recording lives in
  `browser-trace/` (`recording.py`, `upload.py`, `server.py`, `main.py`); the binary is a
  PyInstaller onefile built in the Dockerfile.
- **flyfleet** — `/Users/faisal/workspace/src/github.com/corelens-engineering/flyfleet`,
  branch `feat/recording-upload-arming` (pushed, no PR). Control plane: pool of one-machine
  Fly apps, CDP proxy, and a browser-trace passthrough.

## What exists now (the part being replaced)

chrome-live:
- `browser-trace/upload.py` — boto3 client, two gates (credentials present + `upload_enabled`).
- `TIGRIS_BUCKET/ACCESS_KEY_ID/SECRET_ACCESS_KEY/ENDPOINT_URL/REGION` in `browser-trace.conf`,
  templated from container env by `root/etc/s6-overlay/s6-rc.d/browser-trace/run`.
- `GET|POST /recordings/config` on port 8088 — the in-memory `upload_enabled` + `browser_id`.
- Background upload at tab close, `drain_uploads()` on shutdown, `upload_key` in the sidecar.
- `boto3` in `browser-trace/pyproject.toml`.

flyfleet:
- `TIGRIS_*` + `RECORDING_UPLOAD_ENABLED` settings, passed into each machine's env at create time.
- `FlyApp.arm_recording_upload()`, called from `prepare_browser_trace()` on every CDP connect.
- Port 8088 declared as a machine service (flycast) + `browser_trace_url` in the app-info dict.

**Keep** (do not undo): the `/api/v1/browsers/{id}/trace/{path}` passthrough in flyfleet — the
new flow needs it to discover recordings — and the encoder timing fix in `recording.py`
(frame arrival times → ffmpeg concat playlist → `_OUTPUT_FPS`), which is unrelated to uploads.

**Expected to go away**: `upload.py`, the `TIGRIS_*` plumbing in the image, `/recordings/config`,
the toggle/`browser_id` state, `arm_recording_upload`, `RECORDING_UPLOAD_ENABLED`, and the
`boto3` dependency (which also shrinks the onefile binary and removes a bundling risk).

## Design questions to settle first

1. **Who triggers the upload, and when?** A recording only finalizes when its tab closes, so
   the caller can't presign in advance — it doesn't know the recording id yet. Suggested flow:
   `GET …/trace/recordings` to list, presign a key per recording id, then exec the PUT. Confirm
   this against how remotebrowser wants to drive it.
2. **Plain `curl` or a thin CLI?** `curl` needs no new code in the image. A small
   `browser-trace upload <id> <url>` subcommand would buy retries, existence checks, and a
   sidecar update — at the cost of code and a bigger binary. Recommend curl unless retries matter.
3. **Who records that a recording was already uploaded?** Nothing in the container tracks it once
   the sidecar's `upload_key` goes away. Control-plane DB is probably the right home.
4. **Local retention** — recordings stay on disk (`/tmp/recordings/<id>.mp4` + `<id>.json`) and
   `GET /recordings/{id}/video` keeps serving them. Decide whether an uploaded file is deleted.
5. **Key naming** — the caller now picks the `Key`, so the old "container can't know its
   browser id" problem disappears. Keep `<browser_id>/<recording_id>.mp4` unless there's a reason not to.

## Gotchas that will bite

- **`Content-Type` must match the signed value exactly** (`video/mp4`), or S3 returns
  `SignatureDoesNotMatch`. Same for the bucket/key/expiry.
- `curl -T` sets `Content-Length` and may send `Expect: 100-continue`; add `--fail` so a failed
  PUT is a non-zero exit rather than a silent HTML error body.
- **`ExpiresIn=3600`** — a URL minted before a long session can expire before the upload.
- Machines only pick up new env/services **at create time**, so config changes need
  `POST /api/v1/admin/upgrade` and a pool recycle, not a restart.
- Screencast frames are change-driven; a static page records almost nothing. Test with an
  animating page (`scripts/recording_smoke_test.py --animated`).
- flyfleet's CDP proxy rewrites target ids to `<browser_id>@<targetId>` and only strips the
  prefix back off for `Target.getTargetInfo` — `attachToTarget`/`closeTarget` need the bare id.
- `.env` values may be quoted; browser-trace's conf parser strips quotes (`main.py:61`).
- Transient and expected: `503` on claim right after a deploy (pool refilling), and CDP closing
  with `4502 Failed to get debugger URL` on a machine whose Chrome is still booting — wait for
  `curl http://<ip>:9222/json/version` to return 200.

## How to test

Everything is on flycast, so the org WireGuard tunnel must be up, and use `http://`, not
`https://` (no TLS handler on those services).

```sh
# 1. flyfleet unit tests. settings.py validates on import and .env.test is absent (gitignored).
cd /Users/faisal/workspace/src/github.com/corelens-engineering/flyfleet
printf 'BACKEND=fly\nCONTAINER_IMAGE=ghcr.io/remotebrowser/chrome-live\nFLY_API_TOKEN=test\nFLY_ORG_SLUG=test-org\n' > .env.test
uv run pytest tests/test_browser_trace.py tests/test_browser_trace_proxy.py -q
# plain `uv run pytest` drives real Fly machines — slow and costly

# 2. end-to-end recording (chrome-live). Needs updating for the presigned flow.
cd /Users/faisal/workspace/src/github.com/remotebrowser/chrome-live
./scripts/recording_smoke_test.py --browser-id rec-mine-1 --animated --scroll-seconds 10

# 3. credentials, independent of the container
./scripts/check_tigris_creds.py --prefix rec-mine-1/

# 4. what the browser saw (app name is in the script output)
fly logs -a chrome-xxxxxx --no-tail | grep -aE '\[upload\]|\[recording\]'

# 5. manual, via the passthrough
curl -X POST http://flyfleet-dev.flycast/api/v1/browsers/rec-mine-1
curl http://flyfleet-dev.flycast/api/v1/browsers/rec-mine-1/trace/recordings
curl -X DELETE http://flyfleet-dev.flycast/api/v1/browsers/rec-mine-1
```

`scripts/recording_smoke_test.py` drives CDP through flyfleet's proxy, opens a page, animates
or wheel-scrolls it, closes the tab, and prints the upload state. It will need reworking:
drop the `/recordings/config` read, and instead list recordings, presign, and PUT.

Verify the video itself, not just that a file exists — download and `ffprobe` it. Video
duration should track the session (e.g. 14.3s of video for a 14.8s session); a wildly different
number means the encoder timeline regressed.

## How to deploy

```sh
# flyfleet (control plane). Builds from the WORKING TREE, not from git.
cd /Users/faisal/workspace/src/github.com/corelens-engineering/flyfleet
fly deploy -a flyfleet-dev
curl -s http://flyfleet-dev.flycast/openapi.json | grep -o '"/api/v1/browsers[^"]*"' | sort -u

# chrome-live image for the dev pool. --build-only --push avoids starting a machine in the
# image-holder app; --remote-only gets a native amd64 build instead of QEMU on darwin.
cd /Users/faisal/workspace/src/github.com/remotebrowser/chrome-live
fly deploy -a keep-chrome-live-dev --remote-only --build-only --push --image-label latest

# then recycle the pool so machines pull the new image
curl -X POST http://flyfleet-dev.flycast/api/v1/admin/upgrade
```

`flyfleet-dev`'s `CONTAINER_IMAGE` is `registry.fly.io/keep-chrome-live-dev:latest`. Confirm
machines actually moved by digest, since every machine shows the same `:latest` tag:

```sh
fly machines list -a chrome-xxxxxx --json | python3 -c "import json,sys; print([m['image_ref']['digest'] for m in json.load(sys.stdin)])"
```

Recycling is slow by design: `upgrade` only flips DB state, the GC loop runs every ~10 min
(`pool/manager.py`), and outdated apps retire only once `standby_count >= POOL_SIZE`, so old
suspended machines linger for a while.

**Do not** trigger chrome-live's `publish.yml` via `workflow_dispatch` to test — it pushes
`:latest` to `keep-chrome-live` (prod), `-dev`, and `-ci`. It normally runs on `main` only.