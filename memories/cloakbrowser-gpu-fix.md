---
name: cloakbrowser-gpu-fix
description: CloakBrowser chrome-live variant renders blank VNC ONLY under emulation (podman on Apple Silicon); works fine on native amd64 with the committed --use-gl=swiftshader
metadata: 
  node_type: memory
  type: project
  originSessionId: e46f5f07-bcf6-4c1e-9b70-b3f60fa75893
---

The CloakBrowser variant (`Dockerfile.cloakbrowser` + `cloakbrowser/root/.../chromium/run`) shows a blank white noVNC screen with `FATAL: GPU process isn't usable. Goodbye.` crash-loop **only when run under QEMU user-mode emulation** (podman with `--platform=linux/amd64` on Apple Silicon). Verified on Fly (native amd64, app `chrome-live-cloak` in `remote-browsers` org): the committed `--use-gl=swiftshader` version renders and CDP :9222 works perfectly, 0 GPU crashes. A `--disable-gpu --disable-software-rasterizer` variant also works on amd64 but is NOT needed — the committed code is fine as-is.

**Why:** CloakBrowser is amd64-only. On Apple Silicon podman runs it via qemu-user-static (not Rosetta, despite Rosetta being enabled — the base image ships qemu-user-static and grabs binfmt). QEMU can't emulate Chromium's multiprocess GPU/sandbox model (ptrace/prctl "not implemented"), so SwiftShader's GPU process crash-loops. This is purely an emulation artifact, not a flag bug.

**How to apply:** NEVER diagnose this image via podman/docker on the Mac — QEMU breaks Chromium's GPU independently of any flag, producing false "VNC broken" symptoms. Always build/verify on native amd64 (`fly deploy --dockerfile Dockerfile.cloakbrowser`; Fly uses amd64 Depot builders). If a peer reports "VNC not working," first ask whether they tested under emulation. Separate open issue: the cloak run script drops the base's `--proxy-server=http://127.0.0.1:8119`, so it bypasses tinyproxy allow/denylist.

**Second, distinct bug — noVNC IPv4-only bind (NOT cloak-specific, lives in BASE image):** the base `novnc` s6 run does `websockify --web /usr/share/novnc/ 80 localhost:5900` — bare `80` binds `0.0.0.0:80` (IPv4 only). Fly's private network (`.internal`/`.flycast`/`fly proxy`) is IPv6-only (6PN), so noVNC :80 is unreachable over the private net → "Connection reset by peer". PROVEN 2026-07-14 by deploying the base/main image to `chrome-live-cloak`: base VNC resets over `fly proxy` identically to cloak. Fix = bind `[::]:80` (dual-stack). Added as a cloak override `cloakbrowser/root/etc/s6-overlay/s6-rc.d/novnc/run` (+ Dockerfile chmod), but the real fix belongs in the base image since it affects base too. Note `:5900` (raw Xvnc) already binds IPv6 and works over 6PN; only the noVNC web port was broken.
