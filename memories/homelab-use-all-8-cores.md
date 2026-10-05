---
name: homelab-use-all-8-cores
description: Homelab WSL2 VM now has 8 cores / 50 GB; the user wants lidar jobs to use all 8, not taskset 0-3
metadata:
  type: feedback
---

The homelab (100.122.215.60) WSL2 VM is set to `processors=8`, `memory=50GB`
in `C:\Users\faisa\.wslconfig` (host: Ryzen 9 5950X). Old READMEs say 32 cores
and pin jobs to 4 (`taskset -c 0-3`) because the VM died with all 32 busy.

On 2026-10-05 the user said "use all 8 cores" for terrarupa lidar jobs.

**Why:** the crash was with 32 cores; the VM is now capped at 8, so the old
4-core rule wastes half the box.

**How to apply:** pin to `0-7`, keep the cgroup memory cap and `nice`. PDAL
stages are mostly single-threaded, so fill the cores by running jobs side by
side, limited by memory (keep the total under ~44 GB). Do not change
`.wslconfig` (it needs `wsl --shutdown`). See [[terrascope-homelab-deploy]].
