---
name: quicksand-fleet-drive-hackernews-script
description: Throwaway script that drives a Quicksand Fleet browser over its CDP bridge (launch, load Hacker News, scroll, terminate), kept here instead of in the repo
metadata:
  type: project
---

Manual smoke-test script for quicksand-fleet, deleted from `scripts/drive_hackernews.py` on
2026-09-03 because it should not live in the repo. Restore it from here when you need to drive a
deployed fleet by hand.

**Why:** it exercises the full public path (REST launch → `/cdp` bridge → CDP commands → REST
terminate) from outside the server, which unit and e2e tests do not cover. It uses raw CDP over
`websockets` instead of Playwright because Playwright cannot override the `Host` header that the
Dokku nginx vhost needs. Related: [[dokku-staging-access]].

**How to apply:** write the code below back to `scripts/drive_hackernews.py`, run
`uv run scripts/drive_hackernews.py` (defaults target the Dokku vhost), or
`uv run scripts/drive_hackernews.py --url http://localhost:8700 --host-header ''` for a local
`make dev` server. Delete it again afterwards. Note the old docstring example says port 8400; the
default is 8700 since commit ddbf543.

```python
#!/usr/bin/env python3
"""Drive a Quicksand Fleet browser from your own machine, over the service's CDP bridge.

Launches a browser, opens Hacker News, scrolls slowly for 5 seconds, then terminates it.

    uv run scripts/drive_hackernews.py
    uv run scripts/drive_hackernews.py --url http://localhost:8400 --host-header ''

Raw CDP over `websockets` instead of Playwright: both deps are already in this project, and
Playwright cannot override the `Host` header the Dokku nginx vhost needs.
"""

import argparse
import asyncio
import json
import time
from typing import Any

import httpx
import websockets

HN_URL = "https://news.ycombinator.com"
SCROLL_SECONDS = 5.0
SCROLL_STEPS = 10

_start = time.monotonic()


def log(message: str) -> None:
    print(f"[{time.monotonic() - _start:5.1f}s] {message}", flush=True)


class Cdp:
    """Minimal CDP client: send a command, await its reply, or await an event."""

    def __init__(self, ws: Any) -> None:
        self._ws = ws
        self._next_id = 0
        self._replies: dict[int, asyncio.Future[dict[str, Any]]] = {}
        self._events: dict[str, asyncio.Future[dict[str, Any]]] = {}
        self._reader = asyncio.create_task(self._read_loop())

    async def _read_loop(self) -> None:
        async for raw in self._ws:
            message = json.loads(raw)
            if "id" in message:
                future = self._replies.pop(message["id"], None)
                if future and not future.done():
                    future.set_result(message)
            else:
                future = self._events.pop(message.get("method", ""), None)
                if future and not future.done():
                    future.set_result(message)

    async def call(
        self, method: str, params: dict[str, Any] | None = None, session_id: str | None = None
    ) -> dict[str, Any]:
        self._next_id += 1
        message: dict[str, Any] = {"id": self._next_id, "method": method, "params": params or {}}
        if session_id:
            message["sessionId"] = session_id
        future: asyncio.Future[dict[str, Any]] = asyncio.get_running_loop().create_future()
        self._replies[self._next_id] = future
        await self._ws.send(json.dumps(message))
        reply = await asyncio.wait_for(future, timeout=60)
        if "error" in reply:
            raise RuntimeError(f"{method} failed: {reply['error']}")
        return reply.get("result", {})

    def expect_event(self, method: str) -> asyncio.Future[dict[str, Any]]:
        """Register interest *before* the command that triggers the event, to avoid a race."""
        future: asyncio.Future[dict[str, Any]] = asyncio.get_running_loop().create_future()
        self._events[method] = future
        return future

    async def close(self) -> None:
        self._reader.cancel()


async def drive(cdp: Cdp, session_id: str) -> None:
    loaded = cdp.expect_event("Page.loadEventFired")
    await cdp.call("Page.enable", session_id=session_id)
    await cdp.call("Page.navigate", {"url": HN_URL}, session_id=session_id)
    await asyncio.wait_for(loaded, timeout=60)

    title = await cdp.call(
        "Runtime.evaluate",
        {"expression": "document.title", "returnByValue": True},
        session_id=session_id,
    )
    log(f"Loaded {HN_URL} — title: {title['result']['value']!r}")

    size = await cdp.call(
        "Runtime.evaluate",
        {"expression": "({w: innerWidth, h: innerHeight})", "returnByValue": True},
        session_id=session_id,
    )
    viewport = size["result"]["value"]

    log(f"Scrolling slowly for {SCROLL_SECONDS:.0f}s ...")
    # Paced against a deadline, not a fixed sleep per step: each round trip to the server costs
    # a few hundred ms, which would otherwise stretch the 5s well past 5s.
    interval = SCROLL_SECONDS / SCROLL_STEPS
    deadline = time.monotonic() + SCROLL_SECONDS
    steps = 0
    while time.monotonic() < deadline:
        due = time.monotonic() + interval
        await cdp.call(
            "Input.dispatchMouseEvent",
            {
                "type": "mouseWheel",
                "x": viewport["w"] // 2,
                "y": viewport["h"] // 2,
                "deltaX": 0,
                "deltaY": 120,
            },
            session_id=session_id,
        )
        steps += 1
        await asyncio.sleep(max(0.0, due - time.monotonic()))

    offset = await cdp.call(
        "Runtime.evaluate", {"expression": "scrollY", "returnByValue": True}, session_id=session_id
    )
    log(f"Stopped after {steps} wheel steps at scrollY={offset['result']['value']}px")


async def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://lambda-quicksand-fleet", help="Fleet base URL")
    parser.add_argument(
        "--host-header",
        default="quicksand-fleet.lambda-quicksand-fleet",
        help="Host header for the nginx vhost. Pass '' when the URL already is the vhost.",
    )
    args = parser.parse_args()

    headers = {"Host": args.host_header} if args.host_header else {}
    api = f"{args.url.rstrip('/')}/api/v1/browsers"
    browser_id = None

    async with httpx.AsyncClient(timeout=240.0, headers=headers) as http:
        try:
            log(f"Launching a browser on {args.url} ...")
            response = await http.post(api)
            response.raise_for_status()
            browser_id = response.json()["browser_id"]
            log(f"Browser {browser_id} is up")

            ws_url = f"{api}/{browser_id}/cdp".replace("http://", "ws://", 1).replace(
                "https://", "wss://", 1
            )
            # `host=`/`port=` keep the vhost in the URL (and so in the Host header) while the TCP
            # connection still goes to the real server, which is what the nginx vhost needs.
            connect_url = ws_url
            connect_kwargs: dict[str, Any] = {}
            if args.host_header:
                real = httpx.URL(args.url)
                connect_url = str(httpx.URL(ws_url).copy_with(host=args.host_header, port=None))
                connect_kwargs = {"host": real.host, "port": real.port or 80}

            async with websockets.connect(
                connect_url, open_timeout=30, max_size=10 * 1024 * 1024, **connect_kwargs
            ) as ws:
                log("CDP bridge connected")
                cdp = Cdp(ws)

                targets = await cdp.call("Target.getTargets")
                page = next(t for t in targets["targetInfos"] if t["type"] == "page")
                attached = await cdp.call(
                    "Target.attachToTarget", {"targetId": page["targetId"], "flatten": True}
                )
                log(f"Attached to page target {page['targetId']}")

                await drive(cdp, attached["sessionId"])
                await cdp.close()
        finally:
            if browser_id:
                log(f"Closing browser {browser_id} ...")
                closed = await http.delete(f"{api}/{browser_id}")
                log(f"Browser {browser_id} {closed.json()['status']}")


if __name__ == "__main__":
    asyncio.run(main())
```
