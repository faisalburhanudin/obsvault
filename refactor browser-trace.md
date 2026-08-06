# Task: replace browser-trace's config file with a push-based config endpoint

## Repos

| Role                                             | Path                                                                   |
| ------------------------------------------------ | ---------------------------------------------------------------------- |
| Browser container image (owns `browser-trace`)   | `/Users/faisal/workspace/src/github.com/remotebrowser/chrome-live`     |
| Control plane that creates & configures browsers | `/Users/faisal/workspace/src/github.com/corelens-engineering/flyfleet` |
|                                                  |                                                                        |

## Background: how config reaches browser-trace today

`browser-trace` is a Python service inside the chrome-live container. It reads a key=value file,
`/app/browser-trace.conf`. Three different mechanisms currently write that file or its values:

1. **Boot templating.** `root/etc/s6-overlay/s6-rc.d/browser-trace/run` runs `sed` to substitute
   `${PLACEHOLDER}` tokens in `browser-trace.conf` from the container's env.
2. **A remote `sed` from another repo.** flyfleet shells into the running machine to rewrite one
   line — see finding 1.

## Findings from the investigation

### 1. The conf is a cross-repo RPC channel whose wire format is a file path and a regex

flyfleet sets the Logfire trace parent by shelling into the machine:

```python
# flyfleet src/browser_trace.py:5,13
CONF_PATH = "/app/browser-trace.conf"
f"sed -i 's/^LOGFIRE_TRACEPARENT=.*/LOGFIRE_TRACEPARENT={traceparent}/' {CONF_PATH}"
```
```python
# flyfleet src/fly/fly_machine.py:180-189
async def configure_logfire_traceparent(self) -> None:
    cmd = build_set_traceparent_command()
    ...
    await self.exec(["bash", "-c", cmd])
```

Consequences:

- chrome-live cannot rename that key, reformat the line, or move the file without silently
  breaking flyfleet. There is no contract, no version, no test spanning the two repos.
- **It fails silently.** `sed -i` that matches nothing exits 0. If the line is ever removed or
  renamed, flyfleet logs `"Logfire traceparent configured successfully"` and nothing happened.
  (Precedent: two other lines were removed from this conf in `a8c355e`.)
- The value is interpolated unescaped into both a shell command and a sed replacement whose
  delimiter is `/`. Safe today only because traceparents are hex-and-dashes.
- `fly_machine.py:188` swallows all exceptions ("not critical"), so genuine failures are invisible too.

### 2. The same value arrives by two paths

`LOGFIRE_TRACEPARENT` is passed as machine env at create time (`flyfleet src/fly/fly_machine.py:67`)
**and** re-sedded per session, because machines are reused across sessions under
`autostop: "suspend"`.

### 3. Three values share one lifecycle but use three mechanisms

`traceparent`, `upload_enabled` (future dev), `browser_id` (future dev) are all: per-session, known by flyfleet, must change
on a running machine, not secrets. They are served respectively by create-env + remote sed, by
POST + conf write-back, and by POST + conf write-back.

### 4. The HTTP channel already exists

flyfleet already proxies to browser-trace over 6PN:

- `flyfleet src/app.py:104` — `/api/v1/browsers/{browser_id}/trace/{path:path}`, all methods
- `flyfleet src/trace_proxy.py:10` — `BROWSER_TRACE_PORT = 8088`
- Already carries `/recordings`, `/traffic`, `/health`, including streamed MP4 with Range support.

This is not new plumbing. It is one more call down a pipe that already works.

##  Verify

- It does **not** need to be durable. flyfleet always sets the upload toggle when it asks a browser
  to store recordings, so re-asserting after a restart is acceptable and expected.

## Proposal to implement

**Split config by lifecycle, not by file.**

| Class                 | Values                                                                                                                           | Mechanism                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| Bootstrap / static    | `LOGFIRE_TOKEN`, `SERVICE_NAME`, `ENVIRONMENT`, `LOG_LEVEL`, `CDP_HOST/PORT`, `RECORDING_DIR`, `HTTP_HOST`, `BROWSER_TRACE_PORT` | Fly secrets/env → read once at startup     |
| Per-session / dynamic | `traceparent`, `upload_enabled`, `browser_id`                                                                                    | `POST /config` on browser-trace, in memory |

