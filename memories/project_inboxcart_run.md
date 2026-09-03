---
name: project-inboxcart-run
description: How to run the inboxcart app locally (dev server command)
metadata: 
  node_type: memory
  type: project
  originSessionId: 50588757-7042-45ee-ac7e-6d89496535b8
---

Run the inboxcart app locally from `apps/inboxcart/`:

```bash
uv run uvicorn app.main:app --port 5555
```

(`npm run dev` does the same but adds `--host 0.0.0.0 --reload`.) App listens on port 5555. Requires `INBOXCART_DATABASE_URL` and other `INBOXCART_*` vars in `.env`.

See [[project-inboxcart-manual-testing]] for forcing scheduler/backfill claims and the sign-in wake test.
