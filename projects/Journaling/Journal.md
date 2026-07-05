## Backlog
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
- [ ] sentry cli
- [ ] logfire cli
- [ ] ganti ban motor
## 2026-07-02
- [x] Yuxi Dashboard
	- [x] Re-organize
- [x] Investigate slow inboxcart
	- [x] https://heyario.slack.com/archives/C049DGC1D2M/p1783022954021789
- [ ] Captcha solving
- [ ] Tab Recording
- [x] Figure out email missing 2019
	- [ ] Grouped inboxcart_emails by year + sender_email. Same 3 Amazon addresses in every year → not a sender change.
	- [ ] Sample 100, create script  is production actually missing emails? and does the fixed walk retrieve everything?
	- [ ] Sender changed
		- [ ] ![[Pasted image 20260705185913.png]]
## 2026-07-01
- [ ] Captcha solving
- [ ] Tab Recording
- [x] add tap-connect to callback gmail
- [ ] 
## 2026-06-29
- [x] fix(inboxcart): reject Google accounts without a Gmail mailbox at connect
- [x] fix: too many concurrent requests https://github.com/corelens-engineering/demos/pull/1028
- [ ] Capsolver
- [x] Backfill until 2019
- [ ] tap recording
- [x] request yuxi https://metabase.getgather.dev/dashboard/16-the-big-board
## 2026-06-25
- [x] create test manager for daytona and demo
- [x] remote browser listing feature
- [x] test yuxi issue using allowlist email
### Personal
- [x] English task
	- [x] I ate a lot yesterday because my wife made a delicious meal.
	- [x] She made fried shrimp with simple seasoning because the shrimp was very fresh, and we wanted to preserve its natural flavor. I had bought it directly from a fisherman.
	- [ ] By the time my wife finished cooking the shrimp, I had already eaten half of it.
- [x] Budgeting
	- [x] Mandiri: Pengembalian iuran tahunan
	- [ ] DBS: Pengembalian iuran tahunan
### English
- 1. a
- 2.b
- 3.b
- 4.b
- 5.c

## 2026-06-23
- [ ] tap connect daytona -> remote browser test
- [x] test cint integration
- [ ] Document remote browser

### English
- [ ] I am a programer. I have been programmer for 10 years. I am making a browser integration today.
- [ ] I love gar
- [ ] I was bored yesterday. I was begging a job to my manager when our teems conducted the morning meeting. By the afternoon, my teams had finished all of the works before the days ended.
## 2026-05-22
- [x] backfill encryption key
- [ ] research
	- [ ] Pakai Steel with browserbased
## 2026-06-19
- [x] https://github.com/corelens-engineering/demos/pull/983
- [x] debug headline-hub-lambda
- Remotebrowser discussion
	- Browserless
	- Browserbased
		- bisa human in the loop
		- jangan full desktop
		- dia rewrite CDP
	- Cloak browser
		- yg jadi vnc browsernya doang
	- Bisa direkam
		- screen recording
	- Steel browser
		- CDP langsung jalan
	- Milestones
		- pattern banyak masalah
		- investigate cloak browser 
		- fly vs daytona
			- daytona more for machine
		- **mcp auth bisa dibuang**
			- dipakai untuk menentukan nama machine
		- but we still need consider auth
			- SaaS
		- seperti browserbased **goals**
	- claude context CDP?
		- can claude connect with CDP
	- experiment
		- bisa 100% python
		- https://sourcehut.org/
	- SaaS 
	- Hubungan dengan corelens
		- Connectors
			- tap-connect
				- connect.corelens.ai
					- 1 FE
					- 1 BE
			- Tugasnya sampai dapat refresh token
			- hand off to backstage
			- connector yg nyalain remotebrowser
		- Backstage
			- User remote browser
			- bikin kyk test manager aja
			- **test pattern api**
		- Insight
	- Milestones
		- Speed topic utama
		- Masalah stealth pakai Cloak
		- Comparing current competitor
## 2026-06-18
- [x]  Use oxylabs for lambda-remotebrowser
- [ ] Backfilling
	- [x] Est cost, check availability.
	- [ ] Run.
- [ ] Check why there is no amazon

![[Pasted image 20260618202647.png]]


Every night, I **sleep with my baby in my bed room** because I **do not sleep with my wife and my daughter**.
I do not **sleep alone** because I **think it will be selfish**.
Right now, I **don't have sleeping schedule** because I **am adapting to my baby schedule.**.
Since **I slept with my baby**, I **don't have enough sleep**.

---
Yesterday, I **planted lemongrass** because I **had left over from refrigerator**.
I didn't **want to throw it away** because I **want to propagate it**.
When I **was planting the lemongrass**, I **used used orchid pot**.
I **had been clean the pot** before I **found out that the pot is too small for the lemongrass**.
![[Pasted image 20260618200026.png]]
![[Pasted image 20260618202623.png]]

## 2026-06-17
- [ ] UI to check extraction in production
- [ ] Backfilling
	- [ ] Issue found when backfilling
		- [ ] Walgreens (226 emails)
			- [ ] using transaction id instead of order id, so it not parsed
				- [ ] map transaction to order id ?
			- [ ] routes issue
		- [ ] Domino's (83 emails)
			- [ ] classify as purchase but the email is too short just contain click to view notification
				- [ ] maybe instead of classify as purchase also check is it parse able?
		- [ ] Walmart no order number for shippinggmigr
- [ ] set GIT_REV in build-arg
- [x] Migrate
	- [x] circuit-shack-lambda 
	- [x] datadash-lambda
	- [x] grabbit-lambda
	- [x] headline-hub-lambda
	- [x] page-turner-lambda
	- [x] ytboard-lambda
- [x] Clean up  insufficient authentication scopes sentry error, just 5 user ![[Pasted image 20260617190153.png]]
- [x] 200 on capacity, waiting room
## 2026-06-15
- [ ] https://github.com/gather-engineering/demos/pull/924
- [ ] https://github.com/gather-engineering/demos/pull/925
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
