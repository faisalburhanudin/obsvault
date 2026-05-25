- Flyfleet
	- [ ] Setup CI
	- [x] Deploy
- Remote Browser
	- [x] Secret
	- [x] Deploy
	- [ ] Setup CI
	- [ ] LogFire
	- [ ] Sentry
	- [ ] OAuth
	- [x] Tailscale
		- [x] https://github.com/remotebrowser/mcp-getgather/pull/1006
	- [ ] Close access to public internet
	- [ ] Pinning IP or magic DNS?
- Safeline WAF
	- [x] Configure
	- [x] DNS mapping
	- [ ] change domain to mcp.remotebrowser.ai

--- 

- Flyfleet
	- [ ] Setup CI
- Remote Browser
	- [ ] Setup CI
	- [ ] LogFire
	- [ ] Sentry
	- [x] OAuth
	- [ ] Close access to public internet
- Tailscale service discovery
	- [x] Use tailscale service to service discovery
	- [ ] Enable auto approve
- Safeline WAF
	- [x] change domain to mcp.remotebrowser.ai
---
- Flyfleet
	- [ ] Setup CI
		- [ ] Need invitation Doppler
- Remote Browser
	- [x] PR serve
	- [ ] Setup CI
		- [ ] Need invitation Doppler
	- [x] LogFire
	- [x] Sentry
	- [ ] Close access to public internet
	- [ ] Test MCP
		- [x] list tool unautorized
		- [ ] autorized tool call
- Tailscale service discovery
	- [x] Enable auto approve
---
- [ ] chrome-live
	- [ ] build local and pushwait
	- [ ] CI for remote browser
---
Quick update on remotebrowser oss

MCP now live at **`REDACTED`**
- **Ingress:** Traffic hits **Safeline WAF** (GCE).
- **Internal Proxy:** Requests move through **Tailscale Service** (Port **4000**).
- **Backend:** Tailscale routes to **REDACTED** instances on Fly.

In this deployment I used tailscale service to solve fly deployment, at fly when deployment happen old machine is not turn off until new machine ready (blue/green), this caused multiple service a live at same time, caused fly to assign multiple IP, this make it hard to pinning IP for Safeline WAF, using tailscale service will solve service discovery via tailscale tags, and auto approve downstrem service.