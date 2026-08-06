While implementing recording upload to Tigris I hit something I'd rather sort out before this goes further.

The feature needs a runtime toggle per browser upload on/off, plus the browser id for the object key plus 5 static config for Trigris.  My current approach writes it back into `/app/browser-trace.conf` and lets the existing 1s file watcher re-apply it.

Proposal: split config by lifecycle. 
- Per-session values (traceparent, upload toggle, browser id) go to a `POST /update-trace-parent` & `POST /store-recording?browser_id=123` on browser-trace, held in memory only. 
- Static config (Tigris creds, tokens, ports) is read from env at startup. No write-back, no watcher, no sed. 
