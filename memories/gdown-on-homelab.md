---
name: gdown-on-homelab
description: How to install and run gdown on homelab (100.122.215.60) to pull Google Drive files, plus the auth story
metadata:
  type: reference
---

`gdown` downloads Google Drive files/folders from the CLI. Installed on homelab
(100.122.215.60, WSL2 Debian) at `~/.local/bin/gdown`.

Install there needed two workarounds:

```
pip3 install --user --break-system-packages gdown
```

- Plain `pip3 install --user` fails with PEP 668 `externally-managed-environment`.
- `python3 -m venv` also fails: `python3-venv` is not installed (needs sudo apt).
- `~/.local/bin` was not on PATH; added to `~/.bashrc`.

Usage:

```
gdown "https://drive.google.com/drive/folders/<FOLDER_ID>"   # folder; --folder flag is deprecated
gdown "https://drive.google.com/uc?id=<FILE_ID>"             # single file
gdown --fuzzy "<full share URL>"                             # when the URL form is odd
```

**Auth:** gdown has no login command. Public "anyone with link" items need
nothing. For private files, export browser cookies for drive.google.com in
Netscape format to `~/.cache/gdown/cookies.txt`; they expire and must be
refreshed. For a headless server that needs durable auth, use `rclone` (real
OAuth / service accounts) instead.

Related: [[terrascope-homelab-deploy]]
