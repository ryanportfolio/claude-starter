---
description: One-time first-session setup for a project spawned from the claude-starter template. Use when the user says /init-project, "set up this project", "configure the starter", "initialize the template" — or proactively when you notice CLAUDE.md still contains "FILL IN" template markers at the start of a session. Detects the stack from the scaffold, fills CLAUDE.md's FILL IN sections via a short Q&A, seeds the reference files, tunes the best-practices catalog to the stack, removes template notes, and commits.
---

# init-project — configure a freshly spawned starter project

The starter template ships with placeholder sections that MUST be configured before the kernel rules are trustworthy. This skill is the guided path: detect what's detectable, ask only what isn't, write it all down, commit.

Run it ONCE per project. If `grep -c "FILL IN" CLAUDE.md` returns 0, the project is already configured — say so and exit.

## Step 1: Detect the stack (no questions yet)

Look before asking. Gather from the repo itself:

- `ls` the root — what scaffold exists? (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `*.csproj`, nothing yet?)
- If `package.json` exists: read `scripts` (build/dev/test/check commands), `dependencies` (framework, router, query lib, ORM), `devDependencies` (bundler, test runner).
- Equivalent manifest reads for other ecosystems.
- `git remote get-url origin` — the repo path for PR links.

If the repo is EMPTY (fresh spawn, no app code yet), that's fine — note it and skip detection-dependent steps; the user may be about to scaffold. Offer to re-run `/init-project` after scaffolding instead of guessing.

## Step 2: Ask what detection can't answer

Plain chat, numbered (popup tools are banned). Only ask what's actually unknown — skip questions the scaffold already answered:

1. **Deploy target:** where will this run? (host/platform, database, where secrets live)
2. **Sandbox capabilities:** can sessions in this environment run installs, builds, type-checks, tests meaningfully? Can the user reach a dev server the session starts? Is there a browser?
3. **Authoritative verification:** what's the final word that a change works — local test suite, CI, a deploy log?
4. **Hard lines:** anything that must ALWAYS go through the user (installs, migrations, deploys, destructive ops)?

If the user doesn't know yet (brand-new project), write the honest default: "not yet decided — ask before installs/migrations/deploys" and move on. Don't stall setup on undecided infrastructure.

## Step 3: Fill in CLAUDE.md

- Replace the **verification** FILL IN section with the real answer from Step 2 (what this sandbox can/can't verify, what the authoritative signal is, what to flag-as-risk instead of claim).
- Replace the **Environment & Deploy Target** FILL IN section with the deploy target, install policy, migration policy, and hard lines.
- Delete the `STARTER TEMPLATE NOTE` comment block and every `FILL IN` comment.
- Keep the section structure — future sessions navigate by those headings.

## Step 4: Seed the reference files

- `commands.md` — the detected scripts/commands, verbatim and runnable.
- `tech-stack.md` — detected framework + any non-default picks the user names (and WHY, if they say).
- `deployment.md` — the deploy answers from Step 2.
- Leave `pitfalls.md` / `architecture.md` / `secrets.md` skeletal — they fill organically via `/recall save`.

## Step 5: Tune applying-best-practices

Open `.claude/skills/applying-best-practices/SKILL.md`. The catalog ships as a generic web/TS baseline:

- Non-web or non-JS project → cut the React/bundle/query-cache sections entirely; keep the discipline section and the Async/IO + JS-perf generics that still apply (or their ecosystem equivalents).
- Web project → trim to the actual stack (e.g. drop query-cache rules if there's no query library yet; note the framework's idioms).
- Empty repo → leave as-is, note in the file that it's untuned.

## Step 6: README

If `README.md` is the spawn stub (`# <name>` only), ask the user for a one-line project description and expand it minimally: name, one-liner, how to run (from `commands.md`). Don't write aspirational docs for code that doesn't exist.

## Step 7: Wire the starter remote

```
git remote get-url starter || git remote add starter https://github.com/Aoh1578/claude-starter.git
```

This pre-wires `/sync-starter` and lets the session-start hook surface template drift ("starter differs on N files"). Remotes are local git config, not committed — mention that a new clone on another machine needs this line re-run (or the hook's URL-fallback fetch covers it when credentials allow).

## Step 8: Commit

Follow the project's git rule: branch (`feat/init-project`), stage exactly the files this skill touched, commit, push, open the PR. Tell the user it's safe to merge immediately — it's configuration, not code.

## Anti-patterns

- Don't invent deploy facts or sandbox capabilities — wrong kernel rules are worse than FILL IN markers. Ask, or write the honest "undecided" default.
- Don't run installs just to probe the stack — read manifests instead.
- Don't leave any `FILL IN` marker behind. `grep -n "FILL IN" CLAUDE.md` must return nothing at the end.
- Don't pad the reference files with boilerplate prose — they're lookup tables for future sessions, not documentation theater.
- Don't run this twice. Configured projects evolve via `/recall save` and direct CLAUDE.md edits, not re-initialization.
