# OpenCode Extensibility Reference

> Comprehensive reference for OpenCode CLI's extension points.
> Researched 2026-02-27. Sources: opencode.ai/docs, community guides, plugin repos.

## Doc Validity Checks

Re-validate this document periodically to avoid stale guidance:

- Confirm instruction precedence and AGENTS/CLAUDE fallback behavior in current docs.
- Confirm command file frontmatter keys and `$ARGUMENTS` behavior still match runtime.
- Confirm permission key names (`read`, `edit`, `bash`, `task`, `skill`, etc.) still exist.
- Confirm skill discovery paths and naming constraints are unchanged.
- Spot-check at least one example snippet against live behavior in a throwaway repo.

---

## 1. Instruction Loading Order

OpenCode merges instructions from multiple sources (highest priority last):

| Priority | Source | Location |
|----------|--------|----------|
| 1 | Remote config | `.well-known/opencode` |
| 2 | Global config | `~/.config/opencode/opencode.json` |
| 3 | Custom config | `OPENCODE_CONFIG` env var |
| 4 | Project config | `./opencode.json` |
| 5 | `.opencode` directories | `.opencode/` in project |
| 6 | Inline config | `OPENCODE_CONFIG_CONTENT` env var |

### AGENTS.md precedence

1. Project `AGENTS.md` (highest)
2. Global `~/.config/opencode/AGENTS.md`
3. Project `CLAUDE.md` (backward compat)
4. Global `~/.claude/CLAUDE.md`

### Loading additional instruction files

Use `instructions` array in `opencode.json` to load extra files alongside AGENTS.md:

```json
{
  "instructions": [
    "docs/guidelines.md",
    ".cursor/rules/*.md",
    "https://example.com/rules.md"
  ]
}
```

Supports: glob patterns, local paths, remote URLs (5s timeout).

---

## 2. Skills

### Discovery locations (checked in order)

- `.opencode/skills/<name>/SKILL.md` (project)
- `~/.config/opencode/skills/<name>/SKILL.md` (global)
- `.claude/skills/*/SKILL.md` (Claude compat, project)
- `~/.claude/skills/*/SKILL.md` (Claude compat, global)
- `.agents/skills/*/SKILL.md` (generic, project)
- `~/.agents/skills/*/SKILL.md` (generic, global)

### SKILL.md format

```markdown
---
name: "skill-name"          # Required: 1-64 chars, lowercase alphanumeric + hyphens
description: "What it does" # Required: 1-1024 chars
license: "MIT"              # Optional
compatibility: "opencode"   # Optional
metadata: {}                # Optional
---

Skill instructions here...
```

Name validation: `^[a-z0-9]+(-[a-z0-9]+)*$`

### Permissions

In `opencode.json`:
```json
{
  "permission": {
    "skill": "ask"          // "allow" | "ask" | "deny"
  }
}
```

Supports wildcards: `"internal-*": "deny"`

---

## 3. Custom Commands (Slash Commands)

### Locations

- `.opencode/commands/<name>.md` (project)
- `~/.config/opencode/commands/<name>.md` (global)

### Format

```markdown
---
description: "Short description shown in TUI"
agent: build                                      # Optional: which agent runs it
model: "anthropic/claude-3-5-sonnet-20241022"     # Optional: override model
---

Command instructions/template here.

Use $ARGUMENTS for all args, or $1, $2 for positional.
```

### Dynamic content injection

Embed command output:
```markdown
Current branch: !`git branch --show-current`
Current status: !`git status --short`
```

Embed file content:
```markdown
Review this file: @src/components/Button.tsx
```

### Configuration alternative (opencode.json)

```json
{
  "command": {
    "test": {
      "template": "Run full test suite with coverage...",
      "description": "Run tests",
      "agent": "build"
    }
  }
}
```

Custom commands can override built-ins (`/init`, `/undo`, `/redo`, `/share`, `/help`).

---

## 4. Agents

### Types

- **Primary agents**: Direct interaction (Build, Plan)
- **Subagents**: Invoked by primary agents or `@mention` (General, Explore)

### Built-in agents

| Agent | Type | Access |
|-------|------|--------|
| Build | Primary | Full tool access |
| Plan | Primary | Read-only by default |
| General | Subagent | Full tool access |
| Explore | Subagent | Read-only |

### Defining custom agents

**Via markdown** (`.opencode/agents/<name>.md` or `~/.config/opencode/agents/<name>.md`):

```markdown
---
description: "Purpose of this agent"
mode: primary|subagent
model: "anthropic/claude-opus-4-6"
temperature: 0.7
max_steps: 10
tools:
  read: true
  edit: false
  bash: true
permission:
  edit: ask
  bash: allow
hidden: false
---

Agent system prompt and instructions...
```

**Via opencode.json:**

```json
{
  "agent": {
    "my-agent": {
      "description": "...",
      "mode": "subagent",
      "model": "...",
      "tools": {"read": true, "edit": false},
      "permission": {"bash": "allow"}
    }
  }
}
```

---

## 5. Hooks & Plugins (TypeScript)

### Locations

- `.opencode/plugin/` (project)
- `~/.config/opencode/plugin/` (global)

### Available hooks

| Hook | Trigger | Use case |
|------|---------|----------|
| `event` (`session.create`) | New session started | Initialize state |
| `event` (`session.destroy`) | Session ended | Cleanup |
| `event` (`chat.message`) | Message received | Context injection |
| `event` (`file.change`) | File modified | Auto-reload |
| `tool.execute.before` | Before tool runs | Modify/block tool calls |
| `tool.execute.after` | After tool completes | Post-processing |
| `experimental.chat.system.transform` | System prompt build | Inject custom context |
| `stop` | Agent tries to stop | Block until conditions met |
| Compaction hook | Context compressed | Preserve state |
| Message transform | Before LLM send | Modify messages |
| Custom tools | Agent requests | Plugin-provided tools |

### Plugin context object

```typescript
{
  client: Client,      // API to interact with OpenCode
  project: Project,    // Current project info
  directory: string,   // Working directory
  worktree: string,    // Git worktree root
  $: ShellAPI          // Execute shell commands
}
```

### Example: commit reminder hook

```typescript
hook('tool.execute.after', (context, tool) => {
  if (tool.name === 'edit') {
    sessionState.get(sessionId).hasChanges = true;
  }
});

hook('stop', (context) => {
  if (sessionState.get(sessionId).hasChanges) {
    throw new Error("Please commit changes first");
  }
});
```

### Example: branch-based context loading

```typescript
hook('event', async (context, event) => {
  if (event.type === 'session.create') {
    const branch = await context.$.git(['branch', '--show-current']);
    // Load branch-specific instructions
  }
});
```

---

## 6. Rules System

### Locations

- `.opencode/rules/` (project)
- `~/.config/opencode/rules/` (global)

### opencode-rules plugin (community)

Install:
```json
{
  "plugin": ["opencode-rules@latest"]
}
```

Supports conditional rule loading:
- **File patterns**: trigger rules based on file types in context
- **Keywords**: activate rules based on prompt terms
- **Tool availability**: apply rules only when certain MCP tools exist
- **Conditional logic**: combine multiple conditions

---

## 7. Variable Substitution (opencode.json)

- `{env:VARIABLE_NAME}` -- Environment variables
- `{file:path/to/file}` -- File contents (e.g., API keys)

---

## 8. Comparison: OpenCode vs Claude Code

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Instruction files | `AGENTS.md` + `instructions[]` array | `CLAUDE.md` + `@path` imports |
| Skills | `.opencode/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` |
| Commands | `.opencode/commands/*.md` | Skills with `user-invocable: true` |
| Agents | Markdown + JSON config | Task tool subagent types |
| Hooks | TypeScript plugins (powerful) | `.claude/hooks/` (shell-based) |
| Rules | `.opencode/rules/` + opencode-rules plugin | `.claude/rules/` with YAML frontmatter |
| Config | `opencode.json` (merged from multiple levels) | `.claude/settings.json` |
| Context loading | `instructions[]` in JSON, auto-merge | `@path` imports in CLAUDE.md |
| Backward compat | Reads CLAUDE.md, .claude/skills/ | N/A |

### Key advantage: `instructions[]`

OpenCode's `instructions` array in `opencode.json` solves the "skills files aren't auto-loaded" problem that Claude Code has. Add skill files there and they're always in context:

```json
{
  "instructions": [
  ]
}
```

Claude Code equivalent requires `@` imports in CLAUDE.md (tool-specific syntax).

---

## 9. Practical Setup for This Dotfiles Repo

### Global config (`~/.config/opencode/opencode.json`)

Add `instructions` array to auto-load skills:
```json
{
  "instructions": [
  ]
}
```

### Per-project config (`./opencode.json`)

Override or extend with project-specific skills:
```json
{
  "instructions": [
  ]
}
```

### Commands for slash command access

Create command files in `~/.config/opencode/commands/`:
- `pre-flight.md` -- `/pre-flight` before starting a fix
- `critique.md` -- `/critique` after completing a fix
- `second-opinion.md` -- `/second-opinion` for harsher re-review
