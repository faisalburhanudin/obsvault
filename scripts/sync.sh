#!/bin/bash
#
# Obsidian vault auto-sync. Run from cron/launchd.
# Logs every run and raises a macOS notification if anything fails, so a
# blocked commit (see scripts/git-hooks/pre-commit) or a rebase conflict
# never fails silently.
#
set -uo pipefail

REPO_DIR="/Users/faisal/workspace/src/github.com/faisalburhanudin/obsvault"
LOG="$REPO_DIR/scripts/sync.log"

cd "$REPO_DIR" || exit 1

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG"; }

notify() {
  # $1 = short reason. terminal-notifier is reliable from launchd/background
  # contexts; osascript is a fallback for interactive runs.
  local msg="$1"
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier -title "obsvault sync failed" -message "$msg" -sound Basso >/dev/null 2>&1 && return
  fi
  command -v osascript >/dev/null 2>&1 && \
    osascript -e "display notification \"$msg\" with title \"obsvault sync failed\" sound name \"Basso\"" >/dev/null 2>&1 || true
}

# Any failing step lands here with the step name.
fail() {
  local step="$1"
  log "FAILED at: $step (see output above)"
  notify "$step — check scripts/sync.log"
  exit 1
}

log "=== sync start ==="

# Stage everything.
git add -A >>"$LOG" 2>&1 || fail "git add"

# Commit only if something is staged. The pre-commit hook runs here and will
# abort the commit (non-zero) if it detects secrets / an .env dump.
if ! git diff --cached --quiet; then
  if ! git commit -m "auto-sync: $(date '+%Y-%m-%d %H:%M')" >>"$LOG" 2>&1; then
    fail "git commit (blocked by pre-commit hook? secrets detected)"
  fi
fi

# Pull remote changes (rebase to keep history linear).
if ! git pull --rebase origin main >>"$LOG" 2>&1; then
  git rebase --abort >>"$LOG" 2>&1 || true
  fail "git pull --rebase (conflict — resolve manually)"
fi

# Push.
git push origin main >>"$LOG" 2>&1 || fail "git push (rejected — secret scanning or non-fast-forward?)"

log "=== sync ok ==="
