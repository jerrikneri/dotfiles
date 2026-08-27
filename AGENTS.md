# AGENTS.md - Dotfiles Repository Guidelines

This document provides guidelines for AI coding agents working with this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for Unix-like systems (macOS, Arch Linux, Ubuntu, NixOS).
Primary languages: Shell scripts (bash/zsh), with configuration files for various tools.
Main directories: `.aliases`, `.config`, `.functions`, `.scripts`, `bin`, `nix`, OS-specific dirs.

## Quick Operating Rules

- Follow the short rules in this section first for fast startup context.
- Use detailed protocols in `.ai-agents/skills/*/SKILL.md` and `.ai-agents/rules/*/SKILL.md` for execution details.
- Treat memory as two-tier: concise reusable bullets in `AGENTS.md`, deeper process detail in skills/rules files.
- Prefer incremental updates over full rescans when maintaining memory.
- Keep learned-memory sections compact; merge/prune before adding more bullets.
- If guidance is personal-only or experimental, store it in `AGENTS.local.md` before promoting to `AGENTS.md`.
- Follow command safety gates in `.ai-agents/rules/agent-meta-protocol/SKILL.md`; ask before state-changing operations and include rollback guidance when making changes.
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
# Bats test suite
bats tests/bash/ai_sync.bats

# Check a specific function by sourcing
source <file> && <function_name>
```

## Code Style Guidelines

Follow standard bash/zsh conventions (quote variables, `set -euo pipefail` for scripts, `local` for function vars, errors to stderr). Mimic neighboring files for framework choice and patterns.

### Repo-specific conventions

- **File organization**: aliases in `.aliases/<category>.sh`, functions in `.functions/<category>.sh`, install scripts in `.scripts/`, executables in `bin/`
- **Environment vars** (defined in `.config/zsh/.zshenv`): `$DOTFILES`, `$REPOS`, `$SCRIPTS`, `$ALIASES`, `$FUNCTIONS`, `$XDG_CONFIG_HOME`
- **OS detection** (from `.scripts/detect_os.sh`):
  ```bash
  case "$OSTYPE" in
    darwin*)  # macOS specific code ;;
    linux*)   # Linux specific code ;;
  esac
  ```
- **Debug output**: `source .scripts/utils.sh && _debug_echo "msg"` (enable: `export SHELL_DEBUG=true`)

## Common Patterns

1. **Sourcing files**: Use absolute paths with environment variables
2. **Directory creation**: Always use `mkdir -p`
3. **File backup**: `cp file file.old` before modifications
4. **Symlinks**: Prefer symlinks for dotfile management

## AI Agent Skills

This repo contains reusable AI agent skill files in `.ai-agents/skills/<name>/SKILL.md` and always-on rules in `.ai-agents/rules/<name>/SKILL.md`. These are model-agnostic markdown protocols that work with any AI coding tool (Claude Code, Open Code, Cursor, etc.).

Skills are auto-discovered by agents that read skill directories (Claude `~/.claude/skills/`, opencode `~/.config/opencode/skills/`). Use `sync-skills` to symlink them into place. For opencode, rules are loaded via the `opencode.json` `instructions` array; for agents without a rules concept, `sync-skills` symlinks rules as skills too.

### Continual learning memory sections

To keep memory updates safe and reusable, learned content in `AGENTS.md` should be maintained only in these managed sections:

- Tier 1: concise, durable bullets in learned sections below
- Tier 2: detailed implementation protocols in `.ai-agents/skills/*/SKILL.md` and `.ai-agents/rules/*/SKILL.md`

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

### Adding new skills

Create a new directory `.ai-agents/skills/<name>/SKILL.md`. Follow these conventions:
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
