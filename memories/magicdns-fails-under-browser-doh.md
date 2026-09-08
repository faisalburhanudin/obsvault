---
name: magicdns-fails-under-browser-doh
description: A *.ts.net name that curl resolves fine but the browser reports DNS_PROBE_POSSIBLE — the browser's secure DNS (DoH) bypasses MagicDNS.
metadata:
  type: reference
---

If a tailnet name works from `curl` but the browser shows "This site can't be
reached / DNS_PROBE_POSSIBLE", it is the browser, not the tailnet. Brave and
Chrome ship "Use secure DNS" (DNS-over-HTTPS) on, which sends the query
straight to Cloudflare or Google and never reaches Tailscale's MagicDNS
resolver. `curl` uses the OS resolver, so it succeeds.

Fix: `brave://settings/security` -> **Use secure DNS** -> off, or "With your
current service provider".

**Why:** the split between the two resolvers makes this look like a broken
deploy. Checking with `curl` first tells you which side is at fault.

**How to apply:** to confirm without touching settings, open the node's
`100.x` IP and port directly — that skips DNS. The TLS cert only matches the
`ts.net` name, so go back to the hostname once DNS works. Relevant to
[[dokku-tailnet-app-serves-itself]].
