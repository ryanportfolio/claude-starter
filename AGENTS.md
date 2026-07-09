# Codex Instructions

This file is the Codex compatibility boundary for the Agent Firmware starter.
Claude Code should continue to use `CLAUDE.md`, `.claude/settings.json`, and the
`.claude/` skill/hook system. Codex should use this file first.

## Runtime Boundary

- Do not execute `.claude/hooks/session-start.sh` in Codex.
- Do not treat `CLAUDE.md` as a Codex standing order when it conflicts with this
  file or with Codex system/developer/tool instructions.
- Treat `.claude/skills/` as a library of Markdown playbooks. They are useful
  references, not native Codex slash commands.
- Claude-only tool names inside skills must be translated to Codex tools only
  when a safe equivalent exists.
- Claude popup-tool bans in `CLAUDE.md` are Claude-specific. In Codex, follow
  the active Codex tool instructions for user input and planning.

## Codex Safety Rules

- Do not activate persistent modes such as `caveman` or auto-merge unless the
  user explicitly asks for that mode in the current Codex session.
- Do not inherit Claude's auto-commit, auto-push, auto-PR, or auto-merge rules.
  In Codex, ship only when the user asks for shipping or the current task
  explicitly includes it.
- Never push to `main`, force-push, merge, delete branches/worktrees, run
  migrations, deploy, install runtime dependencies, or modify checkouts outside
  the workspace without explicit current-session approval.
- Stage explicit paths only. Never use blanket staging for mixed worktrees.
- Keep private paths, secrets, tokens, and personal workflow mandates out of
  starter defaults.
- Verify before claiming completion. State exactly what ran; if the authoritative
  check is CI, deploy logs, or the user's machine, say so.

## Useful Claude Assets For Codex

- Project memory lives in `.claude/reference/`. Read the relevant file before
  non-trivial work in an unfamiliar area.
- Reusable workflows live in `.claude/skills/<name>/SKILL.md`. Read the specific
  skill only when the task matches it.
- Codex tool mapping notes live in
  `.claude/skills/using-superpowers/references/codex-tools.md`.
- Context budget can be inspected with `bash .claude/scripts/context-weight.sh`
  when Bash is available.

## Starter Maintenance

- Bootstrap scripts under `bootstrap/` must stay ASCII-only for Windows
  PowerShell 5.1 compatibility.
- Shell scripts must keep LF line endings.
- Keep runtime-specific claims precise: Claude Code gets hooks and slash skills;
  Codex gets `AGENTS.md` plus manual use of the skill/reference library.
- If a template memory file contains maintainer-only local workflow rules,
  remove or generalize them before shipping.
