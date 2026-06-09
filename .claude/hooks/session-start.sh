#!/bin/bash
set -euo pipefail

# SessionStart hook
#
# Design principle: do work Claude can't do itself, surface things Claude can't
# otherwise see, and stay quiet about anything Claude can recompute on demand.
#
# CLOUD (CLAUDE_CODE_REMOTE=true):
#   - Auto-rebase current branch onto origin/main (cloud sandbox is isolated,
#     safe to rewrite)
#   - Print the universal-skills reminder block
#
# Note: we deliberately do NOT cat CLAUDE.md here. Claude Code auto-loads it as
# project memory, and SessionStart only injects context via stdout/additionalContext
# (not stderr) — so a stderr cat was redundant noise, not context injection.
#
# LOCAL (CLAUDE_CODE_REMOTE unset):
#   - Read-only fetch from origin (prime the cache, no output)
#   - Print the universal-skills reminder block
#   - Never modify the working tree or any branch

# Retry a git fetch up to 4 times with exponential backoff (2s, 4s, 8s, 16s).
# The cloud sandbox's local git proxy occasionally returns transient 503s;
# without retries, a single blip surfaces as a SessionStart hook error.
# Usage: fetch_with_retry <args to pass to git fetch...>
fetch_with_retry() {
  local attempt=1
  local max_attempts=4
  local delay=2
  while [ "$attempt" -le "$max_attempts" ]; do
    if git fetch "$@" 2>&1; then
      return 0
    fi
    if [ "$attempt" -lt "$max_attempts" ]; then
      echo "[SessionStart] fetch attempt $attempt failed, retrying in ${delay}s..." >&2
      sleep "$delay"
      delay=$((delay * 2))
    fi
    attempt=$((attempt + 1))
  done
  return 1
}

# Print the caveman-ultra session default to STDOUT.
#
# CRITICAL: this goes to stdout, NOT stderr. SessionStart injects context only
# via stdout/additionalContext — stderr is user-visible diagnostic noise that
# Claude never sees. The caveman default lives in CLAUDE.md, but project memory
# is easy to miss at session start, so we re-assert it here as injected context
# to make it the first thing Claude acts on. Keep it on stdout or it does nothing.
print_caveman_directive() {
  cat <<'CAVEMAN'
[SessionStart] ACTIVE SESSION DEFAULT — caveman ultra (per CLAUDE.md).
BEFORE your first reply, invoke the `caveman` skill at ultra intensity (Skill tool,
args: "ultra") and apply that style to ALL prose replies for the entire session:
terse, abbreviated, arrows for causality, full technical accuracy preserved. This
persists across this and every future session until the user says "stop caveman" /
"normal mode".
  - Prose only. Code, commits, PRs, file contents, and symbol/function/API/error
    strings stay normal and are never abbreviated.
  - Auto-clarity carve-outs: security warnings, irreversible-action confirmations,
    and ambiguous multi-step sequences drop to plain prose, then resume caveman.
CAVEMAN
}

# Print the fixed "universal skills" reminder block.
# Cross-cutting skills that apply to most sessions regardless of task; project-
# specific skills are not listed — Claude discovers those from the
# available-skills list.
print_skill_reminders() {
  cat >&2 <<'SKILLS'
[SessionStart] Universal skills — invoke proactively when the trigger fires:
  - caveman                       → FIRST, at session start: /caveman ultra (default prose mode)
  - applying-best-practices       → BEFORE non-trivial edits (features, refactors, perf, bug fixes)
  - recall                        → BEFORE work in unfamiliar areas; /recall save <text> after gotchas
  - verification-before-completion → BEFORE claiming work is done / committing / opening a PR
  - systematic-debugging          → ON any bug, test failure, or unexpected behavior
  - test-driven-development       → BEFORE writing implementation code for a feature or bugfix
  - brainstorming                 → BEFORE designing new features or behavior changes
  - safe-ship                     → BEFORE pushing / opening a PR
  - impartial-review              → AFTER substantive changes, before merging
SKILLS
}

# Inject the caveman-ultra default into context FIRST (stdout), before any git
# work or branch-specific exit. Independent of git state, so it runs every path.
print_caveman_directive

# ---------- Cloud path ----------
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  echo "[SessionStart] Syncing branch with latest main..." >&2

  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "[SessionStart] Already on main branch, skipping sync" >&2
    print_skill_reminders
    exit 0
  fi

  echo "[SessionStart] Fetching origin/main..." >&2
  if ! fetch_with_retry origin main; then
    echo "[SessionStart] Warning: Failed to fetch origin/main after 4 attempts; continuing without sync" >&2
    print_skill_reminders
    exit 0
  fi

  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "[SessionStart] Warning: Uncommitted changes detected, skipping sync" >&2
    print_skill_reminders
    exit 0
  fi

  echo "[SessionStart] Rebasing $CURRENT_BRANCH onto origin/main..." >&2
  if git rebase origin/main 2>&1; then
    echo "[SessionStart] ✓ Successfully rebased onto origin/main" >&2
  else
    echo "[SessionStart] Rebase failed, aborting..." >&2
    git rebase --abort 2>/dev/null || true

    echo "[SessionStart] Attempting merge with origin/main..." >&2
    if git merge origin/main --no-edit 2>&1; then
      echo "[SessionStart] ✓ Successfully merged origin/main" >&2
    else
      echo "[SessionStart] Warning: Merge failed, you may need to resolve conflicts manually" >&2
      git merge --abort 2>/dev/null || true
      print_skill_reminders
      exit 0
    fi
  fi

  print_skill_reminders
  exit 0
fi

# ---------- Local path ----------
# Skip silently if not a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# Skip silently if no origin remote
if ! git remote get-url origin >/dev/null 2>&1; then
  exit 0
fi

# Quiet read-only fetch — prime the cache so subsequent git commands in this
# session see up-to-date refs. No output unless retries trigger a warning.
fetch_with_retry --all --prune --quiet 2>/dev/null || \
  echo "[SessionStart] Warning: fetch failed after 4 attempts; reporting from cached state" >&2

print_skill_reminders

exit 0
