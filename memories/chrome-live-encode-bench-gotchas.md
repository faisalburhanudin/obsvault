---
name: chrome-live-encode-bench-gotchas
description: Traps that silently corrupt bench/ffmpeg-encode runs - browser-trace self-contention, cgroup v1 only, and tunnel drops destroying results.
metadata:
  type: project
---

**browser-trace competes with the benchmark.** The recorded tab hits
`_MAX_RECORDING_SECONDS` (10 min) partway through a long sweep and browser-trace
encodes its own recording, throttled to `ENCODE_CPU_PERCENT`. That steals ~50% of
the one core and silently turns an arm into a contention measurement - it cost a
whole `threads-1` arm on 2026-08-28. The harness now waits for an idle box before
each arm and flags any arm whose idle floor or median (machine CPU - ffmpeg share)
gap exceeds 5%. Trust the `CONTAMINATED` marker; re-measure those arms.

**The chrome-live image has cgroup v1 only** - no `/sys/fs/cgroup/cgroup.controllers`.
Use the `cpu,cpuacct` hierarchy (`cpu.cfs_quota_us` / `cpu.cfs_period_us`), not v2
`cpu.max`. Move the process via `cgroup.procs` (not v1's `tasks`, which moves one
thread). Task migration can be denied even when the quota files are writable, so
probe it with a throwaway child before trusting the arm.

**A dropped WireGuard tunnel looks exactly like a crashed benchmark**, because
`fly ssh` then returns empty output. That combination deleted a browser while its
results were still only inside it. The harness now retries the liveness probe and
the result fetch, validates the JSON is non-empty, and keeps the browser when
retrieval fails. `flyctl` reaching a machine over 6PN does not mean `.flycast`
resolves - check `curl http://flyfleet-dev.flycast/health` separately.

Findings from these runs: [[encode-cpu-limit-mechanisms]].
