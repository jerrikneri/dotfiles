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

  # Helper: backup existing path to .bkup (or timestamped .bkup)
  _backup_path() {
    local target_path="$1"
    local backup="${target_path}.bkup"

    if [ -e "$backup" ] || [ -L "$backup" ]; then
      backup="${backup}.$(date +%Y%m%d%H%M%S)"
    fi

    /bin/cp -R "$target_path" "$backup"
    echo "$backup"
  }

  # Helper: replace destination with symlink, creating backup if needed
  _sync_link() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ -L "$dest" ]; then
      local current_target
      current_target="$(readlink "$dest")"
      if [ "$current_target" = "$src" ]; then
        echo "  $label already synced"
      else
        ln -sfn "$src" "$dest"
        echo "  updated $label (symlink refreshed)"
      fi
    elif [ -e "$dest" ]; then
      # Skip if existing destination content already matches source.
      if [ -f "$src" ] && [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo "  $label already synced"
        return
      fi
      if [ -d "$src" ] && [ -d "$dest" ] && diff -qr "$src" "$dest" >/dev/null 2>&1; then
        echo "  $label already synced"
        return
      fi

      local backup
      backup="$(_backup_path "$dest")"
      rm -rf "$dest"
      ln -sfn "$src" "$dest"
      echo "  replaced $label (backup: $backup)"
    else
      ln -sfn "$src" "$dest"
      echo "  linked $label"
    fi
  }

  # Helper: sync source file into managed append block in destination file.
  _sync_append_block() {
    local src_file="$1"
    local dest_file="$2"
    local label="$3"
    local begin_marker="<!-- BEGIN DOTFILES AGENTS SYNC -->"
    local end_marker="<!-- END DOTFILES AGENTS SYNC -->"

    if [ ! -f "$dest_file" ]; then
      cp "$src_file" "$dest_file"
      echo "  created $label"
      return
    fi

    local tmp_file trimmed_file merged_file
    tmp_file="$(mktemp)"
    trimmed_file="$(mktemp)"
    merged_file="$(mktemp)"

    awk -v begin="$begin_marker" -v end="$end_marker" '
      $0 == begin { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "$dest_file" >"$tmp_file"

    # Normalize trailing whitespace-only lines to keep sync idempotent.
    awk '
      { lines[NR] = $0 }
      END {
        last = NR
        while (last > 0 && lines[last] ~ /^[[:space:]]*$/) {
          last--
        }
        for (i = 1; i <= last; i++) {
          print lines[i]
        }
      }
    ' "$tmp_file" >"$trimmed_file"

    {
      cat "$trimmed_file"
      printf "\n%s\n" "$begin_marker"
      cat "$src_file"
      printf "\n%s\n" "$end_marker"
    } >"$merged_file"

    if cmp -s "$merged_file" "$dest_file"; then
      rm -f "$tmp_file" "$trimmed_file" "$merged_file"
      echo "  $label already synced"
      return
    fi

    local backup
    backup="$(_backup_path "$dest_file")"
    /bin/cp "$merged_file" "$dest_file"

    rm -f "$tmp_file" "$trimmed_file" "$merged_file"
    echo "  synced $label (appended managed block, backup: $backup)"
  }

  echo "Syncing AI config from $DOTFILES -> $target_dir"

  # AGENTS.md (append-managed sync instead of symlink overwrite)
  _sync_append_block "$DOTFILES/AGENTS.md" "$target_dir/AGENTS.md" "AGENTS.md"

  # .ai-agents/skills/
  mkdir -p "$target_dir/.ai-agents"
  _sync_link "$DOTFILES/.ai-agents/skills" "$target_dir/.ai-agents/skills" ".ai-agents/skills"

  # .ai-agents/rules/
  _sync_link "$DOTFILES/.ai-agents/rules" "$target_dir/.ai-agents/rules" ".ai-agents/rules"

  # Helper: merge .agentsignore patterns into a target ignore file
  _merge_ignore_patterns() {
    local target_ignore="$1"
    local ignore_type="$2"

    if [ -f "$target_ignore" ]; then
      local added=0
      while IFS= read -r pattern || [ -n "$pattern" ]; do
        # Skip comments and blank lines
        [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
        if ! grep -qFx "$pattern" "$target_ignore"; then
          echo "$pattern" >>"$target_ignore"
          added=$((added + 1))
        fi
      done <"$agentsignore"
      if [ "$added" -gt 0 ]; then
        echo "  appended $added pattern(s) to $ignore_type"
      else
        echo "  $ignore_type already has all patterns"
      fi
    else
      # Create the ignore file with patterns if it doesn't exist
      cp "$agentsignore" "$target_ignore"
      echo "  created $ignore_type with agent patterns"
    fi
  }

  # Merge .agentsignore patterns into all relevant ignore files
  local agentsignore="$DOTFILES/.ai-agents/.agentsignore"

  if [ -f "$agentsignore" ]; then
    # .gitignore
    _merge_ignore_patterns "$target_dir/.gitignore" ".gitignore"

    # .claudeignore
    _merge_ignore_patterns "$target_dir/.claudeignore" ".claudeignore"

    # .opencodeignore (if this is the correct name)
    _merge_ignore_patterns "$target_dir/.opencodeignore" ".opencodeignore"
  fi

  echo "Done."
  unset -f _backup_path _sync_link _sync_append_block _merge_ignore_patterns
}

# Evaluate continual-learning cadence gates.
# Returns 0 when eligible, 1 when deferred.
learn-cadence-status() {
  local cadence_file="${1:-workspace/context/_meta/learning-cadence.json}"
  local context_root="${2:-workspace/context}"
  local completed_turns_since_last_run="${3:--1}"

  if [ ! -f "$cadence_file" ]; then
    echo "Error: cadence state file not found: $cadence_file" >&2
    return 1
  fi

  # Helper: get one JSON scalar value with grep/sed.
  _json_scalar() {
    local key="$1"
    local file="$2"
    grep -E "\"${key}\"" "$file" | head -n 1 | sed -E "s/.*\"${key}\": (null|true|false|\"[^\"]+\"|[0-9]+).*/\1/"
  }

  # Helper: convert ISO UTC to epoch on macOS/Linux.
  _iso_to_epoch() {
    local iso="$1"
    if date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso" "+%s" >/dev/null 2>&1; then
      date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso" "+%s"
    else
      date -u -d "$iso" "+%s"
    fi
  }

  local now_epoch
  now_epoch="$(date -u +%s)"

  local last_run_raw trial_enabled trial_started_raw trial_duration
  local last_observed_mtime_ms
  last_run_raw="$(_json_scalar "lastRunAt" "$cadence_file")"
  trial_enabled="$(_json_scalar "enabled" "$cadence_file")"
  trial_started_raw="$(_json_scalar "startedAt" "$cadence_file")"
  trial_duration="$(_json_scalar "durationMinutes" "$cadence_file")"
  last_observed_mtime_ms="$(_json_scalar "lastObservedContextMtimeMs" "$cadence_file")"

  # Strip quotes from string fields.
  local last_run trial_started
  last_run="${last_run_raw//\"/}"
  trial_started="${trial_started_raw//\"/}"

  local latest_mtime=0
  local latest_mtime_ms=0
  local f m
  for f in "$context_root"/*/*.md; do
    [ -f "$f" ] || continue
    if m="$(stat -f %m "$f" 2>/dev/null)"; then
      :
    else
      m="$(stat -c %Y "$f")"
    fi
    if [ "$m" -gt "$latest_mtime" ]; then
      latest_mtime="$m"
    fi
  done
  latest_mtime_ms=$((latest_mtime * 1000))

  local default_min_turns=10
  local default_min_minutes=120
  local default_trial_min_turns=3
  local default_trial_min_minutes=15
  local default_trial_duration=1440

  local min_turns="${CONTINUAL_LEARNING_MIN_TURNS:-$default_min_turns}"
  local min_minutes="${CONTINUAL_LEARNING_MIN_MINUTES:-$default_min_minutes}"
  local trial_min_turns="${CONTINUAL_LEARNING_TRIAL_MIN_TURNS:-$default_trial_min_turns}"
  local trial_min_minutes="${CONTINUAL_LEARNING_TRIAL_MIN_MINUTES:-$default_trial_min_minutes}"
  local trial_duration_minutes="${CONTINUAL_LEARNING_TRIAL_DURATION_MINUTES:-$default_trial_duration}"

  local trial_active=false
  if [ "$trial_enabled" = "true" ] && [ -n "$trial_started" ]; then
    local trial_start_epoch
    trial_start_epoch="$(_iso_to_epoch "$trial_started")"
    local trial_age_minutes=$(((now_epoch - trial_start_epoch) / 60))
    if [ "$trial_age_minutes" -lt "$trial_duration_minutes" ]; then
      trial_active=true
    fi
  fi

  local effective_min_turns="$min_turns"
  local effective_min_minutes="$min_minutes"
  if [ "$trial_active" = true ]; then
    effective_min_turns="$trial_min_turns"
    effective_min_minutes="$trial_min_minutes"
  fi

  local turns_gate="unknown"
  if [ "$completed_turns_since_last_run" -ge 0 ] 2>/dev/null; then
    if [ "$completed_turns_since_last_run" -ge "$effective_min_turns" ]; then
      turns_gate="pass"
    else
      turns_gate="fail"
    fi
  fi

  local minutes_since_last=0
  local minutes_gate="fail"
  if [ "$last_run" = "null" ] || [ -z "$last_run" ]; then
    minutes_gate="bootstrap"
  else
    local last_run_epoch
    last_run_epoch="$(_iso_to_epoch "$last_run")"
    minutes_since_last=$(((now_epoch - last_run_epoch) / 60))
    if [ "$minutes_since_last" -ge "$effective_min_minutes" ]; then
      minutes_gate="pass"
    fi
  fi

  local mtime_gate="fail"
  if [ "$latest_mtime_ms" -gt "${last_observed_mtime_ms:-0}" ]; then
    mtime_gate="pass"
  fi

  local eligible=false
  local reason
  if [ "$minutes_gate" = "bootstrap" ]; then
    eligible=true
    reason="bootstrap-first-run"
  elif [ "$minutes_gate" = "pass" ] && [ "$mtime_gate" = "pass" ]; then
    if [ "$turns_gate" = "fail" ]; then
      eligible=false
      reason="turns-gate-not-met"
    else
      eligible=true
      if [ "$turns_gate" = "pass" ]; then
        reason="minutes-mtime-turns-gates-passed"
      else
        reason="minutes-and-mtime-gates-passed-turns-unknown"
      fi
    fi
  else
    reason="gates-not-met"
  fi

  printf 'eligible=%s\n' "$eligible"
  printf 'reason=%s\n' "$reason"
  printf 'trial_active=%s\n' "$trial_active"
  printf 'turns_gate=%s (required=%s actual=%s)\n' "$turns_gate" "$effective_min_turns" "$completed_turns_since_last_run"
  printf 'minutes_gate=%s (required=%s actual=%s)\n' "$minutes_gate" "$effective_min_minutes" "$minutes_since_last"
  printf 'mtime_gate=%s (latest=%s last_observed=%s)\n' "$mtime_gate" "$latest_mtime_ms" "${last_observed_mtime_ms:-0}"

  unset -f _json_scalar _iso_to_epoch

  if [ "$eligible" = true ]; then
    return 0
  fi
  return 1
}

llama-serve() {
  local model_name="$1"
  local context_length="${2:-16384}"
  local model_dir="${3:-$HOME/models}"

  if [ -z "$model_name" ]; then
    echo "Usage: llama-serve <model-name|model-file.gguf> [context-length] [model-dir]" >&2
    echo "Example: llama-serve llama-3.2-3b-q8 32768" >&2
    echo "Default context: 16384, Default dir: ~/models" >&2
    return 1
  fi

  local model_file="$model_name"

  if [[ "$model_file" != *.gguf ]]; then
    model_file="${model_file}.gguf"
  fi

  local model_path="${model_dir%/}/${model_file}"

  if [ ! -f "$model_path" ]; then
    echo "Error: model file not found: $model_path" >&2
    return 1
  fi

  echo "Serving model: $model_path with context length: $context_length"

  llama-server \
    -m "$model_path" \
    -ngl 999 \
    -c "$context_length" \
    --host 127.0.0.1 \
    --port 1337
}

# Function to serve MLX models using mlx_lm.server
# Usage: mlx-serve <model-folder-name> [context-length] [model-dir]
mlx-serve() {
  local model_name="$1"
  local context_length="${2:-16384}"
  local model_dir="${3:-$HOME/models}"

  if [ -z "$model_name" ]; then
    echo "Usage: mlx-serve <model-folder-name> [context-length] [model-dir]" >&2
    echo "Example: mlx-serve gpt-oss-20b 32768" >&2
    echo "Default context: 16384, Default dir: ~/models" >&2
    return 1
  fi

  local model_path="${model_dir%/}/${model_name}"

  # Check if model folder exists
  if [ ! -d "$model_path" ]; then
    echo "Error: model folder not found: $model_path" >&2
    return 1
  fi

  # Check if it's a valid MLX model folder (should contain config.json)
  if [ ! -f "$model_path/config.json" ]; then
    echo "Warning: config.json not found in $model_path - this may not be a valid MLX model" >&2
  fi

  echo "Serving MLX model from: $model_path with context length: $context_length"
  
  # Run mlx_lm server with the model path (brew-installed)
  mlx_lm server \
    --model "$model_path" \
    --host 127.0.0.1 \
    --port 1338 \
    --max-tokens "$context_length"
}
