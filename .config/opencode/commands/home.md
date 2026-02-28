---
description: "Update dotfiles AI agent markdown with learnings and improvements"
---

Update the dotfiles repository AI agent documentation with learnings and improvements from the current session. This command focuses on persisting valuable knowledge back to the main dotfiles repo for future sessions.

Steps:
1. Analyze current session context for valuable learnings
2. Identify which updates belong in:
   - `~/code/dotfiles/AGENTS.md` (main agent guidelines)
   - `~/code/dotfiles/.ai-agents/skills/*.md` (reusable skill protocols)
   - `~/code/dotfiles/.ai-agents/rules/*.md` (always-on behavioral rules)
3. Propose specific updates with clear rationale
4. Apply updates to appropriate files
5. Prepare a commit message summarizing the improvements
6. Show the diff and ask for approval to commit

Learning targets:
- New patterns discovered that should become standard practice
- Workflow improvements that apply across projects
- Tool configuration improvements
- Common error patterns and their solutions
- Reusable code snippets or command patterns

Quality gates:
- Must be generalizable beyond the current project
- Must improve future agent behavior
- Must not include project-specific or sensitive information
- Should follow existing format and style of target files

Managed sections in AGENTS.md:
- `## Learned User Preferences`
- `## Learned Workspace Facts`  
- `## Learned Agent Workflow Improvements`

Keep each section concise (max 10 bullets). Merge or prune before adding.

$ARGUMENTS