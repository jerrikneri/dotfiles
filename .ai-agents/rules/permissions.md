# Command Execution Permissions

> Canonical permission policy for AI coding tools. This documents the intent -- each tool enforces it in its own format (Claude Code via CLAUDE.md prose, Open Code via opencode.json permission block).

## Always Ask Before

- Writing or modifying files (except temporary workspace files)
- Running commands that modify system state (install, uninstall, git commits, etc.)
- Deleting or moving files
- Running commands with sudo
- Making configuration changes
- Installing packages or dependencies

## Safe to Execute Without Asking

- Read-only commands (ls, cat, grep, find, etc.)
- Checking status (git status, which, --version commands)
- Navigation (cd, pwd)
- Viewing logs or debugging output
- Running --help commands
- Testing/validation that doesn't modify state

## Guidelines

- Group related changes and ask once for the batch
- Explain what changes will be made and why
- Provide rollback instructions when making changes
- If unsure whether a command is safe, ask first

## Tool-Specific Enforcement

**Open Code** (`opencode.json`):
```json
{
  "permission": {
    "read": "allow",
    "edit": "ask",
    "grep": "allow",
    "list": "allow",
    "bash": {
      "*": "ask",
      "find *": "allow",
      "git diff": "allow",
      "git diff *": "allow",
      "git status": "allow",
      "git status *": "allow",
      "ls *": "allow"
    },
    "task": "allow",
    "external_directory": "ask"
  }
}
```

**Claude Code** (`CLAUDE.md`):
Permission section is included as LLM guidance in the global CLAUDE.md. Claude Code does not have structured permission enforcement beyond settings.json allowlists, so the prose serves as best-effort guidance.

## Persistent Permission Overrides (Managed by /perm-*)

Use OpenCode slash commands to persist granular rules:

- `/perm-allow <tool> <pattern>`
- `/perm-deny <tool> <pattern>`
- `/perm-ask <tool> <pattern>`

These commands update both `opencode.json` (enforced) and this table (documented intent).

| Tool | Pattern | Action |
|------|---------|--------|
| bash | git diff | allow |
| bash | git diff * | allow |
| bash | git status | allow |
| bash | git status * | allow |
