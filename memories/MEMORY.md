# Memory Index

Shared across all projects. Grouped by the repo the memory came from.

## Cross-project (how to work)

- [Short sentences](short-sentences-for-non-native.md) — write replies in short, simple sentences for a non-native reader
- [No over-commenting](no-over-commenting.md) — comment only what the code cannot say
- [No co-author](feedback_no_coauthor.md) — do not add Co-Authored-By lines in commits
- [Deploy-first working style](working_style_deploy_first.md) — ships rough POCs day one, iterates daily, over upfront polish
- [Confirm before dangerous actions](confirm-before-dangerous-actions.md) — ask before creating GCE instances or any cost-incurring/destructive action
- [Confirm before DB commands](feedback_confirm_before_db_commands.md) — prod DB needs confirmation first; local DB fine to run freely
- [Never read .env directly](never-read-dotenv-use-censored-script.md) — inspect secrets only via a value-censoring script

## remotebrowser/remotebrowser

- [Dokku staging access](dokku-staging-access.md) — SSH to dokku@100.97.220.119:2222 with key ~/.ssh/dokku_lambda to run dokku commands for the `remotebrowser` app
- [Steel research: competitor-only](competitor-research-steel-only.md) — keep Steel.dev research standalone; no "vs us" comparisons or project references
- [SaaS direction](saas-direction.md) — selling the stack as raw browser-infra SaaS (self-serve/PLG); roadmap in research/saas-roadmap.md
- [Tests must not read .env](tests-must-not-read-dotenv.md) — no load_dotenv in the pytest suite; only the server reads .env, export creds by hand locally
- [Daytona cost baseline](daytona-lifetime-baseline.md) — measure via billing dashboard (the audit log undercounts); 2026-08-25: $5.64/day, 85% from 21 long-lived sandboxes
- [Logfire project for browser work](logfire-project-remote-browser-dev.md) — use remote-browser-dev, filter by service_name; pro is empty
- [Daytona UUID -> browser_id](daytona-uuid-to-browser-id-mapping.md) — no direct lookup exists; match audit create time to relay-open time
- [Daytona single shared API key](daytona-single-shared-api-key.md) — one personal key for all services + laptops; billing cannot be attributed without audit-log IPs
- [Daytona Watch API deleted_at artifact](daytona-watch-api-deleted-at-artifact.md) — deleted_at is poll-detection time, not real deletion; measure with last_activity_at
- [Live view keeps sandboxes alive](live-view-dashboard-keeps-sandboxes-alive.md) — open dashboard blocks auto-stop; the idle-gate's own exec counts as activity
- [Logfire read token not in Doppler](logfire-read-token-not-in-doppler.md) — Doppler only has write tokens; create a read token in the Logfire UI for query-API scripts
- [DELETE 404s on live sandboxes](daytona-delete-404-on-live-sandbox.md) — tap-connect sweeps a shared reservation table with no fleet predicate; either deployment reaps the other's browsers
- [Daytona auto-stop never fires](daytona-auto-stop-never-fires.md) — 15-min idle stop does not fire on abandoned sandboxes; the probe that would explain it is dark since 2026-08-25
- [Local CDP leak test setup](local-cdp-leak-test-setup.md) — instrument the client side in browser.py, not the relay; .env CHROMEFLEET_URL cannot be unset via env var

## remotebrowser/chrome-live and mcp-getgather/chrome-live

- [Build & publish keep-chrome-live-dev](build-keep-chrome-live-dev.md) — Fly remote builder only; local amd64 podman dies under QEMU; how to reach flyfleet-dev's flycast IP
- [CI deploys by registry push](chrome-live-ci-deploys-by-registry-push.md) — no `fly deploy` in CI, so the fleet runs many digests at once
- [The /etc/hosts ad-block layer is inert](chrome-live-hosts-layer-is-inert.md) — `--proxy-server` makes DNS proxy-side; only the tinyproxy fnmatch filter blocks
- [tinyproxy filter race](chrome-live-tinyproxy-filter-race.md) — ~6% of containers boot with ad blocking silently off
- [Encode CPU-limit mechanisms](encode-cpu-limit-mechanisms.md) — cpulimit is a duty cycle, not a ceiling; only `-preset` cuts total work
- [Encode bench gotchas](chrome-live-encode-bench-gotchas.md) — browser-trace contends with the bench; cgroup v1 only; tunnel drops eat results
- [CloakBrowser VNC/GPU](cloakbrowser-gpu-fix.md) — blank VNC is an emulation artifact (podman on Mac/QEMU), NOT a flag bug; committed --use-gl=swiftshader works on native amd64; verify on Fly

## remotebrowser/browser-trace

- [aiohttp sidecar test](aiohttp-sidecar-test.md) — resume: build/run scratchpad Dockerfile.test to test v0.3.3 aiohttp recording API
- [live-view + recording initiative](live-view-recording-initiative.md) — HTTP service so one CDP screencast feeds recording+live view; task sequence + Tier-C/CapSolver decision; see docs/live-view-recording-research.md
- [liveview POC](liveview-poc.md) — built & verified chromium Docker POC: liveview.py aiohttp on :9223 (live view WS + recordings), poc/Dockerfile; signal-forwarding & podman-mac gotchas

## corelens-engineering/demos and gather-engineering/demos

- [grabbit ↔ remotebrowser cross-org routing](grabbit-remotebrowsers-cross-org-routing.md) — grabbit (org yuxi-yao) can't reach remotebrowser's Flycast (org remote-browsers); must use Tailscale
- [tap-connect CPU steal root cause](tap-connect-cpu-steal-root-cause.md) — sidecar freezes were Fly shared-CPU throttling, driven by uncached bs4 pattern loading; fixed with lru_cache
- [Logfire project split](logfire-project-split-remotebrowser.md) — flyfleet-dev logs to `remote-browser-dev`, the tcmf sidecar and prod flyfleet to `getgather`; filter by environment
- [tap-connect getgather memory growth](tap-connect-getgather-memory-leak.md) — allocator retention from bs4 churn, not a Python or C leak; resolved by caching
- [tcmf shared-CPU burst exhaustion](tap-connect-shared-cpu-burst-exhaustion.md) — steal 37-51% post-fix; throttle lands AFTER the spike, so errors anti-correlate with load
- [tap-connect test failures: dead ends](tap-connect-test-failures-fleet.md) — fleet capacity, Tailscale routing, and the 27 orphan skips were all ruled out
- [Test Data TODOs](project_test_data_todos.md) — known gaps in inboxcart test dataset needing future revision (e.g. test_062 Clarks missing attachment)
- [Migration Conventions](project_migration_conventions.md) — shared dev DB auto-migrated on merge, idempotent-migration convention, CI snapshot test pitfalls, renumber-on-rebase
- [Inboxcart Manual Testing](project_inboxcart_manual_testing.md) — local DB seed from prod, forcing scheduler claims, Gmail after: PT-timezone gotcha, LLM failure modes
- [Inboxcart Run](project_inboxcart_run.md) — `uv run uvicorn app.main:app --port 5555` to run the app locally
- [Backfill Under-fetch](project_backfill_underfetch.md) — paused fix+validation; pagination/terminator fix uncommitted, resultSizeEstimate unreliable, resume with oracle-vs-stored

## corelens-engineering/deployment

- [Ansible task names are noun phrases](ansible-task-name-ensure.md) — name the end state ("Git installed"), not "Ensure …" or "Install …"; lint constrains casing and Jinja position
- [Podman backend is being removed](podman-backend-being-removed.md) — the role omits podman on purpose; do not propose provisioning it
- [Podmanfleet target decisions](podmanfleet-target-decisions.md) — VM `fleet`, Doppler fleet/prd_podmanfleet, tag:podman-fleet, clone authenticates via git env config

## gather-engineering/remote-browser-tests

- [Tigris report debugging](tigris-report-debugging.md) — pull historical test reports from Tigris (creds via fly-secret manager app; zip size = pass/fail)
- [SMS OTP outage Jul 2026](sms-otp-outage-jul2026.md) — two problems: Amazon OTP never retrievable (config bug) + real SMS-gateway outage from ~2026-07-18
