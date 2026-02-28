---
description: "Compact session context for fresh restart"
---

Execute the [compact] protocol from the session management skill.

Read the full protocol from `.ai-agents/rules/session-management.md` (or `~/code/dotfiles/.ai-agents/rules/session-management.md` if project-level doesn't exist).

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Dump full session context to today's `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md`
4. Include: Tasks completed, decisions made, code changes, blockers, next steps
5. Format for easy pickup in new session
6. After saving, remind user to start fresh session with more token bandwidth

$ARGUMENTS
