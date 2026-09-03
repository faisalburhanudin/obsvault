---
name: tap-connect-getgather-memory-leak
description: "getgather sidecar RSS growth is glibc allocator retention from bs4 churn, not a Python object leak"
metadata: 
  node_type: memory
  type: project
  originSessionId: fbb4db15-4e0e-4140-a05e-0c58ab759f73
  modified: 2026-08-12T08:47:08.395Z
---

On `tap-connect-mock-flyfleet` (Fly org `remote-browsers-dev`), the `getgather`
uvicorn sidecar's RSS grows large under load and does not return at idle
(146MB -> ~500MB across one 25-min load cycle; 147MB -> 632MB over 21h).

**It is not a Python object leak and not a C leak.** Measured with tracemalloc:
at identical idle state (sockets 6, fds 19) RSS rose +360MB while Python-traced
memory rose only +81MB, and `traced` plateaus ~79MB while RSS oscillates
385-506MB. The gap is memory Python freed that glibc keeps in its arenas —
allocator retention, most likely fragmentation from BeautifulSoup's churn in
`zen_distill` (a single bs4 line swings +15MB then -9MB between samples).

**Resolved 2026-08-12, and the fix WAS code** (an earlier note here wrongly said
otherwise): the churn came from `load_distillation_patterns` re-parsing 470
pattern files on every MCP tool call. Adding `@lru_cache` cut RSS from ~510 to
382 MiB and removed the churn at source, so `MALLOC_ARENA_MAX` / jemalloc were
never needed. See [[tap-connect-cpu-steal-root-cause]].

One genuine but minor leak confirmed: zlib compression contexts at
`websockets/extensions/permessage_deflate.py:72` are retained after their
connections close (~11MB; live bytes rose while sockets fell 44->13). Fix is
`compression=None` on `websocket_proxy`'s `websockets.connect()`.

**Why:** Memory looked like the headline problem and was not — it was a symptom
of failing tests hammering the sidecar. Chasing it further wastes time.

**How to apply:** `ps`/`free` are absent from the image; read `/proc` directly.
Compare RSS *deltas* against tracemalloc deltas, never absolutes — tracemalloc
starts in the app lifespan so ~145MB of boot allocations are never traced.
Judge retention by the *idle floor*, not peaks. Related:
[[tap-connect-test-failures-fleet]]
