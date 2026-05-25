#!/bin/bash

set -e

REPO_DIR="/Users/faisal/workspace/src/github.com/faisalburhanudin/obsvault"

cd "$REPO_DIR"

# Stage all changes
git add -A

# Commit only if there are staged changes
if ! git diff --cached --quiet; then
    git commit -m "auto-sync: $(date '+%Y-%m-%d %H:%M')"
fi

# Pull remote changes (rebase to keep history clean)
git pull --rebase origin main

# Push local commits
git push origin main
