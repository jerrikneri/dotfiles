# .ai-agents/ -- Shared AI Coding Tool Configuration

Model-agnostic protocols and instructions for AI coding tools (Claude Code, Open Code, Cursor, etc.).

## Structure

```
.ai-agents/
  .agentsignore                      # Ignore patterns merged into target .gitignore by sync-ai-md
  rules/                             # Global always-on protocols
    session-management.md            # Branch-based session docs, [resume], [compact], [log]
    agent-meta-protocol.md           # Core behaviors: document findings, self-improve, fact-check
    permissions.md                   # Canonical permission policy (read-only = allow, writes = ask)
  skills/                            # Task-specific protocols (invoked per-task)
    pre-flight.md                    # Assess bug before starting (clarity, scope, risk)
    bug-triage.md                    # Full investigate-fix-test-document protocol
    hontoni.md                       # Post-fix self-critique scoring (6 dimensions)
```

## How tools pick this up

**Claude Code**: `~/.claude/CLAUDE.md` references `rules/session-management.md`. Skills are loaded when projects symlink the `.ai-agents/` directory.

**Open Code**: `opencode.json` `instructions[]` array auto-loads skill files. Commands in `.config/opencode/commands/` provide `/pre-flight`, `/critique`, `/second-opinion` slash commands.

**Any tool**: `AGENTS.md` at project root documents the skills and links to them. Any AI tool that reads a project's root markdown will find them.

## Syncing into projects

```bash
# Symlinks AGENTS.md, .ai-agents/skills/, .ai-agents/rules/
# and merges .agentsignore patterns into the target's .gitignore.
sync-ai-md /path/to/project

# Or from within the project:
sync-ai-md .
```

The `sync-ai-md` function is defined in `$DOTFILES/.functions/.ai.sh` and uses `$DOTFILES` env var (set in `.config/zsh/.zshenv`).

## Adding new skills

Create a `.md` file in `skills/`. Conventions:
- Self-contained (works without any other file)
- Portable (no tool-specific syntax, no YAML frontmatter)
- Header block: include a `>` quoted block explaining what it is and how to use it
- Language-agnostic where possible

## Adding new rules

Create a `.md` file in `rules/`. These are always-on global protocols (session management, permissions, behavioral directives) rather than task-specific skills.
