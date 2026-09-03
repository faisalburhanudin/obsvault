---
name: chrome-live-tinyproxy-filter-race
description: chrome-live's tinyproxy races the cont-init script that generates its filter, so ~6% of containers run with ad blocking silently off.
metadata:
  type: project
---

Root cause of "ads sometimes appear" in chrome-live.

`root/etc/s6-overlay/s6-rc.d/tinyproxy/` has **no `dependencies.d`**, so s6-rc
starts tinyproxy concurrently with `legacy-cont-init`, the oneshot that runs
`/etc/cont-init.d/00-entrypoint.sh` — the script that generates
`/home/user/tinyproxy-filter.txt` (~20 MB, 917k patterns). Bundle membership in
`user/contents.d` creates NO ordering; only `dependencies.d` does.

Two outcomes, and the asymmetry is what makes it silent:
- Filter file **absent** -> tinyproxy exits fatally, s6 restarts it. Self-heals.
  Fleet evidence: 7,929 `filter file: No such file or directory` across 1,286
  containers (~6 restarts each; matches 3-7 `Initializing tinyproxy` per boot).
- Filter file **exists but empty/partial** (entrypoint uses a plain `>` redirect,
  which truncates instantly then writes for seconds) -> tinyproxy starts
  SUCCESSFULLY with zero patterns and never retries. No blocking for the life of
  that container, no error.

Failure rate: of 84 containers that loaded amazon.com, refusals were bimodal —
74 in 150-399, 3 in 400+, 1 in 50-149, 1 in 10-49, and **5 at exactly 0**. No
gradual tail, so zero is a distinct mode, ~6%.

Fixes, best first:
1. Generate the filter at BUILD time in the Dockerfile. It derives only from
   `/app/hosts`, which is already baked, so the race disappears and boot gets
   faster. (The `/etc/hosts` append must stay at runtime — Fly rewrites it.)
2. Add empty file `tinyproxy/dependencies.d/legacy-cont-init`.
3. Make the write atomic: `awk ... > FILE.tmp && mv FILE.tmp FILE`.
4. Assert a minimum pattern count at startup and fail loudly.

See [[chrome-live-hosts-layer-is-inert]] — the `/etc/hosts` layer that would
otherwise have been a backstop does not run either, so this race has no safety net.
