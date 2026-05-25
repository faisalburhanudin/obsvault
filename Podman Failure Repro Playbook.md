Use this to reproduce the suspected Podman runtime/networking failure before deciding whether moving from LXC to VM will prevent it.

## Goal

We want to test these hypotheses:

- [ ] `Podman 4.3.1` is the main problem
- [ ] Running Podman inside LXC is the main problem
- [ ] Host stress or helper-process death is the trigger
- [ ] Moving to a VM reduces or removes the issue

---

## General Rules

- [ ] Use a disposable environment
- [ ] Keep the workload the same between LXC and VM
- [ ] Start with Podman `4.3.1`
- [ ] Run the same repro steps in both environments
- [ ] Record exact error messages before resetting Podman state
- [ ] Do not run `podman system reset` until after evidence is collected

---

## Test Matrix

| Environment | Podman Version | Test |
|---|---:|---|
| LXC | 4.3.1 | Reboot/runtime-loss repro |
| LXC | 4.3.1 | Helper-kill repro |
| LXC | 4.3.1 | CPU-stress repro |
| VM | 4.3.1 | Reboot/runtime-loss repro |
| VM | 4.3.1 | Helper-kill repro |
| VM | 4.3.1 | CPU-stress repro |
| VM | latest 5.x | Repeat all three tests |

---

## Baseline Setup

Run this in each test environment.

- [x] Verify Podman version
```bash
podman version
```

- [x] Start one simple long-lived container
```bash
podman rm -f repro 2>/dev/null || true
podman run -d --name repro docker.io/library/alpine sleep 100000
```

- [x] Confirm the container is healthy
```bash
podman ps
podman exec repro ip a
podman inspect repro
```

- [ ] Identify the networking backend if rootless
```bash
ps aux | grep -E 'slirp4netns|pasta|conmon'
```

Success criteria for baseline:

- [ ] `podman exec repro ip a` works
- [ ] `podman inspect repro` works
- [ ] container remains running

---

## Evidence Collection

If anything breaks, collect this before resetting anything.

- [ ] Run:
```bash
podman version
podman info
podman ps -a
podman inspect repro
journalctl -u podman --no-pager -n 200
journalctl --no-pager -n 200 | grep -E 'podman|conmon|slirp4netns|pasta|netns'
ps aux | grep -E 'podman|conmon|slirp4netns|pasta'
ls -la /run
ls -la /run/user
ls -la /run/user/$(id -u)
```

If rootful and relevant:

- [ ] Also check:
```bash
ls -la /run/user/0
ls -la /run/user/0/netns
```

---

## Repro 1: Reboot / Runtime-Loss

This tests whether ephemeral runtime state disappears while Podman’s saved state remains.

### Steps

- [ ] Start the baseline container
- [ ] Confirm networking works
```bash
podman exec repro ip a
```

- [ ] Reboot the host or restart the environment in a way that clears `/run` but preserves Podman storage

- [ ] After reboot, test:
```bash
podman ps -a
podman exec repro ip a
podman start repro
podman inspect repro
```

### Expected failure signals

- [ ] `no such file or directory`
- [ ] namespace or `netns`-related errors
- [ ] `podman exec` fails on an existing container
- [ ] `podman inspect` or `podman start` behaves inconsistently

### Interpretation

- [ ] Fails in LXC only: LXC is likely involved
- [ ] Fails in both LXC and VM: Podman version or runtime handling is likely involved
- [ ] Fails in 4.3.1 but not latest 5.x: upgrade is a strong candidate fix

---

## Repro 2: Kill the Networking Helper

This tests whether rootless networking helper death causes the same failure class.

### Steps

- [ ] Start the baseline container
- [ ] Identify helper processes
```bash
ps aux | grep -E 'slirp4netns|pasta'
```

- [ ] Kill the helper process
```bash
kill -9 <pid>
```

- [ ] Immediately retest:
```bash
podman exec repro ip a
podman stop repro
podman start repro
podman inspect repro
```

### Expected failure signals

- [ ] networking disappears
- [ ] `podman exec` fails
- [ ] restart does not recover cleanly
- [ ] Podman references missing runtime/helper state

### Interpretation

- [ ] If this reproduces the same failure, helper death is a credible trigger
- [ ] If only LXC reproduces it, LXC may be making helper/runtime behavior worse

---

## Repro 3: CPU-Stress Trigger

This tests whether host overload causes helper death or runtime corruption.

### Steps

- [ ] Start the baseline container
- [ ] Add CPU stress on the host
- [ ] While load is high, loop these commands:
```bash
podman ps
podman exec repro ip a
ps aux | grep -E 'slirp4netns|pasta|conmon'
```

### Expected failure signals

- [ ] helper process disappears during stress
- [ ] container stays present but networking fails
- [ ] Podman commands start failing while CPU is saturated

### Interpretation

- [ ] If only high load triggers it, CPU pressure may be the trigger rather than LXC alone
- [ ] If high load triggers it in LXC but not VM, LXC may be amplifying the failure

---

## LXC vs VM Decision Checklist

### If the issue reproduces only in LXC

- [ ] Treat LXC as a likely contributing factor
- [ ] Prioritize testing migration to VM
- [ ] Still upgrade Podman, because `4.3.1` is old

### If the issue reproduces in both LXC and VM on `4.3.1`

- [ ] Do not assume VM migration alone will fix it
- [ ] Prioritize Podman upgrade
- [ ] Keep testing helper death and CPU stress as triggers

### If the issue reproduces in `4.3.1` but not latest 5.x

- [ ] Treat upgrade as the highest-value mitigation
- [ ] Migration to VM may still help, but the version is likely a major factor

### If the issue only reproduces under heavy CPU

- [ ] Treat host stress as a likely trigger
- [ ] Review CPU limits, memory pressure, OOM, and helper-process survival
- [ ] Do not blame only stale netns paths

---

## What Would Count as “Good Evidence”

- [ ] Exact Podman error text
- [ ] Whether `slirp4netns` or `pasta` was running before failure
- [ ] Whether helper process disappeared after failure
- [ ] Whether the container still exists in `podman ps -a`
- [ ] Whether `podman inspect` works while `podman exec` fails
- [ ] Whether reboot, helper death, and CPU stress produce the same signature

---

## Likely Prevention Actions If Repro Succeeds

- [ ] Upgrade from Podman `4.3.1` to current 5.x
- [ ] Move from LXC to VM if LXC reproduces disproportionately
- [ ] Add monitoring for `slirp4netns`, `pasta`, `conmon`, and Podman service health
- [ ] Capture logs before any `podman system reset`
- [ ] Review resource pressure on the host

---

## References

- [ ] Podman system migrate docs  
https://docs.podman.io/en/latest/markdown/podman-system-migrate.1.html

- [ ] Podman runtime/rootless docs  
https://docs.podman.io/en/v4.9.0/markdown/podman.1.html

- [ ] Podman networking docs  
https://docs.podman.io/en/latest/markdown/podman-network.1.html

- [ ] Podman releases  
https://github.com/containers/podman/releases

- [ ] Example Podman networking/runtime issues  
https://github.com/containers/podman/issues/8047  
https://github.com/containers/podman/issues/19456
