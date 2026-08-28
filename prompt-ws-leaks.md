# CDP websocket keep-alive leak

## Problem

CDP relay websockets stay open for 65-76 minutes after the job that opened
them has finished. The relay pings the remote browser every 60s for that whole
time, so the sandbox/machine never goes idle and never auto-stops.

Find why the socket is not closed when the job ends, and fix it.

## Evidence (Logfire, project `remote-browser-dev`, 24h window ending 2026-08-28)

Total CDP socket time in 24h:

| service | route | sockets | avg | max | total open |
|---|---|---|---|---|---|
| remote-browser | `/cdp/{browser_id}` | 1723 | 59s | 4585s | 28.3 h |
| fleet-gateway-dev | `/api/v1/browsers/{browser_id}/cdp` | 3345 | 25s | 4210s | 23.0 h |
| flyfleet | `/api/v1/browsers/{browser_id}/cdp` | 567 | 48s | 4205s | 7.5 h |

Worked example, browser `Bq8dtk59s` on 2026-08-28:

```
00:30:46  GET    /api/v1/browsers/Bq8dtk59s/pages     200   job starts
00:31:01  GET    /api/v1/browsers/Bq8dtk59s           200   last GET ever
00:36:20  DELETE /api/v1/browsers/Bq8dtk59s           404   browser already gone
01:47:18  HTTP   /cdp/Bq8dtk59s  closes, duration 4585s     76 min open
01:47:18  HTTP   /cdp/Bq8dtk59s  closes, duration 4577s     second socket
```

Two sockets survived the DELETE by 71 minutes. The DELETE returned 404, so the
browser was already gone, and the relay kept running anyway.

Socket holders, by user-agent: `Python/3.13 websockets/15.0.1` (the zendriver
CDP client) and `node` (the MCP client). They close in pairs per browser at
different wall-clock times, so this is not one server restart reaping them --
it looks like an idle timeout expiring somewhere downstream.

Confirmed NOT the cause: HTTP polling. After the last distill span each
browser gets exactly 1 more `GET /api/v1/browsers/{id}`, in the same second.
Every GET arriving more than 5 min later came from `curl` or a Chrome UA
(manual dashboard use). There is no polling leak.

### Queries to reproduce

Longest-lived sockets:

```sql
SELECT service_name,
       url_path,
       start_timestamp,
       end_timestamp,
       round(duration/60, 1) AS min_open,
       attributes->>'http.user_agent' AS ua
FROM records
WHERE start_timestamp >= now() - interval '24 hours'
  AND http_route IN ('/cdp/{browser_id}', '/api/v1/browsers/{browser_id}/cdp')
  AND duration > 600
ORDER BY duration DESC
LIMIT 25
```

Full timeline for one browser:

```sql
SELECT start_timestamp, end_timestamp, round(duration,1) AS dur_s,
       service_name, span_name,
       http_response_status_code AS code,
       attributes->>'http.user_agent' AS ua
FROM records
WHERE start_timestamp >= now() - interval '24 hours'
  AND url_path LIKE '%Bq8dtk59s%'
  AND kind = 'span' AND http_route IS NOT NULL
ORDER BY start_timestamp
LIMIT 100
```

## Code anchors

- `getgather/browsers/router.py:150` -- `websocket_proxy()`. Opens the remote
  leg with `ping_interval=60, ping_timeout=30, close_timeout=10`. That 60s ping
  is the traffic keeping the machine awake.
- `getgather/browsers/router.py:166` -- `client_to_remote()` blocks on
  `client_ws.receive_text()` with no timeout. If the client leaks the socket
  without disconnecting, this task never completes.
- `getgather/browsers/router.py:196` -- `asyncio.wait(..., FIRST_COMPLETED)`
  then cancels the pending task. This looks correct; the problem is that
  neither task ever finishes.
- `getgather/browsers/router.py:308` -- `relay_browser_cdp()`. Note step (1)
  auto-creates the browser if missing, so a late reconnect can resurrect a
  browser that was already deleted.
- `getgather/browsers/router.py:358` / `:368` -- the two websocket routes.
- `getgather/cdp_client.py:30` -- `open_cdp()` and `CDPClient`, whose
  `_reader_task` is the `Python/3.13 websockets` client side.
- There is an existing worktree named `cdp-ws-ping-interval` -- check whether
  it already contains work on this.

## Hypotheses to test, cheapest first

1. The relay has no idle timeout. `ping_interval=60` keeps both legs healthy,
   so a client that forgets to close leaves the socket up until some external
   timeout fires. Test: does any code path close the relay when the browser is
   deleted?
2. The client leaks. `CDPClient.aclose()` is not called on some path -- an
   early return, an exception, or a task that outlives its request. Test: audit
   every `open_cdp` caller for a `finally: await client.aclose()`.
3. The relay should die when the browser is deleted but does not. `DELETE`
   returned 404 at 00:36 while the socket lived to 01:47, so nothing links the
   two.

## Acceptance

- A CDP relay socket closes within a bounded time after its last message, not
  65-76 minutes.
- Deleting a browser closes any relay socket still open for it.
- No 60s ping traffic continues to a browser whose job has ended.
- `make check` passes. Add a regression test near
  `tests/test_browser_backend.py:151`, which already exercises the relay via
  `_relay_roundtrip`.

## Non-goals

- Do not touch the HTTP polling path. It was investigated and is clean.
- Do not change the Daytona or Podman last-activity code; that was already
  fixed in commit 6c1d131.
- Do not add config knobs unless the fix genuinely needs one.

Start by reading the code anchors and confirming which hypothesis holds before
changing anything.
