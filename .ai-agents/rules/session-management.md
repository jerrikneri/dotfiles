# Session Management Protocol

> Branch-based session documentation system for AI coding agents.
> Tool-agnostic: works with any AI coding tool that loads this file (Claude Code, Open Code, Cursor, etc.).
> Trigger words: `[resume]`, `[document]`, `[log]`, `[record-session]`, `[ticket]`, `[ready]`

---

## Branch-Based Session Management

At session start:
1. Detect git branch: `git branch --show-current`
2. Sanitize name for filesystem: `tests/1846-foo` -> `tests-1846-foo`
3. Check for `workspace/context/{branch-name}/YYYY-MM-DD-CURRENT.md` (today's date)
4. If directory doesn't exist: Create `workspace/context/{branch-name}/` and `archive/` subdirectory
5. Load TODAY's file + LAST session's dated file (for continuity, if different day)
6. If today's file doesn't exist: Create new `YYYY-MM-DD-CURRENT.md` for this branch

During session -- update the context file automatically at these points:
- **After completing any multi-step task** (created files, modified config, built a feature)
- **After making a decision** that affects architecture, tooling, or workflow
- **After discovering something non-obvious** (a gotcha, a workaround, a pattern)
- **Before responding to the user** when any of the above apply -- don't wait to be asked

Do NOT document:
- Trivial single-file edits with obvious intent
- Read-only exploration that didn't lead to a conclusion
- Things already captured in git diff (code shows what changed)

Rules:
- Never delete from current files -- they accumulate until archived
- Only load today + last session files (token efficient, ~500-1000 tokens)
- Switching branches automatically loads different dated files (separate context per branch)
- Documentation must be succinct and to the point -- no fluff
- Focus on "what changed" and "why" -- the code shows "how"

## Task Tracking

- Use checkbox markdown files for complex tasks: `workspace/context/{branch}/tasks.md`
- Format: `[ ]` unchecked, `[x]` completed
- Reference with @workspace/context/{branch}/tasks.md only when needed
- If `tasks.md` is missing, initialize from `workspace/context/_templates/tasks.md`
- Keep a small `Command Sync` block in `tasks.md` for `/resume`, `/log`, `/document`, `/record-session`, `/learn`, `/learn-cadence`, and `/learn-from-mistake`

## Archiving (Do This Proactively)

- When branch context grows large: Move old `YYYY-MM-DD-CURRENT.md` files to `workspace/context/{branch}/archive/YYYY-MM/`
- Keep only recent dated files in branch root (today + last few sessions)
- Archive folder should be excluded from AI tool searches for token efficiency

## Documentation Protocol

1. Summarize key decisions, code changes, and next steps in today's `YYYY-MM-DD-CURRENT.md`
2. Archive the file to `workspace/context/{branch}/archive/YYYY-MM/`
3. Remind user to start a new session
4. New session should read archived summary if continuing work

## Format Rules

- Always date documentation blocks (YYYY-MM-DD)
- Keep summaries under 100 lines
- Focus on "what changed" and "why" -- not "how" (code shows how)
- No emojis in logs
- Helper scripts: `workspace/context/{branch}/scripts/`
- Doc blocks for classes/methods ok. Prefer self-documenting code. Comment only non-obvious "why"

## Trigger: [resume]

When user sends `[resume]` (or invokes `/resume` slash command):
1. Load today's `YYYY-MM-DD-CURRENT.md` + last session's dated file (if exists)
2. Summarize what was accomplished and current state
3. Identify next steps from documentation
4. Ready to continue seamlessly from previous session(s)
5. When modifying dated current.md file, if removing things, move changes to archive file so they're not lost

## Trigger: [document]

When user sends `[document]` (or invokes `/document` slash command):
1. Dump full session context to today's `YYYY-MM-DD-CURRENT.md`
2. Include: Tasks completed, decisions made, code changes, blockers, next steps
3. Format for easy pickup in new session
4. After saving, remind user to start fresh session with more token bandwidth

## Trigger: [log]

When user sends a prompt marked with `[log]` (or invokes `/log` slash command):
- Save the prompt content to `workspace/context/{branch}/prompts/YYYY-MM-DD.md`

## Trigger: [record-session]

When user sends `[record-session]` (or invokes `/record-session` slash command):
1. Detect current branch and sanitize branch name for filesystem
2. Create `workspace/context/{branch}/records/` if missing
3. Write `workspace/context/{branch}/records/YYYY-MM-DD-HHMM-record-session.md`
4. Include full verbatim transcript of the current session (user and assistant turns)
5. Include changed-files context from `git status --short` and `git diff --name-only`
6. Include metadata: timestamp, branch, repository root, and trigger source
7. Include any slash command arguments in a short `Notes` section

Cross-agent command text (copy/paste template):

```markdown
Execute the [record-session] protocol from the session management rule.

Read the full protocol from `.ai-agents/rules/session-management.md` (or `~/code/dotfiles/.ai-agents/rules/session-management.md` if project-level doesn't exist).

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Create `workspace/context/{branch}/records/` if missing
4. Write `workspace/context/{branch}/records/YYYY-MM-DD-HHMM-record-session.md`
5. Include the full verbatim conversation transcript (user and assistant turns) from this session
6. Include changed files summary from `git status --short` and `git diff --name-only`
7. Include a short metadata block: date/time, branch, repo root, and trigger source
8. If called with arguments, include them as a "Notes" section

$ARGUMENTS
```

## Trigger: [ticket]

When user includes `[ticket]` in a message (without relying on slash commands):
1. Remove only the `[ticket]` marker from the captured content
2. Detect current branch: `git branch --show-current`
3. Resolve `ticket_name` and optional `branch_name` from the message
   - Prefer explicit labels: `ticket name: ...`, `branch name: ...`
   - If no explicit `ticket_name`, use Jira-style ID if present (`[A-Z][A-Z0-9]+-[0-9]+`)
4. If `ticket_name` is still missing, ask exactly one follow-up for ticket name
5. Resolve `branch_name` by priority:
   - explicit branch name
   - derived from `ticket_name` slug (lowercase, spaces/underscores to `-`, remove non `[a-z0-9-]`, collapse repeated dashes, trim edge dashes)
6. Ensure git branch exists and switch to it:
   - if local branch exists: checkout `{branch_name}`
   - otherwise: create and checkout `{branch_name}`
7. Ensure `workspace/context/{branch_name}/` exists
8. If details content is empty after cleanup, ask exactly one follow-up for ticket details
9. Write deterministic file `workspace/context/{branch_name}/ticket-details.md` with:
   - ticket_name
   - branch_name
   - captured_at_local and captured_at_iso
   - source: `[ticket]`
   - raw input
   - cleaned details body

## Trigger: [ready]

When user includes `[ready]` in a message (without relying on slash commands):
1. Remove only the `[ready]` marker from the captured content
2. Detect current branch: `git branch --show-current`
3. Sanitize branch name for filesystem paths (replace `/` with `-`) when resolving `workspace/context/{branch}/...`
4. Execute the same protocol as `/ready`
5. Use `workspace/context/{branch}/ticket-details.md` as the ONLY acceptance-criteria source
6. If ticket file or criteria are missing/incomplete, ask exactly one targeted follow-up, then continue the `/ready` protocol
7. If criteria remain incomplete after that follow-up, fail the Requirements Gate
8. Run requirements traceability, tests/manual verification, in-process hontoni review, and second-opinion subagent review
9. Return `READY` only if all gates pass (including both review composites `> 80` and no unresolved major/critical flaws); otherwise return `NOT READY` with blockers and next actions
