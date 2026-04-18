# AGENTS.md - Dotfiles Repository Guidelines

This document provides guidelines for AI coding agents working with this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for Unix-like systems (macOS, Arch Linux, Ubuntu, NixOS).
Primary languages: Shell scripts (bash/zsh), with configuration files for various tools.
Main directories: `.aliases`, `.config`, `.functions`, `.scripts`, `bin`, `nix`, OS-specific dirs.

## Quick Operating Rules

- Follow the short rules in this section first for fast startup context.
- Use detailed protocols in `.ai-agents/skills/*.md` and `.ai-agents/rules/*.md` for execution details.
- Treat memory as two-tier: concise reusable bullets in `AGENTS.md`, deeper process detail in skills/rules files.
- Prefer incremental updates over full rescans when maintaining memory.
- Keep learned-memory sections compact; merge/prune before adding more bullets.
- If guidance is personal-only or experimental, store it in `AGENTS.local.md` before promoting to `AGENTS.md`.
- Follow command safety gates in `.ai-agents/rules/agent-meta-protocol.md`; ask before state-changing operations and include rollback guidance when making changes.
- End each user-facing response with a brief self-check line: `Confidence: X/10` and `Would you like me to pressure-test this answer?`.
- If confidence is below `8/10`, include the top uncertainty and the fastest verification step.

## Response Reliability Guardrails

- Never fabricate facts, metrics, citations, benchmarks, dates, command output, or test results.
- For numeric claims (counts, percentages, frequencies, timings), provide a verifiable source or state `Unknown`.
- Label uncertain claims as `Unverified` and avoid presenting them as facts.
- Distinguish `Observed` (direct evidence), `Inferred` (reasoned from evidence), and `Speculative` (hypothesis needing validation).
- Prefer `I don't know yet` over guessing, and include the fastest concrete verification step.
- If evidence is missing or conflicting, ask one targeted question or run a read-only verification command before concluding.

## Security Baseline

- Never commit secrets, credentials, or `.env` files; stop and notify if sensitive files are staged.
- Prefer least privilege for commands and file permissions; avoid broad permission changes.
- Treat destructive commands as high risk; run them only with explicit user instruction and a rollback plan.
- Validate external input and quote shell variables to prevent injection and accidental globbing.
- Keep security checks in automation (pre-commit and CI), not only manual review.

## Build/Test Commands

### Installation
```bash
# Main installation (interactive)
./install.sh

# Check syntax for shell scripts
shellcheck <script.sh>
shellcheck -s bash <script.sh>  # for bash scripts
shellcheck -s sh <script.sh>    # for POSIX sh scripts

# Test a specific function or alias
source <file> && <function_name>
```

### Running Tests
```bash
# No formal test suite exists yet
# Test scripts manually by sourcing and executing
source .scripts/utils.sh && _debug_echo "test"

# Test installation scripts in dry-run mode (when available)
DRYRUN=1 ./install.sh
```

## Code Style Guidelines

### Shell Script Standards

1. **Shebang Lines**
   - Use `#!/usr/bin/env bash` for bash scripts
   - Use `#!/usr/bin/env zsh` for zsh scripts
   - Always include shebang for executable scripts

2. **Error Handling**
   - Start scripts with `set -euo pipefail` for robust error handling
   - Use `set -e` to exit on error
   - Use `set -u` to error on undefined variables
   - Use `set -o pipefail` to propagate pipe failures

3. **File Organization**
   - Place aliases in `.aliases/<category>.sh`
   - Place functions in `.functions/<category>.sh`
   - Place installation scripts in `.scripts/`
   - Place executables in `bin/`

4. **Naming Conventions**
   - Files: lowercase with underscores (e.g., `install_arch.sh`)
   - Hidden files start with dot (e.g., `.essential.sh`)
   - Functions: lowercase with underscores or short abbreviations
   - Variables: UPPERCASE for exports, lowercase for local vars
   - Environment vars: UPPERCASE (e.g., `DOTFILES`, `REPOS`)

5. **Function Style**
   ```bash
   # Good function style
   function_name() {
     local var_name="$1"
     if [ -z "$var_name" ]; then
       echo "Error: parameter required" >&2
       return 1
     fi
     # Function body
   }
   ```

6. **Conditional Statements**
   ```bash
   # Preferred style
   if [ -f "$file" ]; then
     # action
   fi
   
   # For string comparisons
   if [[ "$var" == "value" ]]; then
     # action
   fi
   ```

7. **Variable Usage**
   - Always quote variables: `"$var"` not `$var`
   - Use `${var}` when concatenating
   - Check if variables exist before use
   - Prefer `[ -z "$var" ]` to check empty strings

8. **Comments and Documentation**
   - Add comments for non-obvious logic
   - Document function parameters and return values
   - Use descriptive variable names

### Environment Variables

Key environment variables (defined in `.config/zsh/.zshenv`):
- `$DOTFILES`: Root dotfiles directory
- `$REPOS`: Code repositories directory
- `$SCRIPTS`: Scripts directory
- `$ALIASES`: Aliases directory
- `$FUNCTIONS`: Functions directory
- `$XDG_CONFIG_HOME`: Config directory (~/.config)

### File Permissions

- Executable scripts: `chmod +x script.sh`
- Configuration files: `chmod 644 file`
- Keep `.env` out of git (see .gitignore)

### Git Workflow

1. **Branches**: Use descriptive branch names
2. **Commits**: Clear, concise commit messages
3. **Sensitive Data**: Never commit `.env` files
4. **Testing**: Test changes on target OS before committing

### OS-Specific Code

Use OS detection pattern from `.scripts/detect_os.sh`:
```bash
case "$OSTYPE" in
  darwin*)  # macOS specific code ;;
  linux*)   # Linux specific code ;;
esac
```

### Error Messages

- Send errors to stderr: `echo "Error: message" >&2`
- Provide helpful error messages
- Exit with non-zero status on error

### Dependencies

- Document required tools in comments
- Check for dependencies before use:
  ```bash
  command -v tool >/dev/null 2>&1 || { echo "tool required" >&2; exit 1; }
  ```

### Debug Mode

Support debug output using:
```bash
source .scripts/utils.sh
_debug_echo "Debug message"
# Enable with: export SHELL_DEBUG=true
```

## Common Patterns

1. **Sourcing files**: Use absolute paths with environment variables
2. **Directory creation**: Always use `mkdir -p`
3. **File backup**: `cp file file.old` before modifications
4. **Symlinks**: Prefer symlinks for dotfile management

## AI Agent Skills

This repo contains reusable AI agent skill files in `.ai-agents/skills/`. These are model-agnostic markdown protocols that work with any AI coding tool (Claude Code, Open Code, Cursor, etc.).

### Available Skills

| Skill | Purpose | When |
|-------|---------|------|
| `.ai-agents/skills/pre-flight.md` | Assess bug clarity, scope, risk before starting | Before any fix |
| `.ai-agents/skills/bug-triage.md` | Full protocol for investigating and fixing production errors | During the fix |
| `.ai-agents/skills/continual-improvement.md` | Incremental learning loop for durable preferences and workspace facts | After meaningful work or via `/learn` |
| `.ai-agents/skills/hontoni.md` | Self-critique scoring framework (6 dimensions, composite score) | After completing fix |
| `.ai-agents/rules/session-management.md` | Branch-based session context, resume, compact, archiving | Every session |
| `.ai-agents/rules/agent-meta-protocol.md` | Document findings, self-improve config, recognize repetition, fact-check, second opinion, auto-run tests | Always on |

### OpenCode Integration

Skills are auto-loaded via `opencode.json` `instructions` array. Slash commands available:
- `/pre-flight <error description>` -- run pre-flight assessment
- `/critique` -- run hontoni scoring on completed work
- `/second-opinion` -- harsher re-review assuming first critique was too lenient
- `/learn` -- run continual improvement memory sync
- `/learn-from-mistake <note>` -- run fast mistake-to-memory loop with supplied context
- `/learn-cadence` -- evaluate cadence gates before running memory sync
- `/resume` -- load branch context and resume from previous session
- `/document` -- dump session context for fresh restart
- `/log <note>` -- save a prompt or note to session log
- `/perm-allow <tool> <pattern>` -- persist a granular allow rule
- `/perm-deny <tool> <pattern>` -- persist a granular deny rule
- `/perm-ask <tool> <pattern>` -- persist a granular ask rule

### Continual learning memory sections

To keep memory updates safe and reusable, learned content in `AGENTS.md` should be maintained only in these managed sections:

- Tier 1: concise, durable bullets in learned sections below
- Tier 2: detailed implementation protocols in `.ai-agents/skills/*.md` and `.ai-agents/rules/*.md`

## Learned User Preferences

- Prefer concise progress updates with concrete file references.
- Prefer bash-native solutions over Python for simple local automation tasks.
- Avoid hardcoded file lists; discover files dynamically from `workspace/context/`.
- Keep operational helper scripts in `.scripts/` rather than under `workspace/`.

## Learned Workspace Facts

- This repository stores reusable agent skills under `.ai-agents/skills/` and always-on rules under `.ai-agents/rules/`.
- Learning index state is stored at `workspace/context/_meta/learning-index.json`.
- Learning cadence state is stored at `workspace/context/_meta/learning-cadence.json`.
- Learning index refresh helper script is `.scripts/update_learning_index.sh`.

## Learned Agent Workflow Improvements

- Use incremental context processing (new/changed files only) when updating learned memory.
- Use `/learn-from-mistake <note>` for fast single-incident memory capture.
- Use `/learn-cadence` before `/learn` for cadence-gated memory sync.
- Keep learned-memory sections compact by merging/pruning before adding bullets.
- Check for existing test files before creating new ones; add tests to existing files to maintain cohesion.
- Run tests automatically after code changes; never present work as complete with failing tests.

Command files: `.config/opencode/commands/`
Config: `.config/opencode/opencode.json`
Full extensibility reference: `.config/opencode/OPENCODE-EXTENSIBILITY.md`

### Using skills in projects

**Option 1 -- Symlink the skills directory into a project:**
```bash
ln -s ~/code/dotfiles/.ai-agents/skills /path/to/project/.ai-agents/skills
```
Single source of truth. Updates to dotfiles propagate automatically.

**Option 2 -- Copy skills into a project:**
```bash
mkdir -p /path/to/project/.ai-agents/skills
cp ~/code/dotfiles/.ai-agents/skills/*.md /path/to/project/.ai-agents/skills/
```
Use when the project needs its own copy (e.g., project-specific examples added).

**Option 3 -- Reference inline in a project's AGENTS.md:**
Paste the concise checklist version directly into the project's AGENTS.md and point to the skills directory for depth. See the Trial Partners portal's AGENTS.md for an example of this pattern.

### Adding new skills

Create a new `.md` file in `.ai-agents/skills/`. Follow these conventions:
- Self-contained: the file must work without any other file
- Portable: no tool-specific syntax (no `@path` imports, no YAML frontmatter)
- Header block: include a `>` quoted block explaining what it is and how to use it
- Language-agnostic where possible (examples in multiple languages, or generic pseudocode)

### Personal project overlays

For project-specific preferences that shouldn't be committed to a shared repo, create `AGENTS.local.md` at the project root (ensure it's in that project's `.gitignore`). This works as a personal overlay on top of the committed `AGENTS.md`.

## Maintenance Notes

- Keep scripts modular and single-purpose
- Test on all supported platforms when possible
- Document any OS-specific behavior
- Update this file when adding new conventions
