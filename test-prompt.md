I want to test ways of **limiting the CPU that browser-trace's MP4 encode
consumes**, and compare each against a measured baseline. Testing only — do not
change `browser-trace/recording.py` or any product code unless I ask.

## The one thing I care about

A CPU timeseries chart of a single encode: machine-wide CPU and ffmpeg's own
share, sampled every 200 ms, across three phases — idle before, encode, idle
after. I want to see how each limiting mechanism changes **the height and the
width of that spike**.

## What already exists — reuse it, do not rebuild it

`bench/ffmpeg-encode/` is a working harness.

```bash
cd bench/ffmpeg-encode
TRACE=1 ./ffmpeg-encode.sh          # this is the mode that produces the chart data
```

It creates a browser on `flyfleet-dev`, opens a tab, injects a full-viewport CSS
animation over CDP so frames actually flow, captures for `ANIMATE_SECONDS`,
quiesces the page, runs one encode while sampling `/proc/stat` and the ffmpeg
process's `/proc/<pid>/stat`, then deletes the browser. It writes
`results-<timestamp>.json`; the per-sample series is `trace.samples[]` with
`{t, phase, cpu_pct, ffmpeg_pct}`.

Prerequisites: `flyctl` authenticated and Fly WireGuard up (`curl http://flyfleet-dev.flycast/health` should return OK). One run takes ~4 minutes.

## Baseline to compare against

Machine: **1 performance vCPU / 4 GB** (flyfleet's config — *not* the `cpus = 4`
in `chrome-live/fly.toml`; confirm with `fly machines list`).

From  — 1212 frames, 123.4 s of video, 5.12 MB out:

| metric | value |
| --- | --- |
| CPU before | 2.1% mean |
| CPU during | 87.7% mean, 100% peak |
| ffmpeg's own share | 86.0% mean |
| spike duration | 29.3 s |
| work | 25.3 core-seconds (~21 ms/frame) |

The encode is **~86% CPU-bound, ~14% I/O** (25.3 core-s over 29.3 s wall), so
roughly a seventh of the spike is disk, not compute.