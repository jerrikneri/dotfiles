---
description: "Save a prompt or note to session log"
---

Execute the [log] protocol from the session management skill.

Read the full protocol from `.ai-agents/rules/session-management.md` (or `~/code/dotfiles/.ai-agents/rules/session-management.md` if project-level doesn't exist).

Steps:
1. Detect current branch: !`git branch --show-current`
2. Sanitize branch name for filesystem (replace `/` with `-`)
3. Save the following content to `workspace/context/{branch}/prompts/YYYY-MM-DD.md`
4. Append if file already exists for today

Content to log:
$ARGUMENTS
