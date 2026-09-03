---
name: tap-connect-shared-cpu-burst-exhaustion
description: "tcmf steal after the lru_cache fix was driven by memory_xray itself, not by the workload or by shared-CPU burst credit"
metadata: 
  node_type: memory
  type: project
  originSessionId: c3dfb1ba-12c2-4c6f-9f58-505eb850d7d2
  modified: 2026-08-12T15:10:00.855Z
---

Measured 2026-08-12 on `tap-connect-mock-flyfleet` (tcmf, `shared-cpu-2x`).
**Supersedes an earlier draft of this note that blamed Fly shared-CPU
burst-credit exhaustion — that explanation was not needed and was wrong.**

The remaining steal was `memory_xray` (`MEMORY_XRAY_TRACEMALLOC=1` +
`MEMORY_XRAY_CENSUS=1`), left on from the leak hunt. py-spy on the live
sidecar:

- idle, no tool calls: xray was **~97%** of on-CPU Python time
- under load: **40%** (35.5 of 88.6 CPU-s per 5 min), split ~62% tracemalloc
  snapshot compare / ~33% `_type_counts` walking `gc.get_objects()`

Its cost *grows with heap size*, so it self-amplifies: bigger heap -> slower
sample -> and tracemalloc's own retained snapshots enlarge the heap. Observed
over ~1h: RSS 477 -> 713 MiB, `traced_mb` 161 -> 216 MiB, xray sample gap
65s -> 69s against a 60s interval (i.e. each sample blocked the event loop 5s
-> 9s), then steal 37% -> 49% -> 91%.

After redeploying with `MEMORY_XRAY=0`: fresh RSS 142 MiB, steal 0%.

**Why:** Two traps here. (1) The throttle lands minutes AFTER the load that
caused it, so errors anti-correlate with *concurrent* load and light windows
look inexplicably broken — that pattern is what made burst-credit look
plausible. (2) A ~5-9s synchronous event-loop block is enough on its own to
miss WebSocket keepalives, so `1011 keepalive ping timeout` does not prove
steal. Do not size hardware from measurements taken with xray on; ~40% of the
CPU and an unknown share of RSS growth are the instrument.

**How to apply:** `MEMORY_XRAY` is a pydantic `bool` (`getgather/config.py:29`)
gating the loop at `main.py:61`, so `'0'` genuinely disables it — tracemalloc
starts inside the loop and never runs. Also: do NOT re-arm
`SIDECAR_RSS_LIMIT_MB` at its 500 default; legitimate transients hit 592-713
MiB and would recycle the machine, which is the CPU-burning loop to avoid.
Related: [[tap-connect-cpu-steal-root-cause]],
[[tap-connect-getgather-memory-leak]], [[tap-connect-test-failures-fleet]].
