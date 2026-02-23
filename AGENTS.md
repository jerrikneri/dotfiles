# AGENTS.md - Dotfiles Repository Guidelines

This document provides guidelines for AI coding agents working with this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository for Unix-like systems (macOS, Arch Linux, Ubuntu, NixOS).
Primary languages: Shell scripts (bash/zsh), with configuration files for various tools.
Main directories: `.aliases`, `.config`, `.functions`, `.scripts`, `bin`, `nix`, OS-specific dirs.

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

## Maintenance Notes

- Keep scripts modular and single-purpose
- Test on all supported platforms when possible
- Document any OS-specific behavior
- Update this file when adding new conventions