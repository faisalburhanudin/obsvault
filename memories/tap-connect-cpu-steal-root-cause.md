---
name: tap-connect-cpu-steal-root-cause
description: "tap-connect sidecar freezes were Fly shared-CPU host throttling (steal), driven by uncached BeautifulSoup pattern loading"
metadata: 
  node_type: memory
  type: project
  modified: 2026-08-12T15:10:25.227Z
  originSessionId: e758bd30-1f9e-40e3-aa5b-3d39a87d4f58
---

Root cause of the `tap-connect-mock-flyfleet` (tcmf) test failures, found
2026-08-12: **Fly host CPU throttling**, not the network and not the fleet.

`/proc/stat` field 8 (`steal`) was 42.6% of accounted CPU against only 6.7%
user time on a `shared-cpu-2x` VM. The sidecar froze for **10.5 contiguous
minutes** — proven by probing `127.0.0.1:23456/health`, which timed out 22×
at a 30s ceiling while p50 was 10ms. Localhost has no network, so the process
itself was not running.

Demand source: `getgather/zen_distill.py::load_distillation_patterns` parsed
**470 HTML files on every MCP tool call, uncached**. The "~3.5s of blocking
CPU" figure recorded here originally was wall-clock measured *while the VM was
throttled*; benchmarked on a quiet VM with `process_time` the real cost is
**~0.22s of CPU per call** (86% BeautifulSoup parsing). It ran as the first
statement of both generic entry points (`mcp/dpage.py:679` and `:755`). Safe to
cache because the sole reader of `Pattern.pattern` — `distill()` — deepcopies
each tree, and nothing mutates the returned list. Fixed with
`@lru_cache(maxsize=8)`; upstreamed as PR #1440 off `origin/main`.

Result: CPU per tool span **11.8s -> 1.34s** (8.8x) at 7x the throughput;
steal **42.6% -> 8.7%**; RSS 510 -> 382 MiB. Treat those per-tool-call figures
as wall-clock-contaminated too — a 0.22s function cannot account for a 10.5s
drop, so the gap was steal, not compute. The steal that remained afterwards was
`memory_xray`, not the workload: see
[[tap-connect-shared-cpu-burst-exhaustion]]. Dedicated CPU was NOT needed.

**Why:** Every symptom pointed at the network (connect timeouts, CDP handshake
timeouts, 1011 keepalive ping timeouts) and none of it was the network. A
frozen process produces timeouts identical to network faults because timeouts
run on the wall clock, which keeps advancing while the process is descheduled.

**How to apply:** Steal is invisible to guest PSI (`/proc/pressure/cpu` read
`full=0` throughout) because there is no in-guest contention — the vCPU simply
is not scheduled. Always compare two `/proc/stat` reads; the cumulative figure
is a since-boot average and read 42.6% *after* throttling had already stopped.
Do NOT re-arm an RSS watchdog for this: restarting burns startup CPU and
deepens the next throttle. Related: [[tap-connect-getgather-memory-leak]],
[[tap-connect-test-failures-fleet]], [[logfire-project-split-remotebrowser]].
