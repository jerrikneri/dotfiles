# .ai-agents/ -- Shared AI Coding Tool Configuration

Model-agnostic protocols and instructions for AI coding tools (Claude Code, Open Code, Cursor, etc.).

## Structure

```
.ai-agents/
  .agentsignore                      # Ignore patterns merged into target .gitignore by sync-ai-md
  rules/                             # Global always-on protocols
    session-management/SKILL.md      # Branch-based session docs, [resume], [compact], [log]
    agent-meta-protocol/SKILL.md     # Core behaviors: document findings, self-improve, fact-check
    permissions/SKILL.md             # Canonical permission policy (read-only = allow, writes = ask)
  skills/                            # Task-specific protocols (invoked per-task)
    pre-flight/SKILL.md              # Assess bug before starting (clarity, scope, risk)
    hontoni/SKILL.md                 # Post-fix self-critique scoring (6 dimensions)
    continual-improvement/SKILL.md   # Incremental learning loop
    teach-me/SKILL.md                # Interactive mentor protocol
    release-readiness/SKILL.md       # Pre-release validation
    spec-driven-development/SKILL.md # Spec-first development
    nix-validation/SKILL.md          # Nix build validation
  templates/                        # Reusable starter files (instantiate, never edit in place)
    tasks.md                        # Branch task checklist: source links, groups, Done-when criteria
```

## How tools pick this up

**Claude Code**: Skills auto-discovered from `~/.claude/skills/<name>/SKILL.md`. Use `sync-skills claude` to symlink them (rules synced as skills too, except `permissions`).

**Open Code**: Skills auto-discovered from `~/.config/opencode/skills/<name>/SKILL.md`; rules loaded via `opencode.json` `instructions[]` array. Use `sync-skills opencode` to symlink skills. Slash commands in `.config/opencode/commands/` provide `/pre-flight`, `/critique`, `/second-opinion`.

**Any tool**: `AGENTS.md` at project root documents the skills and links to them. Any AI tool that reads a project's root markdown will find them.

## Syncing

```bash
# Symlink skills (+ rules for agents without a rules concept) into agent global dirs.
# Interactive multi-select (fzf) or: sync-skills claude opencode / --all / --list
sync-skills

# Symlink AGENTS.md + .ai-agents/ into a target project, merge .agentsignore.
sync-ai-md /path/to/project
```

Both functions are defined in `$DOTFILES/.functions/.ai.sh` and use `$DOTFILES` env var (set in `.config/zsh/.zshenv`).

## Adding new skills

Create a directory `skills/<name>/SKILL.md`. Conventions:
- Self-contained (works without any other file)
- Portable (no tool-specific syntax, no YAML frontmatter)
- Header block: include a `>` quoted block explaining what it is and how to use it
- Language-agnostic where possible

## Adding new rules

Create a directory `rules/<name>/SKILL.md`. These are always-on global protocols (session management, permissions, behavioral directives) rather than task-specific skills. Note: the `permissions` rule is skipped when syncing rules-as-skills (agent-specific config).

## Templates

Reusable starter files, committed here so every project gets them via `sync-ai-md`. Instantiate into the project (e.g. `templates/tasks.md` -> `workspace/context/{branch}/tasks.md`), never edit in place. Conventions: `{placeholder}` markers, a `>` header block explaining usage, and self-documenting structure that needs no external reference.
