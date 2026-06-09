# claude-starter

A batteries-included Claude Code project template: the workflow skills, reference/recall memory system, session hooks, and kernel CLAUDE.md distilled from a heavily-tuned production repo — with all project-specific content stripped out.

## What's inside

- **`CLAUDE.md`** — kernel rules: popup-tool ban, caveman-ultra default prose mode, verification honesty rules, subagent dispatch discipline, git auto-commit workflow, reference-library index. Two `FILL IN` sections (verification limits, deploy target) to configure per project.
- **`.claude/skills/`** — 27 portable skills, including:
  - *Workflow:* `recall` (project memory), `caveman` (terse mode), `safe-ship`, `pr`, `addskill`, `enhance-prompt`, `handoff-audit`, `why`, `learning`, `lab`, `conflict`
  - *Discipline:* `brainstorming`, `writing-plans`, `executing-plans`, `systematic-debugging`, `test-driven-development`, `verification-before-completion`, `impartial-review`, `subagent-driven-development`, `dispatching-parallel-agents`, `using-git-worktrees`, `using-superpowers`, `writing-skills`, `applying-best-practices`, `finishing-a-development-branch`
  - *Craft:* `impeccable` (frontend design), `humanizer` (de-AI writing)
- **`.claude/reference/`** — six skeleton topic files (`secrets`, `architecture`, `pitfalls`, `commands`, `tech-stack`, `deployment`) that `recall` and `learning` populate over time.
- **`.claude/hooks/session-start.sh`** — auto-rebase onto origin/main (cloud), read-only fetch (local), caveman directive + universal-skills reminder injection.
- **`.claude/settings.json`** — hook wiring + read-only Bash permission allowlist.
- **`bootstrap/`** — the one-click project creator (template-only; removed from spawned projects).

## Creating a new project

### One click (recommended)

Double-click `bootstrap/New-ClaudeProject.cmd` (keep a copy anywhere). It prompts for a name, then:

1. Creates a **private** GitHub repo from this template (`gh repo create --template`)
2. Clones it locally
3. Removes the template-only bootstrap files

Requires the `gh` CLI authenticated (`gh auth status`). Without it, the script builds the folder locally and prints the manual repo-creation steps.

### Command line

```powershell
.\bootstrap\new-claude-project.ps1 -Name my-app -Dest C:\code
```

### GitHub UI

This repo is marked as a template — click **Use this template → Create a new repository** on GitHub, then clone. Delete `bootstrap/` and replace this README in the new project.

## After creating a project

1. Open the new folder in Claude Code.
2. Fill in the two `FILL IN` sections in `CLAUDE.md` (verification limits, environment & deploy target). Delete the template note.
3. Tune `applying-best-practices` to the project's stack (it ships as a generic web/TS baseline).
4. Start working — `recall`/`learning` will grow the reference library as quirks surface.

## Maintaining the template

Improvements discovered in any project flow back here: edit the skill/kernel in this repo, commit, push. Future projects inherit them; existing projects can cherry-pick.
