---
description: Rewrite a rough or under-specified request into a polished, copy/paste-ready prompt that any agent or LLM can act on cold. Use when the user gives a quick description of something they want done and asks for it to be turned into a better prompt — e.g., "make this a good prompt", "rewrite this so I can paste it into a new session", "turn this into a copy/paste prompt", or invokes the skill with their rough request as the argument. Output is one fenced markdown block the user copies verbatim, plus a 1-2 sentence note on what changed. The output prompt is platform-neutral (no references to specific tools, agents, or platforms) but project-aware (encodes relevant constraints from CLAUDE.md when applicable to the task).
---

# Enhance prompt

Turn the user's rough request (in `$ARGUMENTS`) into a single, polished prompt that an agent with no prior conversation memory can act on. The output must be platform-neutral — it should work whether the user pastes it into a fresh coding-agent session, an in-IDE assistant, or a generic chat LLM.

**The prime directive: every sentence must change what the receiver does.** If cutting a sentence wouldn't alter the receiver's behavior, cut it. A 200-word prompt that's all signal beats an 800-word prompt that repeats itself.

## Step 1: Extract the real goal

Look past surface wording. Common patterns to recognize:

- "Review X" usually means **audit + propose, not edit**. Phase the work.
- "Add feature X" needs scope, edge cases, UI placement
- "Fix bug X" needs reproduction steps, current vs expected behavior
- "Refactor X" needs scope boundaries (which files, which patterns to keep)
- "Make it better / cleaner / faster" needs concrete success criteria

If the request is genuinely ambiguous on a point that materially changes the output, ask the user once before drafting. Otherwise proceed and surface assumptions inside the prompt as `<TODO: confirm>` placeholders.

## Step 2: Gather receiver-cold context

The receiver has no memory of this conversation and may have no view of the codebase. Add the context they need to act:

- **File paths and line numbers** — if they exist and you can grep them, include them. `Edit client/src/pages/Foo.tsx:142` is 10× more actionable than "edit the foo page."
- **Existing patterns to match** — point at one reference in the codebase ("follow the pattern in `bar.tsx:80-110`")
- **Current state vs desired state** — for bug fixes and changes, spell both out concretely
- **Don't invent facts.** If the user didn't tell you a tier name, file path, or behavior and you can't verify it, leave a `<TODO: user fills in>` placeholder rather than making something up.
- **Don't quote large code blocks.** Reference the file path; if the receiver has repo access they'll read it. Quote the minimum necessary only when the receiver clearly won't have repo access.

## Step 3: Write it like a prompt engineer

Craft rules for the prompt body — these are what separate a good prompt from a transcribed wish:

- **Clear and direct.** Write for a brilliant new employee with zero context on your norms. Golden rule: if a colleague with minimal context would be confused by a sentence, the receiver will be too.
- **Explicit action verbs.** Modern models follow instructions literally: "can you suggest changes" gets suggestions, not edits. Write "Change/Implement/Fix X" when edits are wanted, "Propose/List, do not edit" when they're not. Never leave the act-vs-advise question implicit.
- **Say what to do, not what to avoid.** "Write flowing prose paragraphs" beats "don't use markdown." Convert every negative you can into its positive counterpart; keep negatives only as scope guards ("don't refactor unrelated files").
- **Attach the why to non-obvious constraints.** "Never use ellipses — the output is read by a text-to-speech engine" lets the receiver generalize correctly; a bare rule invites literal-minded misfires. Obvious constraints don't need justification — that's padding.
- **Calm imperative tone.** No "CRITICAL:", "YOU MUST", or ALL-CAPS emphasis — current models overtrigger on aggressive language and it reads as noise. Plain "Do X" is followed just as reliably. Reserve strong emphasis for at most one genuinely blocking rule.
- **Quality modifiers where quality is the point.** If the user wants above-and-beyond output, say so concretely: "Include as many relevant features and interactions as possible; go beyond the basics." Vague prompts get on-distribution median output.
- **Structure with XML tags when content types mix.** If the prompt combines instructions, pasted data/logs, and examples, wrap each in its own tag (`<instructions>`, `<context>`, `<input>`, `<example>`) so the receiver can't confuse data with directive. A short single-purpose prompt doesn't need tags — don't add ceremony.
- **Long pasted content goes at the top, the task at the end.** For prompts carrying 1k+ tokens of logs, docs, or data, put the material first and the instructions/question after it — this measurably improves response quality. For very long documents, add "quote the relevant parts before answering."
- **A role line only when it changes behavior.** "You are a senior security engineer reviewing for OWASP Top 10" focuses the review; "You are a helpful assistant" is dead weight.
- **Examples when format matters.** If the deliverable has a specific shape (severity-tagged findings, a particular table layout), one or two concrete examples in `<example>` tags steer format more reliably than prose description. Keep them short and representative; skip them when the format is obvious.
- **A self-check line for verifiable work.** "Before you finish, verify the change against [the failing test / a type-check / the listed criteria]" reliably catches errors. Match the check to the task; don't bolt a generic "double-check your work" onto everything.
- **General solutions, not test-passers.** For tasks with tests or specific examples, add: "Implement the actual logic that solves the problem generally — do not hard-code values or special-case the given examples. If a test or requirement is itself wrong, say so rather than working around it."
- **Grounding for codebase questions.** When the task is answering questions about existing code, add "read the relevant files before making claims about them; don't speculate about code you haven't opened."

## Step 4: Phase risky work

Anything that touches user-visible copy, database schemas, public APIs, model routing, payment logic, or is a large refactor → split into phases and tell the receiver to STOP between them:

1. **Phase 1: Audit / propose only.** Write findings to `.tmp/<task>-plan.md` or list inline. No file edits.
2. **Phase 2: User reviews.**
3. **Phase 3 (separate prompt or continuation): Implement the approved subset.**

For safe, mechanical work (typo fixes, renaming a single internal variable, adding a console log), a single phase is fine.

When in doubt, phase it. Cheap to skip a phase, expensive to undo a bad edit.

## Step 5: Specify the deliverable

Always include:

- **What artifacts to produce** (file edits, a markdown audit, a new component, a verification script, etc.)
- **Format if structured output is expected** (table layout, severity-tagged list, JSON shape, fenced sections with specific headings)
- **Verification step** — type-check, screenshot, dry-run script — appropriate to the task
- **Scope guards** — common ones: "don't refactor unrelated files", "don't add tests unless asked", "don't install packages without confirmation", "don't change user-facing copy outside the listed strings". For tasks prone to gold-plating, add an anti-overengineering line: "keep the solution minimal — no extra abstractions, configurability, or defensive code beyond what the task needs."

## Step 6: Bake in relevant project constraints

If a `CLAUDE.md` exists in the working directory, skim it for rules that touch the current task and **inline only those rules, stated as plain constraints**. The receiver may not have CLAUDE.md and shouldn't need it — never write "read the CLAUDE.md", "follow the project guidelines", or "CLAUDE.md says X". If a rule matters, it goes in the prompt verbatim as a constraint; if it doesn't, it stays out.

High-frequency categories to consider including when applicable:

- **Naming or terminology policies** — if task touches error surfaces, banners, or user-facing copy that mentions providers/products by name
- **Manual package install policy** — if task may add dependencies
- **Manual DB migration policy** — if task involves schema changes
- **Translation / i18n approval flow** — if task changes user-facing wording
- **Settings duplicated across multiple files** — if task touches a config that's known to live in multiple places (e.g., default model lists, feature flags)
- **Multi-theme / multi-mode UI requirements** — if task adds visual elements

## Step 7: Keep the output platform-neutral

The output prompt must work regardless of who/what executes it.

- ❌ Don't say "use the Bash tool", "via the Task subagent", "as Claude Code", or name any other specific agent platform
- ❌ Don't reference specific UI affordances of one platform ("click the X button in the sidebar")
- ✅ Do say "run the following command", "search the codebase for X", "edit the file at `path:line`", "produce a markdown file at `<path>`"
- ✅ Do specify outcomes and artifacts, not the path to get there

The receiver will use whatever tools they have. Trust them with the *what*; don't prescribe the *how* unless the *how* is itself the point.

## Step 8: Output format

Produce **one outer-fenced markdown block** the user can copy verbatim. Use four backticks for the outer fence so any triple-backtick code blocks inside render correctly:

````
```markdown
[the polished prompt goes here]
```
````

Above the block, add a 1-2 sentence note on what changed from the user's input — e.g., "I added a phase split, three file path references, and the copy-policy constraint since this touches user-facing wording."

Do NOT execute the prompt yourself. Do NOT make any file edits as part of running this skill. The deliverable is the prompt — nothing more.

## Anti-patterns to avoid

- **Don't instruct the receiver to do what its environment already does.** Never include: "read the CLAUDE.md / project guidelines first", "use your available tools", "explore the codebase to understand it", "be thorough and careful", "think step by step". Agent harnesses inject project instructions and tool guidance automatically; a chat LLM has neither. Either way the sentence is dead weight.
- **Don't pad.** If a sentence doesn't change what the receiver does, cut it. This includes restating the goal in different words, generic quality exhortations, and summaries of the prompt within the prompt.
- **Don't invent constraints the user didn't ask for.** A typo fix doesn't need a 5-phase audit, XML tags, examples, or a role line. Match prompt complexity to actual job complexity — most of Step 3's techniques apply only when the task calls for them.
- **Don't shout.** No "CRITICAL", "IMPORTANT!!", or MUST-in-caps scattered through the prompt — it causes overtriggering on modern models and dilutes the one rule that might actually be blocking.
- **Don't dump CLAUDE.md verbatim.** Quote only the rules that apply to this task, as plain constraints.
- **Don't substitute your judgment for the user's clear choices.** If they've decided something, encode it as-is. If they've left something open, ask or flag as `<TODO>`.
- **Don't generate placeholders for things you could verify yourself.** If you can grep the file path or read the relevant code, do it instead of writing `<file path>`.
- **Don't reference platform-specific tools or UI.** The output must be tool-agnostic.
- **Don't pre-write the receiver's reply.** Phrases like "the agent will respond with X" or "you should answer Y" leak frame; just specify what the receiver should produce.
