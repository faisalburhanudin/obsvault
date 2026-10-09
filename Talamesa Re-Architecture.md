## Orchestrator
- [x] Make it good
- [x] Credentials cloudflare queue
- [x] Integrate bucket put and cloudflare queue
- [x] Listen on Cloudflare Queue for processing new data
- [x] Deploy to VM on new port
- [ ] if possible assign domain dagster.talamesa.com


## Spec

Deploy

# Deploy spec

How this Dagster project goes to production, from Dagster down to the
worker. It is based on the old terrarupa deployment
(`../../faisalburhanudin/terrarupa/deploy.sh` and `infra/systemd/`). Items
marked **new** are not in the old deployment.

## Machines

Both machines are reached over Tailscale only.

| Machine | SSH | Runs |
|---------|-----|------|
| VM | `ssh ubuntu@100.65.32.4` | Dagster webserver, Dagster daemon, queue API, `jobs.db` |
| Homelab | `ssh faisal@100.122.215.60` | The worker and the tools (GPU) |

```
                         Tailscale
VM 100.65.32.4                              Homelab 100.122.215.60
┌──────────────────────────────┐            ┌─────────────────────────┐
│ dagster-webserver :3000      │            │ worker                  │
│ dagster-daemon               │            │   claim / heartbeat /   │
│   storage_sensor ── R2 list  │            │   finish over HTTP ─────┼──┐
│   automation_sensor          │            │   runs tools/<tool>     │  │
│   runs: create job, poll ────┼─► jobs.db  │   moves files ── R2     │  │
│ queue API :8100 ◄────────────┼────────────┼─────────────────────────┼──┘
└──────────────────────────────┘            └─────────────────────────┘
```

- The server (web UI) stays on the VM. It reads `jobs.db` read-only for job
  status. It does not start runs any more: the sensors do.
- The worker needs no database and no open port. It only calls the queue
  API and R2.

## What runs where

### VM

| Unit | Command | Bind |
|------|---------|------|
| `orchestration-dagster-webserver` | `uv run dagster-webserver -f definitions.py -h 100.65.32.4 -p 3000` | Tailscale only, the UI has no login |
| `orchestration-dagster-daemon` | `uv run dagster-daemon run -f definitions.py` | none |
| `orchestration-queue-api` | `uv run uvicorn api:app --host 100.65.32.4 --port 8100` | Tailscale only |

- System units, `User=ubuntu`, `Restart=always`, `RestartSec=5`,
  `After=network-online.target tailscaled.service`.
- `WorkingDirectory=/home/ubuntu/orchestration`.
- Each unit sources the env file, then `exec`s the command. `.envrc` uses
  `export`, which `EnvironmentFile=` cannot read.
- `Environment=DAGSTER_HOME=/home/ubuntu/orchestration/dagster_home` in
  both Dagster units. The two must share it.
- The daemon is required. It runs the sensors, the automation, the run
  queue and the retries. Without it nothing starts by itself.

### Homelab

| Unit | Command |
|------|---------|
| `terrarupa-worker` (user unit, lingering on) | `uv run worker.py` in `~/terrarupa/worker` |

The worker stays in the terrarupa repo and is deployed by terrarupa's
`./deploy.sh worker`. This repo does not deploy it. Its setup:

- `uv sync` in `worker/`.
- pixi in `~/.local/bin`, then `pixi install --locked` in
  `tools/lidar_clean` (python-pdal is a conda package).
- roofer v1.0.0 release binary in `~/.local/share/roofer-v1.0.0`, with
  `chmod +x` (the tarball drops the execute bit). Needs glibc 2.38.
- CUDA for `tools/sam3`. On WSL, `nvidia-smi` is at
  `/usr/lib/wsl/lib/nvidia-smi`.
- `WORK_DIR` (default `~/terrarupa/data/`) is kept between runs. A retry
  then skips the download, and tools resume from their done-logs.

## Dagster instance

`dagster_home/` on the VM holds the run, event and schedule storage
(SQLite). It is never copied by deploy and never deleted.

**new:** a `dagster.yaml` in the repo, copied into `dagster_home/` by
deploy. The old deployment had none, so every default applied.

```yaml
run_coordinator:
  module: dagster.core.run_coordinator
  class: QueuedRunCoordinator
  config:
    max_concurrent_runs: 4

run_monitoring:
  enabled: true

telemetry:
  enabled: false
```

- `max_concurrent_runs`: eager can start a run for every project at once.
  There is one worker, so most runs only wait on the queue. Each waiting run
  is a Python process on the VM. A limit keeps the VM small.
- `run_monitoring`: a run killed by a restart is marked failed, not left
  "started" forever.

## Environment

One file, `~/orchestration/.envrc`, not committed. Deploy copies it from
the Mac on purpose. Never print it.

| Var | Used by | Old | Note |
|-----|---------|-----|------|
| `JOBS_DB` | daemon, webserver, queue API, server | yes | Outside `dagster_home/` |
| `QUEUE_TOKEN` | queue API, worker | yes | Same value on both machines |
| `POLL_SECONDS` | runs | yes | Default 30 in old code |
| `RETRY_DELAY` | runs | **new** | Default 120 |
| `STORAGE` | `storage_sensor` | **new** | `r2` in production, a folder locally |
| `R2_BUCKET`, `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` | `storage_sensor`, worker | worker only | **new** on the VM for Dagster. Dagster only lists; a read-only key is enough |
| `QUEUE_URL` | worker | yes | `http://100.65.32.4:8100` |
| `WORK_DIR`, `WORKER_NAME` | worker | yes | Optional |

## Deploy script

`./deploy.sh` in this repo, the same steps as terrarupa's
`deploy_workflow`:

1. **Check the queue is idle.** A restart kills every run, and every run
   waits on a job. Stop when a job is `pending`, or `running` with a
   heartbeat newer than 5 minutes. Print them. `FORCE=1` skips the check.
2. **Copy.** `rsync -az --delete` of git's files plus `.envrc` to
   `ubuntu@100.65.32.4:orchestration/`. Exclude `.git/`, `.venv/`,
   `__pycache__/`, `storage/`, `dagster_home/`, and untracked files.
   Excluded paths are also safe from `--delete`.
3. **Install.** `~/.local/bin/uv sync` on the VM. Copy `dagster.yaml` into
   `dagster_home/` (**new**).
4. **Units.** Copy `infra/systemd/orchestration-*.service` to
   `/etc/systemd/system/`, `daemon-reload`, `enable`, `restart`, then
   `systemctl is-active` for each one.

A worker deploy (terrarupa) needs the same idle check. A restarted worker
kills its job, and the run fails 5 minutes later, when the heartbeat is
stale.

## Moving from the old deployment

The old and new Dagster cannot both use the same queue: both would create
jobs, and the worker takes jobs from one queue API only.

1. Wait for the old queue to be idle.
2. Stop and disable `terrarupa-dagster-webserver`,
   `terrarupa-dagster-daemon` and `terrarupa-queue-api`.
3. Deploy this repo. The new queue API uses the same `JOBS_DB` file, so
   job history and the server's job status stay.
4. Add the existing projects: the first `storage_sensor` tick adds every
   project in R2 as a partition.
5. **Trap:** eager sees every project for the first time. Projects with an
   upload but no run history may all start at once. Decide before step 3
   whether that is wanted, or start with `automation_sensor` stopped and
   turn it on by hand.
6. Server: remove the GraphQL calls that start runs (`server/main.py`).

**Rollback:** stop the new units, enable and start the old three. Both use
the same `jobs.db`.

## Checks after a deploy

- `systemctl is-active` is `active` for the three units.
- `http://100.65.32.4:3000` shows the graph. **Automation** shows both
  sensors running, with recent ticks and no errors.
- The queue API answers: `POST http://100.65.32.4:8100/jobs/claim` with
  `{"worker": "check", "tools": []}` and the Bearer token returns 204. An
  empty tool list claims nothing.
- On the homelab, `journalctl --user -u terrarupa-worker -f` shows claims,
  not connection errors.
- One small project: write its marker, and a run starts within a minute.

## Logs

| What | Where |
|------|-------|
| Dagster runs | The UI, **Runs** |
| Webserver, daemon, queue API | `journalctl -u orchestration-<name> -f` on the VM |
| Worker | `journalctl --user -u terrarupa-worker -f` on the homelab |

## Open questions

1. Does the queue (`jobs.py`, `api.py`) move into this repo, or stay in
   terrarupa and get deployed from there?
2. The repo folder on the VM: `~/orchestration/`, next to the old
   `~/terrarupa/`?
3. `max_concurrent_runs`: 4 is a guess.
4. Step 5 of the move: start eager on, or off?
5. Should the server keep a way to start a run by hand, for example
   re-running one project?


# Real tools spec

Phase 15: replace the fake asset bodies with real jobs on the terrarupa
worker. Read `SPEC.md` first. The terrarupa code is in
`../../faisalburhanudin/terrarupa/`. Paths below are relative to it.

## What exists in terrarupa

- **Queue.** One SQLite table `jobs` in `$JOBS_DB`
  (`orchestrator/jobs.py`). Status: `pending → running → done | failed`, or
  `lost`. Dagster opens the file directly. The worker is on another machine,
  so it uses a small HTTP API (`orchestrator/api.py`, port 8100, Bearer
  `QUEUE_TOKEN`): claim, heartbeat, finish.
- **Worker** (`worker/worker.py`). Claims one job at a time. Downloads the
  inputs from R2, runs the tool, uploads the outputs, then finishes the job
  with `result = {outputs: {key: size_mb}, summary, timing}`, or with
  `error` and a `code` on failure.
- **Progress.** A free-text `progress` column, sent with each heartbeat:
  `downloading x: 12 / 80 MB (15%)`, `running sam3`, `uploading …`. No
  per-tile progress.
- **R2.** Everything for a project is under `projects/<project>/`. The
  server creates `project.json` when a project is created. Uploads are
  multipart, so `cog/ortho.tif` is never visible half-written.

## Design

### Asset body

Each tool asset does what the old orchestrator did:

1. `jobs.create(tool, project)`.
2. Every `POLL_SECONDS` (default 10), read the job. Log `progress` when it
   changes.
3. `done`: return `MaterializeResult` with `r2_keys`, `size_mb` (sum of the
   outputs), `summary` and `timing` from the result.
4. `failed`: raise `dg.Failure` with `job_id`, `code`, `stderr`, `timing`.
5. Heartbeat older than 5 min: mark the job `lost`, raise `dg.Failure`.

Asset names are data, tools are commands. The only name that differs is
`building_masks → sam3`. A dict maps it.

### Retries

Each retry is a new job (Dagster `RetryPolicy`, 3 times, 120 s). Some
failures will fail again, so they do not retry: raise
`dg.Failure(allow_retries=False)` for `no_lidar` and
`lidar_passes_disagree`.

### The queue moves here

Copy `jobs.py` and `api.py` into this repo. The queue belongs to the
orchestrator. The worker and the server do not change: same table, same
API.

### Fake worker for local work

`scripts/fake_worker.py` claims jobs from the local queue and finishes them
with fake progress and fake outputs. This replaces the fake asset body, so
the Dagster code has only one path. Local `dagster dev` runs with the fake
worker; tests use it too.

### Storage sensor on R2

`storage_sensor` lists `projects/` in R2 (boto3, `Delimiter="/"`) instead of
`storage/`. `project.json` makes a partition. The cursor stores the ETag of
each marker, not the mtime. A `STORAGE` setting picks R2 or the local
folder, so the tests stay local.

## Conflicts with `SPEC.md`

These must be decided before coding.

1. **`lod0` and `lod1`.** In the worker, `lod0` reads `lidar/clean/` and
   holds the heights; `lod1` only reads `lod0`. `SPEC.md` says `lod0` is a
   footprint and `lod1` needs `lidar_clean`. Either the tools change (move
   the height step from `lod0` to `lod1`), or `SPEC.md` goes back to the
   old graph.
2. **Upload markers.** The server writes no `_done.json`. `cog/ortho.tif`
   is safe to use as its own marker, because of the multipart upload.
   `raw/lidar/` has many files, so only the server knows when the last one
   is done. Proposal: the server writes `raw/lidar/_done.json` after the
   last lidar file. A server change.
3. **Tile progress.** `SPEC.md` asks for tile counts. The worker does not
   read tool output while it runs. Either the tools print progress lines
   and the worker sends them, or drop `tiles_*` from the metadata.
4. **`export`, reviews, `ai_*`, `apply_*`.** The worker still has these
   tools. They stay in the worker for the server to use, Dagster ignores
   them.

## Not in this spec

- Changing the tools themselves (only item 1 and 3 above, if chosen).
- Stale tiles when inputs change (a tool problem, see `worker/README.md`).
- Several worker types or GPU routing.

## Steps

1. Copy the queue. Tests for create, claim, finish, lost.
2. The fake worker. The asset body submits and waits. `dagster dev` with
   the fake worker gives the same result as Phase 14.
3. Retries and no-retry codes. Test with the fake worker failing on
   purpose.
4. The storage sensor on R2, behind `STORAGE`.
5. Decide and do the conflicts above.
6. Deploy: Dagster, the queue API and the worker on the VM. Keep
   `deploy.sh`'s rule: no deploy while jobs are running.
