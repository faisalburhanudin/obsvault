
# Fact


# Hypotesis
- If tinyproxy down is the browser still accessible. Answer: **No**
	- Why? 
		- root/etc/s6-overlay/s6-rc.d/chromium/run hardcodes the proxy into COMMON, for all three browser variants (chrome / cloak / custom): --proxy-server=http://127.0.0.1:8119
- If ads list download failed will image got build. Answer: **No**
	- hblock's defaults are retry=0 and continue=false
- Is it because the block list reliable?. Answer: **Maybe**
	- All ~40 builtin sources point at master, not a pinned commit
		- it can be empty
	- Validating deployment chome-* /etc/hosts
		- Difference content in /etc/hosts
		- ![[Pasted image 20260818140445.png]]
	- **Conclussion**
		- there is drift but not enough signal
---
# find machine that can't block ads

# Investigate why ads SOMETIMES still appear in chrome-live containers

Repo: `remotebrowser/chrome-live` (branch `main`). Container = Chrome + Xvnc +
tinyproxy under s6-overlay, published to Fly as `keep-chrome-live*`, forked into
~110 ephemeral `chrome-*` apps.

## Architecture (My understanding now, you can explore if possible other missing piece)

Ad blocking is two layers, both generated from one build-time list:

1. **Build time** — `Dockerfile:167-172` runs `hblock` v3.5.1 (sha256-pinned)
   to produce `/app/hosts`, filtered by `allowlist.txt` (contains `cdn4dd.com`)
   and `denylist.txt` (`edgedl.me.gvt1.com`,
   `optimizationguide-pa.googleapis.com`, `safebrowsing.googleapis.com`).
   hblock's ~40 builtin sources are all
   `raw.githubusercontent.com/hectorm/hmirror/master/data/*/list.txt` —
   pinned to `master`, not a commit.
2. **Runtime** — `entrypoint.sh` (as `cont-init.d/00-entrypoint.sh`):
   - `cat /app/hosts >> /etc/hosts` (entrypoint.sh:11)
   - an awk pass rewrites `/app/hosts` into `/home/user/tinyproxy-filter.txt`,
     emitting both `domain` and `*.domain` per entry, skipping bare IPs and
     localhost.
   - `tinyproxy.conf:24-27` loads it: `Filter`, `FilterType fnmatch`,
     `FilterURLs No`, `FilterCaseSensitive No`.

All three browsers (`google-chrome-stable`, `cloak-browser`, `custom-chrome`)
share the `$COMMON` flag set in `root/etc/s6-overlay/s6-rc.d/chromium/run`,
which includes `--proxy-server=http://127.0.0.1:8119`. There is no
`--proxy-bypass-list`. No ad-blocking browser extension is installed.
tinyproxy allows `ConnectPort 443` and `ConnectPort 80` only.

## Method

Reproduce empirically rather than reasoning from source alone. `fly ssh console
-a <app>` works on a running machine; machines are `autostop=suspend` /
`autostart=true`, and SSH rides WireGuard so it won't hold one awake. Load a few
real ad-heavy pages through a container's CDP endpoint (`:9221` internally,
`:9222` published) and inspect what actually loads — tinyproxy logs go to
stdout via the s6 `tinyproxy-log` consumer, so you can see what it refused
versus allowed. **Prefer evidence from an actual page load over static
analysis.**