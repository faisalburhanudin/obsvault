---
name: encode-cpu-limit-mechanisms
description: Measured comparison of ways to cap browser-trace's MP4 encode - cpulimit is a duty cycle, not a ceiling; only -preset reduces total work.
metadata:
  type: project
---

Measured 2026-08-28 on a flyfleet-dev browser (1 perf vCPU / 4 GB) with
`bench/ffmpeg-encode` in `SWEEP=1` mode. Baseline: ~90% ffmpeg share, ~45 s spike,
~41 core-s for ~2000 frames.

**`cpulimit -l 50` (the shipped `ENCODE_CPU_PERCENT`) does not lower the peak.**
It SIGSTOP/SIGCONTs, so the trace is a 0-100% square wave that merely *averages*
53.8%: the machine still sat above 95% for **16%** of the encode and fully stopped
for 10%. The v1 cgroup `cpu.cfs_quota_us` at the same setpoint held a flat 49.5%
and never exceeded 74%. Same cost (1.02x vs 1.03x the control's core-seconds), and
the quota tracks its setpoint more accurately (25% arm: 28.4% vs 24.8%). If the
point of the cap is headroom for Chrome, these are not equivalent.

**Rate limits conserve work** - every throttled arm cost within 5% of 41 core-s, so
halving height roughly doubles width. **`nice +19` and `-threads 1` do nothing** on
one core (98.2% each): niceness only yields to a competitor, and there is no second
core for threads to spread across. **Only `-preset veryfast` moves to a lower work
curve**: 0.48x the work, 19.9 s instead of 45.3 s, for +0.6% file size at the same
CRF. Composing preset + a 50% cap is the untested configuration worth running.

See [[chrome-live-encode-bench-gotchas]] for how to run it without corrupting the
numbers.
