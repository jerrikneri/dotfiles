---
description: "Resume from previous session context"
---

Execute the [resume] protocol from the session management skill.

Read the full protocol from `.ai-agents/rules/session-management.md` (or `~/code/dotfiles/.ai-agents/rules/session-management.md` if project-level doesn't exist).

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Load today's `workspace/context/{branch}/YYYY-MM-DD-CURRENT.md` + last session's dated file
4. Summarize what was accomplished and current state
5. Identify next steps from documentation
6. Ready to continue seamlessly

$ARGUMENTS
