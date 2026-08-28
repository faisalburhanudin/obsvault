## Goals
- [[Hutang KPR]] — started · prioritas #1, saving goal nunggu ini
- [[Dana Darurat]] — not started · after debt
- [[Planning THR]] — not started
- [[Qurban]] — not started · 4/7 share, 16jt
- Balikin uang asuransi
- Balikin uang pajak
## Backlog
- [ ] [[Ganti no HP]]
- [ ] Dashcam
- [ ] LED strip housing
- [ ] setup n8n vm
	- [ ] setup email cleaner
- [ ] using gmail skill to clean email
- [ ] Snaplet alternative
- [ ] [[Ideas]]
## 2026-08-28
- [ ] cpu-limit
	- [ ] [[test-prompt]]
- [ ] Figure out who invoked /api/v1/browsers/{browser_id} too frequently
- [ ] Investigate how surf communicate with the client
## 2026-08-27
- [x] Check caller last_activity_timestamp (time boxed)
	- [x] [[last_activity_result]]
- [x] Check resource needed for the ffmpeg joins
- [x] Ansible podman-fleet
	- [ ] private repo
	- [ ] tailscale oauth for podman-fleet
- [ ] How does the surf communicate, is it a sidecar like ours.
- [ ] Update PR nix
## 2026-08-26
- [x] feat: disable last_activity_timestamp for daytona https://github.com/remotebrowser/remotebrowser/pull/1467
- [x] fix: race between browser deletion and browser resurection https://github.com/remotebrowser/remotebrowser/pull/1468
- [x] feat: make CDP websocket ping internal a backend decision https://github.com/remotebrowser/remotebrowser/pull/1469
- [x] Bring remote browser fix to daytona fixes
	- [x] 1467: There is no last_activity_timestamp
	- [x] 1468: There's no way to attach to an existing browser id
	- [x] 1469: https://github.com/remotebrowser/daytona-fleet/pull/7
- [x] daytona-fleet: nix https://github.com/remotebrowser/daytona-fleet/pull/6
- [ ] Ansible secret
- [ ] Ansible Podman Fleet
## 2026-08-25
Worksheet
- [ ] Phony alphabet
- [ ] Number cheatsheet
- [ ] Mana yang berbeda
- [ ] Puzzle
	- [ ] Kategorikan
- [ ] Tracing Basic Shapes
---
- [ ] Daytona
	- [ ] Not remotebrowser process.exec
	- [ ] [[dwfwe]]
- [ ] Upgrade SDK to use TTL
	- [ ] Yes—current Daytona SDK supports an absolute sandbox lifetime via set_ttl(minutes):
	
	  await sandbox.set_ttl(60)

## 2026-08-21
- [ ] Hitung hutang
---
- [x] Cost analysis daytona
- [ ] Find root cause daytona
- [x] Fix Daytona self-hosted
- [ ] Update
	- [ ] https://github.com/remotebrowser/chrome-live/pull/43
## 2026-08-20
- [x] Disable formater
	- [x] revise neovim workflow in AI workflow
- [x] Check monthly 
- [ ] Breakdown lunasin hutang
---
- [x] Remote browser pre-signed generator
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1462
- [x] Handle something_error to auto-reload 
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1461
- [ ] Internal tools to create and manage browser
- [x] Check 
	- [x] patch_cdp_message prefixes every result.targetId on the way out but only un-prefixes Target.getTargetInfo on the way in, so any client that round-trips a target ID into Target.attachToTarget, Target.closeTarget, Target.activateTarget, or Page.navigate-by-target hits exactly the error you just saw. src/ip.py:90-111 does that same createTarget → attach → close sequence and only works because it connects straight to the machine rather than through the proxy. Stripping the prefix for the whole Target.* family on the client→remote path would make the proxy transparent
- [ ] Check recording for
	- [ ] browserbase
	- [ ] daytona

- [ ] Can we make daytona faster than browserbase?
## 2026-08-19
### Personal
- [x] Disable Herdr vim
	- [x] it's not herdr it zsh

### Work
- [x] fix mock database
	- [x] DB secret
		- [x] browserbase
		- [x] daytona
		- [x] flyfleet
	- [x] Clean data
- [x] Using one secret for database CI
- [x] Proxy flyfleet
- [ ] Tigris remotebrowser
- [x] Streaming log from chrome-live
	- [x] research
- [ ] Finding
	- [ ] Worth noting for your flyfleet branch, separately from this test:  — happy to write that patch if you want it, though it's your repo's call.
## 2026-08-18

Discussion
- Check browserbase
	- sekarang pakai logfire
	- Streaming log
		- log apakah ini?
		- compare sama browserbase
		- check log daytona
			- Log
			- Trace
			- Log untuk
	- Dia bisa screenrecording
	- Make it scalable
- Block analytics, harusnya di tiny proxy tapi sekarang lolos
- Best of N cloud providers
### Persona
- [x] Ruby rainbow worksheet
### Works
- [x] [[pre-signed chrome-live]]
- [x] [[Chromelive recording -> semua ads muncul]]
- [ ] flyfleet pass signed-url
- [ ] Research log stream browserbase & browser steel
## 2026-08-16
- [x] Recording
	- [x] Chrome-live
		- [x] fix: 5s
	- [ ] flyfleet
	- [ ] remotebrowser
		- [ ] daytona
- [x] Simplify CI
	- [x] Consolidate CI
	- [x] Using doppler for browserbase and daytona
- [x] Fix daytona backend
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1456
## 2026-08-16
### Personal
- [x] Worksheet for Elsha

### Work
- [x] Clean up test manager
	- [x] https://github.com/corelens-engineering/fly-cron-manager/pull/26
	- [x] https://github.com/corelens-engineering/fly-cron-manager/pull/23
	- [x] https://github.com/corelens-engineering/fly-cron-manager/pull/22
- [x] PR improvement from remotebrowser to backstage
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1440
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1441
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1437
		- [x] Not need
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1438
		- [x] Not needed
- [x] Update performance metric flyfleet vs browserbase vs daytona
	- [x] https://heyario.slack.com/archives/C049DGC1D2M/p1786893530219869?thread_ts=1785910195.601229&cid=C049DGC1D2M
- [x] Decomission grabbit GCE
- [x] Check [https://github.com/remotebrowser/remotebrowser/pull/1445/changes](https://github.com/remotebrowser/remotebrowser/pull/1445/changes) proper fix
	- [x] https://github.com/remotebrowser/remotebrowser/pull/1454
- [ ]  Continue on recording
    

## 2026-08-14
- [x] [[Clean-up test-manager]]
- [ ] fly-cron-manager
	- [ ] https://github.com/corelens-engineering/fly-cron-manager/pull/23
	- [ ] https://github.com/corelens-engineering/fly-cron-manager/pull/22
	- [ ] https://github.com/corelens-engineering/fly-cron-manager/pull/26
## 2026-08-13
- [x] Daytona test
- [x] Browserbase test
- [ ] Check CI
- [ ] Create PR to backstage
- [x] https://github.com/remotebrowser/remotebrowser/pull/1440 
	- [x] handle pattern upload
## 2026-08-11
- [ ] test-manager daytona
- [ ] test-manager browserbase
- [ ] check chrome-live PR
- [ ] create dpage for Charu
- [ ] support disable proxy for client
- [ ] Load average 
## 2026-08-10

### Personal
- [x] Beli selang hydroponic

### Works
- [x] [[Debugging mock-sidecar]]
## 2026-08-07

### Personal
- [ ] Masukin sedotan
- [ ] Try worktree
- [ ] bikin instalasi listrik diluar untuk hydroponic and lampu 17an

### Works
- [ ] Change recording PR
	- [ ] chrome-live: store recording here
	- [ ] flyfleet: create proxy
	- [ ] remotebrowser: hit api
- [ ] Remove unused secret in sentry
- [ ] [[refactor browser-trace]]
	- [ ] [[why?]]
	- [ ] 
- [ ] create dpage for Charu — 22:00
- [x] fix browserbase issue test manager:
	- [x] staggering
- [x] create DB


## 2026-08-06

### Works
- [x] mock tap-connect
	- [x] tap-connect-flyfleet
		- [x] test manager
	- [x] tap-connect-browserbase
	- [x] tap-connect-daytona
	- [x] Cron every 15 minute


## 2026-08-05

### Works
- [x] Share to team, regarding the cost
- [x] Share to team regarding reliability


## 2026-08-04

### Works
- [x] dpage for Charu Walgreens
- [x] .dockerignore file for flyfleet
- [x] [[start & pause browser browserbase]]
	- [x] Turns out suspend/resume on Browserbase isn't straightforward. Our browser_id is currently just the Browserbase session ID, and that ID isn't durable — releasing a session is terminal, and there's no API to revive it. We can restore the state via Browserbase Contexts (cookies, localStorage, auth), but that always comes back as a new session with a new ID, so the original browser_id can't be resumed as-is.
	- [x] Workaround would be to stop using the Browserbase session ID as our browser_id and mint our own stable ID, mapping it to the current session via Browserbase's session metadata. Doable, but worth flagging that it's a rebuild rather than a true suspend — open tabs, current URL, and in-page state are lost; only credentials survive. flyfleet already has real suspend/resume, so that backend is the cheap one to wire up first.


## 2026-08-03

### Works
- [x] Scale down mcp-getgather-dev-ssd
- [x] Recording: download video when the CDP closed
	- [x] PR: chrome-live https://github.com/remotebrowser/chrome-live/pull/32
	- [x] PR: flyfleet https://github.com/corelens-engineering/flyfleet/pull/166
	- [x] PR: remotebrowser
	- [x] ENV: if tigris exist store there
		- [x] always store to tigris
		- [x] identifier browser-id & session id
		- [x] folder like
- [x] follow yuxi regarding purchase in Walgreens


## 2026-07-31

### Works
- [x] fix: traceparent on chrome-live
	- [x] update PR desc
	- [x] deploy to fly dev
	- [x] run local remotebrowser that pointed to flyfleet.flycast
	- [x] run manual.py
- [x] clean-up PR in flyfleet pull request
- [x] Task from faisal
- [x] Check is catpcha log receive any value
	- result![[Pasted image 20260731142402.png]]


## 2026-07-30

### Works
- [x] Build cloak-browser
	- [x] Setup VM for build
		- [x] Pop OS (not working, UI glitch)
		- [x] Debian
	- [x] Build cloak-browser
		- [x] Test it
	- [x] Upgrade the chromium version to latest
		- [x] It's not possible chromium binary is proprieatry

## 2026-07-29

### Personal
- [x] WA mbk nur masalah lahiran
### Works
- [x] Clean up duplicate order
- [x] Hide from selector first https://github.com/corelens-engineering/demos/pull/1176
- [x] Add environment browserbase to test-manager https://github.com/corelens-engineering/fly-cron-manager/pull/20
	- [x] deploy (waiting PR to be merged)
	  ![[Pasted image 20260729191243.png]]
- [x] Check logo broken https://github.com/corelens-engineering/demos/pull/1199
- [x] fix unittest failed https://github.com/corelens-engineering/demos/pull/1198
- [x] fix fly multiple image in return reminder

## 2026-07-28

## 2026-07-27

### Personal
- [x] Buat kacamata deadline Friday
	- [x] pick up nanti sore
- [x] Unsubscribe brave vpn, deadline 31 Jul https://account.brave.com/account/
- [x] Relogin claude cli

### Works
- [x] setup Walgreens on tap-connect
- [x] setup remotebrowser
- [x] setup @ario/connector
- [x] setup tap-connect
- [x] Clean up remotebrowser
	- [x] https://github.com/corelens-engineering/demos/issues/1153
		- [x] Blocked: waiting team confirmation 
	- [x] https://github.com/corelens-engineering/demos/issues/1152 
- [x] [[Deploy remotebrowser-browserbase]]

## 2026-07-24

### Works
- [ ] setup Walgreens on tap-connect 
	- [x] try manual login
	- [x] artifact http://claude.ai/code/artifact/e2d80a68-1652-4df4-b2ac-1b4c46cc5f1d?via=auto_preview
	- [ ] setup remotebrowser
	- [ ] setup @ario/connector
	- [ ] setup tap-connect
- [ ] [[Clean up remotebrowser]]
	- [ ] MCP
- [ ] Clean up duplicate order

### Personal
- [x] Clean up Mac
## 2026-07-23
- [x] Add to google SSO
- [x] disable worker inboxcart
- [x] Fix deployment cron manager
	- [x] change env
- [x] Debugging grabbit down
## 2026-07-22
- [x] Budgeting
- [x] Fix ABC
## 2026-07-21
- [x] Move PR to chrome-live
	- [x] https://github.com/remotebrowser/chrome-live/pull/29
	- [x] https://github.com/remotebrowser/chrome-live/pull/28
- [x] Deploy OAuth and test https://heyario.slack.com/archives/C049DGC1D2M/p1784601808238869
- [x] rename: https://test-manager.pitta-pound.ts.net/schedules/tap-connect-wallmart%20(dev)
## 2026-07-20
- [x] Add path `/connect/gmail-callback`
- [x] debugging sms relay
	- [x] fix TS_AUTHKEY
	- [x] migrate to OAuth https://github.com/corelens-engineering/sms-relay/pull/2
		- [ ] deploy
- [x] HTTP service for browser-trace https://github.com/remotebrowser/browser-trace/pull/4
---
- [x] herdr command pallete to 
	- [x] create new 
	- [ ] switch session

---
Older entries → [[Journal Archive]]
