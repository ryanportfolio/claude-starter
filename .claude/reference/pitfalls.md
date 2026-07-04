# Pitfalls

> Accumulated project-specific gotchas. Dated entries, newest at the bottom. If this file exceeds ~200 lines, split by area (`pitfalls-<area>.md`) and update the CLAUDE.md index.

## 2026-07-04 — Changes must land in the main checkout, not just a worktree branch/PR

**Critical (user directive):** changes must always land on `main` AND be pulled into the primary checkout at `C:\Users\Home\CoreWise\claude-starter`. That checkout is what the user actually runs (e.g. `bootstrap\New-ClaudeProject.cmd` executes the `.ps1` sitting next to it there).

Two-step trap:
1. Editing a file inside `.claude\worktrees\<name>\...` does **not** touch the main checkout — worktrees have their own working tree. A PR from a worktree branch is invisible to the tool the user runs until merged.
2. Merging the PR to remote `main` still does **not** update the physical files in the local main checkout. `git pull` in `C:\Users\Home\CoreWise\claude-starter` is required for the live files to change.

**Completion protocol for this repo:** after committing + pushing a worktree branch and opening the PR, finish the loop — merge the PR, then `git -C "C:\Users\Home\CoreWise\claude-starter" pull --ff-only`. Verify the change is present in that checkout (e.g. `grep` the edited line) before claiming done.

Symptom that means you skipped this: user re-runs the tool and gets old behavior even though the PR shows the fix.
