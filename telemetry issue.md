# `RecursionError` flood from Logfire when running the frozen browser-trace binary

## Summary

When `browser-trace` runs as the PyInstaller onefile binary (i.e. how it ships
in the container), Logfire repeatedly throws
`RecursionError: maximum recursion depth exceeded` and dumps long nested
tracebacks to stderr. Logfire catches the error internally, so **functionality is
not affected** — recordings, CDP handling, and the HTTP server all work — but the
logs are flooded with multi-frame tracebacks and telemetry is silently degraded
("Your code should still be running fine, just with less telemetry").

This is **pre-existing** (not introduced by the recordings-HTTP-server change);
it was surfaced while running the browser-trace binary end-to-end.

## Environment

- `browser-trace` built as a PyInstaller **onefile** binary (`browser-trace.spec`)
- `logfire` runtime
- Reproduces regardless of whether `LOGFIRE_TOKEN` is set

## Observed output

```
No source code available. This happens when running in an interactive shell,
using exec(), or running .pyc files without the source .py files.
Caught an internal error in Logfire. Your code should still be running fine,
just with less telemetry. This is just logging the internal error.
Traceback (most recent call last):
  File "logfire/_internal/main.py", line 731, in log
  File "logfire/_internal/stack_info.py", line 84, in get_user_stack_info
  File "logfire/_internal/stack_info.py", line 96, in get_user_frame_and_stacklevel
RecursionError: maximum recursion depth exceeded

During handling of the above exception, another exception occurred:
Traceback (most recent call last):
  File "logfire/_internal/ast_utils.py", line 229, in warn_inspect_arguments
  File "logfire/_internal/main.py", line 461, in warning
  File "logfire/_internal/main.py", line 744, in log
  File "logfire/_internal/formatter.py", line 258, in logfire_format_with_magic
  File "logfire/_internal/formatter.py", line 49, in chunks
  File "logfire/_internal/formatter.py", line 74, in _fstring_chunks
  File "logfire/_internal/ast_utils.py", line 162, in __init__
  File "logfire/_internal/ast_utils.py", line 175, in _get_call_node
  File "logfire/_internal/ast_utils.py", line 229, in warn_inspect_arguments
  ...  (repeats until RecursionError)
```

## Root cause

We pass **dynamically-built strings** as the Logfire *message template*. See
`browser-trace/main.py`:

- `_emit_with_traceparent()` calls `log_func(msg, **attrs)` (main.py ~line 105).
- `msg` is assembled at runtime and can contain `{` / `}` characters — e.g. tab
  URLs, error text, and event payloads (`emit_cdp_event`, main.py ~line 138:
  `msg = f"{_log_prefix} {event}"` then `msg += f": {tab_url}"` etc.).

Logfire treats the first positional argument as a **message template**. When that
string contains brace-like tokens, Logfire invokes
`logfire_format_with_magic` → `warn_inspect_arguments`, which tries to read the
**call site's source** to recover the template's field names. In a frozen
PyInstaller binary there is no `.py` source ("No source code available"), so it
tries to emit a warning — and that warning goes back through the same formatter,
which again hits `warn_inspect_arguments`, recursing until `RecursionError`.

### Why `inspect_arguments=False` doesn't prevent it

`logfire.configure(..., inspect_arguments=False, ...)` is already set
(main.py ~line 164). That disables the *magic f-string variable extraction*, but
the formatter still walks the message as a template when it contains `{...}`
tokens, so it still reaches the `warn_inspect_arguments` → no-source →
recursive-warning path.

## Proposed fix (options)

1. **Don't put dynamic content in the template position** (preferred). Emit a
   static template and pass the human string as an attribute, e.g. in
   `_emit_with_traceparent`:
   ```python
   log_func("{message}", message=msg, **attrs)
   ```
   The dynamic string is then plain data — Logfire never tries to parse it as a
   template, so the recursive path is never entered. This is the Logfire-
   recommended pattern for non-literal messages.

2. **Escape braces** in the assembled message before passing it (`msg.replace("{", "{{").replace("}", "}}")`). Works, but easy to forget at new call sites.

3. **Bundle source / adjust the frozen build** so `warn_inspect_arguments` can
   read source. Heavier and doesn't address the underlying "dynamic string as
   template" smell.

Recommend option 1, applied at the two emit sites (`main.py` ~line 145 and
~line 638) via `_emit_with_traceparent`.

## Impact / severity

- **Severity:** low (cosmetic + telemetry quality) — no functional breakage.
- **Cost:** noisy logs (each occurrence is a deep nested traceback) and reduced
  Logfire telemetry fidelity for the affected records.

## Notes

Discovered during an end-to-end run of the browser-trace binary against real
Chromium + ffmpeg (arm64, podman) while validating the recordings HTTP server.
The recursion appeared in the browser-trace log; all recordings completed
successfully regardless.
