
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
		- 