## Backlog
- [ ] English homework, voice note at whatsapp
- [ ] Lem sendal mama
- [ ] [[Ganti no HP]]
- [ ] [[Finance]]
- [ ] Planning liburan malang
- [ ] Planning Qurban 4/7
- [ ] Planning THR
- [ ] Lem Headset
- [ ] Check Asuransi Erlang
- [ ] Monitor harga bahan pokok
- [ ] Snaplet alternative
- [ ] [[Ideas]]
- [ ] GMail Cleaner
- [x] Check email ayem tentrem
- [ ] sentry cli
- [ ] logfire cli

## 2026-06-15
- repeated log 2026-06-16 11:10:39 INFO [app.services.pipeline] @@@ Classified 0 emails in 0.000 seconds


- Buat lebih cepet
- user revoke token setelah selesai
- pengennya user connect, within 2 minute
- 1 module parameterize
- get_purchase_by_detail
	- ketika singgin success, langsung scraping until 2020 langsung
	- worker cuma buat forward
- clints

- Take capacity
- background immediately
## 2026-06-13

Dug into the 14 users (created since Jun 12) with a missing refresh_token. 

It looks like the users are revoking Gmail access after connecting.

Instead the refresh token gone in multiple lifetimes ~2 min, ~1h, ~2h, ~3h, ~7h, ~26h, ~28h
after signup..

  Flow:
  • Token works -> user revokes from their Google security page -> next sync gets invalid_grant:
	  Token has been expired or revoked -> we null the token
  • 8 of 14 got exactly one successful sync before the next hourly run failed -> they pulled access within the first hour.
  • 2 never synced at all (revoked in ~2 min).
  • Outliers presleym311 (26 syncs / ~26h) and steveramosjr1985 (7 syncs / ~7h) left it connected longer, then revoked same cause, later.

## 2026-06-12
- [ ] Handle this? https://heyario.slack.com/archives/C03KV5ZK9CG/p1781213244955679?thread_ts=1781210736.470069&cid=C03KV5ZK9CG
- [ ] Clean https://heyario.sentry.io/issues/7519560064/?project=4511432600846336&query=is%3Aunresolved&referrer=issue-stream
- [x] scale performance-4x
- [x] https://github.com/remotebrowser/mcp/pull/1333
- [ ] Flag enable worker
- [ ] Clean refresh_token
- [ ] check distill on log
## 2026-06-11
- [ ] **merged** Pattern not found purchase amazon prime
- [ ] Pattern empty watch list
	- [ ] https://github.com/remotebrowser/mcp/pull/1331
	- [ ] https://github.com/remotebrowser/mcp/pull/1330
- [ ] 
- [ ] Import email sample

## 2026-06-10
- [x] Why mxxn and blinds test always running?
- [x] Remove juang email
- [x] Check is mistral model using trusted provider
- [x] Sentry
	- [ ] https://heyario.sentry.io/issues/7540879616/events/c9d1b8669b62488aaab799a9a9164b60/

- [x] https://github.com/gather-engineering/demos/pull/894
- [x] https://github.com/gather-engineering/demos/pull/896
### Personal
- [ ] English task
## 2026-06-09

- [x] LLM Optimization
	- [x] Batch call
	- [x] Prompt Caching
	- [x] Gemini Batch API
### Personal


## 2026-06-08

### Ario
- [x]  https://github.com/gather-engineering/demos/issues/860

- [x] Check backfill sync worked in production
	- [x] [question](https://metabase.getgather.dev/question#eyJkYXNoYm9hcmRfaWQiOjE1LCJkYXRhc2V0X3F1ZXJ5Ijp7ImRhdGFiYXNlIjozLCJsaWIvdHlwZSI6Im1icWwvcXVlcnkiLCJzdGFnZXMiOlt7ImxpYi90eXBlIjoibWJxbC5zdGFnZS9tYnFsIiwib3JkZXItYnkiOltbImRlc2MiLHsibGliL3V1aWQiOiI0NmMzMTAwNi0yZDZmLTRkN2ItYjg3OC05OTJjZGJiZTI3OWQifSxbImZpZWxkIix7ImJhc2UtdHlwZSI6InR5cGUvVGV4dCIsImVmZmVjdGl2ZS10eXBlIjoidHlwZS9UZXh0IiwibGliL3V1aWQiOiI2N2MzZTA1Ni1iMTdmLTRlNDEtOGNhOS01ZWI0OGU1Y2IyODgifSwiYmFja2ZpbGxfc3RhdGUiXV1dLCJzb3VyY2UtY2FyZCI6MTcwfV19LCJkaXNwbGF5IjoidGFibGUiLCJkaXNwbGF5SXNMb2NrZWQiOnRydWUsIm5hbWUiOiJJbmJveENhcnQ6IFBlci11c2VyIGJhY2tmaWxsIHByb2dyZXNzIiwib3JpZ2luYWxfY2FyZF9pZCI6MTcwLCJwYXJhbWV0ZXJzIjpbXSwidHlwZSI6InF1ZXN0aW9uIiwidmlzdWFsaXphdGlvbl9zZXR0aW5ncyI6eyJ0YWJsZS5jZWxsX2NvbHVtbiI6InNjcmFwZWQiLCJ0YWJsZS5waXZvdF9jb2x1bW4iOiJzeW5jX2N1cnNvciJ9fQ==)
	- [x] announcement
- [ ] Backfill permanently skips LLM-failed emails — introduced-ish (new exposure)
- [ ] Why mxxn and blinds test always running?
- [x] Check beta-testing issue.
	- [x] ## Receipts results: Location instead of restaurant name on some results
	- [x] ## Receipt search stopped/hung
	- [x] ## Receipt fetching took around 30/60 seconds
	- [x] ## Receipts page- shows only two receipts from a store and that too without location, history and other details
	- [x] ## Connecting to gmail account was not successful on 1st attempt
- [ ] Logfire
	- [ ] Only for extracted flowEmail apa, extracted value, attachment email
- [x] Remove fajar email
- [x] Metabase
	- [x] in funnel I added unique order
	- [x] Deduplicate total purchase order
- [x] Update Gmail UX
- [ ] Store raw email to sentry

### Personal
- [ ] Daftar https://www.instagram.com/p/DZUDJFsxNly/


## 2026-06-05

### Ario
- [ ] https://github.com/gather-engineering/demos/issues/860
	- [ ] dns
	- [x] tap -> change screen to instant
- [x] forward sync
	- [x] store source of email, is it from sync or initial
- [ ] Dedup https://heyario.slack.com/archives/C049DGC1D2M/p1780546640434359
- [ ] Capacity using database
- [ ] work on this issue https://github.com/gather-engineering/demos/issues/860
- [ ] Gmail after: timezone gap in forward sync — pre-existing, highest impact
- [ ] Backfill permanently skips LLM-failed emails — introduced-ish (new exposure)
- [ ] Security: refresh token should be encrypted
- [ ] Why mxxn and blinds test always running?
- [ ] 
## 2026-06-04
### Ario
- [ ] Security: refresh token should be encrypted
- [x] backward filling https://github.com/gather-engineering/demos/pull/853
- [x] Adjust capacity, worker shouldn't use capacity
- [ ] Why mxxn and blinds test always running?

## 2026-06-03
### Ario
- [x] Check sentry
- [x] inboxcart capacity https://github.com/gather-engineering/demos/pull/849
- [ ] backward filling https://github.com/gather-engineering/demos/pull/853
- [ ] metabase dashboard
	- [ ] [[inboxcart-metabase-query]]
	- [ ] only USD
	- [ ] remove test email

### Personal
- [ ] impecable skill is so wonderfull, looks behind the machine

## 2026-06-02

### Ario
- [ ] Investigate [anotherworldportal@gmail.com](mailto:anotherworldportal@gmail.com)
	- [ ] Lync C
		- [ ] 01:24 -> 03:41
		- [ ] Discussion: https://heyario.slack.com/archives/C049DGC1D2M/p1780379829392689?thread_ts=1779931262.749199&cid=C049DGC1D2M
		- [ ] **Blocked in discussion**
- [ ] Debugging yuxi PR
	- [ ] https://heyario.slack.com/archives/C049DGC1D2M/p1780383858124199
	- [ ] **Blocked in discussion**
- [x] clean up token that has insufficient permission
- [x] fix: ignore invalid grant error https://github.com/gather-engineering/demos/pull/844
- [ ] Inboxcart capacity
- [ ] check sentry

### Personal
- [x] Apply https://www.upwork.com/jobs/~022061608220786979272
---
### English
1. an auto mechanic
2. getting degree in medical
3. James is pursuing job for woman
4. education and office works
5. taking care of his own car

![[Pasted image 20260602195348.png]]
