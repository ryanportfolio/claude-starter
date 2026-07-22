---
name: distribute-skill
description: Use when the user asks to copy, distribute, or propagate a skill from this repo to another of their repos (e.g. range, Extract-Video-Wisdom, kbase), or to roll a skill out across repos.
---

# Distribute Skill — copy a SKILL.md to other repos

Ship one or more skills from this repo's `.claude/skills/` into other repos the user owns, one PR per target repo. This encodes hard-won Windows/auth gotchas — do not improvise around them.

## Step 1: Confirm scope (required — do not skip)

Opening PRs in other repos is a publish action. Before touching any remote, state in plain prose:

- which skill(s) will be copied, and
- the exact target repo list,

then wait for the user's confirmation — unless the user's request this turn already named both explicitly (e.g. "copy caveman to range and kbase"), in which case restate and proceed.

Known targets (verify with the user if ambiguous; this list rots):

| Alias | GitHub repo | Local checkout(s) |
|---|---|---|
| range | `ryanportfolio/range` | `C:\Users\Home\CoreWise\range` |
| EVW | `ryanportfolio/Extract-Video-Wisdom` | TWO checkouts: `C:\Users\Home\Documents\CoreWiseLocal\Extract-Video-Wisdom` and `C:\Users\Home\CoreWise\Extract-Video-Wisdom` — ONE repo, ONE PR, never two |
| kbase | `ryanportfolio/kbase` | `C:\Users\Home\CoreWise\kbase` |

## Step 2: Preflight each target (before any write)

Auth/remote quirks bite here more often than anything else. For each target, cheaply verify access first:

```
gh api repos/ryanportfolio/<repo> --jq .full_name
```

- 404/403 → report that target as inaccessible and continue with the rest; never partial-succeed silently. Known history: repos under old handles (`Aoh1578`, `ryanportfoilio`) 404 or deny; remotes may carry stale tracking refs.
- Local checkouts often sit on feature branches with WIP — do NOT commit into them. Distribution goes through the API or a fresh branch, never through the user's working tree.

## Step 3: Copy via gh contents API (not worktree checkout)

Windows MAX_PATH kills worktree checkouts for deep paths (EVW confirmed). Use the contents API to write files onto a new branch:

1. Get the default-branch head SHA:
   `gh api repos/ryanportfolio/<repo>/git/ref/heads/main --jq .object.sha`
2. Create branch `skill/<skill-name>` from it:
   `gh api repos/ryanportfolio/<repo>/git/refs -f ref=refs/heads/skill/<skill-name> -f sha=<sha>`
3. For each file in the skill folder (SKILL.md + any support files, base64-encoded):
   `gh api -X PUT repos/ryanportfolio/<repo>/contents/.claude/skills/<skill-name>/<file> -f message="feat(skills): add <skill-name>" -f content=<base64> -f branch=skill/<skill-name>` — include `-f sha=<blob-sha>` when the file already exists (fetch it first; a PUT without sha on an existing path 422s).
4. Open the PR: `gh pr create --repo ryanportfolio/<repo> --base main --head skill/<skill-name> ...`

Strip claude-starter-specific content before copying (worktree-scoped notes, references to this repo's scripts) if the target repo lacks them — read the skill body, don't copy blind.

## Step 4: Report per target

One line per target: PR URL, or the exact error (`gh` output) if it failed. Never summarize a partial rollout as complete. If the target repo lacks `.claude/skills/` conventions entirely, say so — the PR may need a CLAUDE.md pointer too, flag it rather than silently adding one.

## Anti-patterns

- Don't clone or `git worktree add` the target repo on Windows — MAX_PATH.
- Don't commit into the user's existing local checkouts — they carry feature-branch WIP.
- Don't open two PRs for EVW's two checkouts — one repo, one PR.
- Don't proceed past a 404/403 silently — report the auth matrix failure per target.
- Don't copy the Codex adapter (`.agents/`) — target repos generate their own if they have the sync script; otherwise it's noise.
