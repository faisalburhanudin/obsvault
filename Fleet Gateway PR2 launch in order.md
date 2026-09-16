# Fleet Gateway PR 2 — launch in order instead of racing

Status: written, not committed. Split out of the CDP probe PR so each change can be
reviewed on its own. PR 1 (the CDP probe) goes first; this builds on it.

## What it changes

`race_launch` is replaced by `launch_in_order`: try each upstream in `UPSTREAM_URLS` order
and keep the first one that gives a usable browser. One launch in flight at a time.

```python
async def launch_in_order(
    upstreams, *, body, headers, ws_headers, timeout, probe=None
) -> LaunchResult | None:
    for upstream in upstreams:
        logger.info(f"[launch] Trying {upstream.base_url}")
        result = await _launch_and_probe(
            upstream, body=body, headers=headers, ws_headers=ws_headers,
            timeout=timeout, probe=probe,
        )
        if result is not None:
            logger.bind(event="launch_winner", winner_upstream=upstream.base_url).info(
                f"[launch] Launched on {upstream.base_url}"
            )
            return result
    logger.error("[launch] Every upstream failed to launch a usable browser")
    return None
```

Deleted with it: `_cleanup_other_launches`, the losing-launch bookkeeping, and the
`asyncio.wait` machinery. `UPSTREAM_URLS` order becomes preference order.

## Why

The race creates a browser on **every** upstream and deletes all but one. Measured on the
GCE box with 4 upstreams, that is 4 browsers per request, 3 thrown away. Two of them cost
real money: browserbase-fleet bills the session from creation (`keepAlive: True`,
`timeout: 600`), and both podman-fleet and browserbase-fleet burn a residential proxy exit
IP pinned for 24h per session id. Losing launches also eat podman-fleet's `MAX_BROWSERS`
and browserbase-fleet's account session limit, so gateway traffic can make either return
429 to its own direct clients.

PR 1 makes this slightly worse, because every racer now gets CDP-probed too. Verified on
local fakes: 3 gateway launches produced 3 POSTs, 3 CDP probes and 3 DELETEs on the losing
upstream.

## Benchmark data behind it

Measured from inside the fleet-gateway container, 5 rounds, `x-origin-ip: 8.8.8.8`
(production path). TOTAL = launch + first CDP attach, which is the only finish line where
the fleets are comparable — see `scripts/bench_ready.py`.

| Upstream          | launch | attach | TOTAL p50 | range        |
| ----------------- | ------ | ------ | --------- | ------------ |
| browserbase-fleet | 4.16   | 0.46   | **4.78**  | 4.43 – 5.10  |
| daytona-fleet     | 6.59   | 0.54   | **7.09**  | 4.96 – 8.69  |
| flyfleet          | 2.28   | 6.47   | **8.58**  | 8.07 – 48.06 |
| podman-fleet      | 9.19   | 0.09   | **9.29**  | 8.58 – 9.75  |

Launch-only ranking put flyfleet first; by TOTAL it is third. Its attach is a flat ~6.5s
tax every round (the proxy reconfiguration its pre-warmed pool defers), and its launch
ranged 1.60s to 41.52s. It also produced the run's only hard failure
(`CDP never answered`, no-proxy round 4).

## Recommended config change with it

Prod order is currently browserbase, flyfleet, daytona, podman. browserbase first is right
(tightest distribution, fastest TOTAL). flyfleet should go last — worst tail, only failure.

    dokku config:set fleet-gateway UPSTREAM_URLS=...browserbase,...daytona,...podman,...flyfleet

## Tradeoff to accept

No backup/hedge. A slow-but-alive first upstream blocks that one request until the 60s
per-attempt timeout — flyfleet's 41.52s launch would have been a 41.52s wait. It does not
stall the gateway; other requests keep being served. I originally wrote a backup path that
started the next upstream after N seconds, and removed it on purpose to keep this simple.
If the tail ever hurts, that is the thing to add back.

## Where the code is

Full working patch and files saved at:
`/private/tmp/claude-501/-Users-faisal-workspace-src-github-com-remotebrowser-fleet-gateway/3c38139c-6083-4c38-ac5d-18b35a68d7ae/scratchpad/pr2/`
(session scratchpad — copy it somewhere durable if this sits for a while.)

Tests come with it: `tests/test_upstreams_launch_order.py` replaces
`tests/test_upstreams_race.py`. The key one is
`test_preferred_upstream_wins_without_touching_the_rest`, which asserts the second upstream
receives zero calls.
