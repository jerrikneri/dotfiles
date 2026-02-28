# AI agent config sync
sync-ai-md() {
  local target_dir="${1:-.}"

  if [ -z "$DOTFILES" ]; then
    echo "Error: DOTFILES environment variable not set" >&2
    return 1
  fi

  target_dir="$(cd "$target_dir" 2>/dev/null && pwd)" || {
    echo "Error: directory '$1' does not exist" >&2
    return 1
  }

  if [ "$target_dir" = "$DOTFILES" ]; then
    echo "Error: target is the dotfiles repo itself" >&2
    return 1
  fi

  # Helper: prompt before overwriting a non-symlink target
  _sync_link() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ -L "$dest" ]; then
      ln -sfn "$src" "$dest"
      echo "  updated $label (symlink refreshed)"
    elif [ -e "$dest" ]; then
      printf "  %s already exists and is not a symlink. Overwrite? [y/N] " "$label"
      read -r reply
      if [[ "$reply" =~ ^[Yy]$ ]]; then
        rm -rf "$dest"
        ln -sfn "$src" "$dest"
        echo "  replaced $label"
      else
        echo "  skipped $label"
      fi
    else
      ln -sfn "$src" "$dest"
      echo "  linked $label"
    fi
  }

  echo "Syncing AI config from $DOTFILES -> $target_dir"

  # AGENTS.md
  _sync_link "$DOTFILES/AGENTS.md" "$target_dir/AGENTS.md" "AGENTS.md"

  # .ai-agents/skills/
  mkdir -p "$target_dir/.ai-agents"
  _sync_link "$DOTFILES/.ai-agents/skills" "$target_dir/.ai-agents/skills" ".ai-agents/skills"

  # .ai-agents/rules/
  _sync_link "$DOTFILES/.ai-agents/rules" "$target_dir/.ai-agents/rules" ".ai-agents/rules"

  # Merge .agentsignore patterns into target's .gitignore
  local agentsignore="$DOTFILES/.ai-agents/.agentsignore"
  local gitignore="$target_dir/.gitignore"

  if [ -f "$agentsignore" ]; then
    if [ -f "$gitignore" ]; then
      local added=0
      while IFS= read -r pattern || [ -n "$pattern" ]; do
        # Skip comments and blank lines
        [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
        if ! grep -qFx "$pattern" "$gitignore"; then
          echo "$pattern" >> "$gitignore"
          added=$((added + 1))
        fi
      done < "$agentsignore"
      if [ "$added" -gt 0 ]; then
        echo "  appended $added pattern(s) to .gitignore"
      else
        echo "  .gitignore already has all patterns"
      fi
    else
      echo "  no .gitignore found, skipping ignore merge"
    fi
  fi

  echo "Done."
  unset -f _sync_link
}
