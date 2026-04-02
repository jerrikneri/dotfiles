---
description: "Record full session transcript and changed files"
---

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
