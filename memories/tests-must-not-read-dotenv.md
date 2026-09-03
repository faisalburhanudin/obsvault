---
name: tests-must-not-read-dotenv
description: Tests must not load .env; only the server reads it via pydantic BaseSettings
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 97aa35a6-3a98-4163-a8db-1874ae2b9287
  modified: 2026-08-13T13:46:57.904Z
---

Do not add `.env` loading to the pytest suite (no `load_dotenv` in `tests/conftest.py`, no
`pytest-dotenv`). Only the *server* reads `.env`, via pydantic `BaseSettings`.

**Why:** the user rejected a `pytest_configure` hook that called `load_dotenv` for local
convenience. Keeping the test process free of `.env` means tests take credentials only from the
real environment, matching how CI supplies them as step env.

**How to apply:** for local runs of the `distill`/`mcp` suites that need credentials such as
`ACME_EMAIL`, export them by hand first — `set -a; . ./.env; set +a` — then run pytest.
