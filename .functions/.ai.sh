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

  # Helper: ensure AGENTS.md contains a managed reference to AGENTS.local.md.
  _ensure_agents_local_reference() {
    local agents_file="$1"
    local begin_marker="<!-- BEGIN DOTFILES AGENTS LOCAL REF -->"
    local end_marker="<!-- END DOTFILES AGENTS LOCAL REF -->"
    local managed_line="If present, read and follow instructions in AGENTS.local.md from this repository root."

    local tmp_file trimmed_file merged_file
    tmp_file="$(mktemp)"
    trimmed_file="$(mktemp)"
    merged_file="$(mktemp)"

    awk -v begin="$begin_marker" -v end="$end_marker" '
      $0 == begin { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "$agents_file" >"$tmp_file"

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
      printf "%s\n" "$managed_line"
      printf "%s\n" "$end_marker"
    } >"$merged_file"

    if cmp -s "$merged_file" "$agents_file"; then
      rm -f "$tmp_file" "$trimmed_file" "$merged_file"
      echo "  AGENTS.md already references AGENTS.local.md"
      return
    fi

    local backup
    backup="$(_backup_path "$agents_file")"
    /bin/cp "$merged_file" "$agents_file"

    rm -f "$tmp_file" "$trimmed_file" "$merged_file"
    echo "  updated AGENTS.md (managed AGENTS.local.md reference, backup: $backup)"
  }

  echo "Syncing AI config from $DOTFILES -> $target_dir"

  local target_agents="$target_dir/AGENTS.md"
  local target_agents_local="$target_dir/AGENTS.local.md"

  if [ -L "$target_agents" ]; then
    echo "  AGENTS.md is a symlink; leaving as-is"
  elif [ ! -e "$target_agents" ]; then
    ln -sfn "$DOTFILES/AGENTS.md" "$target_agents"
    echo "  linked AGENTS.md"
  else
    _sync_link "$DOTFILES/AGENTS.md" "$target_agents_local" "AGENTS.local.md"
    _ensure_agents_local_reference "$target_agents"
  fi

  if [ -L "$target_dir/.ai-agents" ]; then
    echo "  .ai-agents is a symlink; leaving as-is"
  else
    # .ai-agents/skills/
    mkdir -p "$target_dir/.ai-agents"
    _sync_link "$DOTFILES/.ai-agents/skills" "$target_dir/.ai-agents/skills" ".ai-agents/skills"

    # .ai-agents/rules/
    _sync_link "$DOTFILES/.ai-agents/rules" "$target_dir/.ai-agents/rules" ".ai-agents/rules"
  fi

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
  unset -f _backup_path _sync_link _ensure_agents_local_reference _merge_ignore_patterns
}

# Sync skills (and optionally rules) from .ai-agents/ into AI agent global
# skill directories. Each .ai-agents/skills/<name>/ directory becomes a
# <agent_dir>/<name> symlink -> source dir (single source of truth).
#
# Agents without a native "rules" concept (e.g. Claude) also get rules
# synced as skills. Agents that handle rules elsewhere (e.g. opencode's
# instructions array) set sync_rules=false.
#
# Scalable: add an agent to the REGISTRY below (one "name|dir|sync_rules|desc" line).
#
# Usage:
#   sync-skills              # interactive multi-select (fzf, or toggle fallback)
#   sync-skills claude       # sync only the named agents (non-interactive)
#   sync-skills claude opencode
#   sync-skills --all        # sync every registered agent
#   sync-skills --list       # list registered agents
#   sync-skills --help
sync-skills() {
  if [ -z "$DOTFILES" ]; then
    echo "Error: DOTFILES environment variable not set" >&2
    return 1
  fi

  local skills_dir="$DOTFILES/.ai-agents/skills"
  local rules_dir="$DOTFILES/.ai-agents/rules"
  if [ ! -d "$skills_dir" ]; then
    echo "Error: skills directory not found: $skills_dir" >&2
    return 1
  fi

  # Agent registry. One agent per line: "name|target_dir|sync_rules|description".
  # sync_rules=true  -> also symlink .ai-agents/rules/<name> as skills
  # sync_rules=false -> rules handled elsewhere (e.g. opencode instructions array)
  # $HOME expands at assignment time. To add an agent, append a line here.
  local registry="claude|$HOME/.claude/skills|true|Claude Code (global, rules as skills)
opencode|$HOME/.config/opencode/skills|false|opencode (global, rules via instructions)"

  # Collect source dirs as "name|path" records (newline-delimited).
  local skill_dirs="" rule_dirs=""
  local d base
  for d in "$skills_dir"/*/; do
    [ -d "$d" ] || continue
    base="${d%/}"; base="${base##*/}"
    skill_dirs="$skill_dirs$base|${d%/}"$'\n'
  done
  if [ -z "$skill_dirs" ]; then
    echo "Error: no skill dirs found in $skills_dir" >&2
    return 1
  fi
  # Rules to skip when syncing rules-as-skills (agent-specific, not portable).
  # Space-separated list of rule directory names.
  local rule_skip="permissions"

  if [ -d "$rules_dir" ]; then
    local skip_match
    for d in "$rules_dir"/*/; do
      [ -d "$d" ] || continue
      base="${d%/}"; base="${base##*/}"
      skip_match=0
      local r
      for r in $rule_skip; do [ "$base" = "$r" ] && { skip_match=1; break; }; done
      [ "$skip_match" -eq 1 ] && continue
      rule_dirs="$rule_dirs$base|${d%/}"$'\n'
    done
  fi

  local selected_names=""

  if [ "$#" -gt 0 ]; then
    case "$1" in
      --help|-h)
        cat <<'EOF'
Usage: sync-skills [agent ...] | --all | --list | --help

Symlink every .ai-agents/skills/<name>/ dir into each agent's global
skill directory as <dir>/<name>. Agents with sync_rules=true also get
.ai-agents/rules/<name>/ symlinked as skills. Run with no args for an
interactive multi-select.
EOF
        return 0
        ;;
      --list|-l)
        echo "Registered skill-sync agents:"
        while IFS='|' read -r n d sr desc; do
          [ -z "$n" ] && continue
          printf '  %-10s %s  (%s)\n' "$n" "$desc" "$d"
        done <<<"$registry"
        return 0
        ;;
      --all|-a)
        while IFS='|' read -r n d sr desc; do
          [ -z "$n" ] && continue
          selected_names="${selected_names}${n}"$'\n'
        done <<<"$registry"
        ;;
      *)
        local arg found
        for arg in "$@"; do
          found=""
          while IFS='|' read -r n d sr desc; do
            [ -z "$n" ] && continue
            if [ "$n" = "$arg" ]; then
              selected_names="${selected_names}${n}"$'\n'
              found=1
              break
            fi
          done <<<"$registry"
          if [ -z "$found" ]; then
            echo "Error: unknown agent '$arg' (run 'sync-skills --list' for options)" >&2
            return 1
          fi
        done
        ;;
    esac
  else
    # Interactive multi-select
    if command -v fzf >/dev/null 2>&1; then
      local fzf_input=""
      while IFS='|' read -r n d sr desc; do
        [ -z "$n" ] && continue
        fzf_input="$fzf_input${n} | ${desc} (${d})"$'\n'
      done <<<"$registry"
      local picked
      picked="$(printf '%s' "$fzf_input" | fzf -m \
        --header="TAB select, ENTER confirm  |  sync .ai-agents/{skills,rules} -> agent skill dirs" \
        --prompt="agents> " --height=40% --border)"
      [ -z "$picked" ] && { echo "No agents selected."; return 0; }
      local line pname
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        pname="${line%% | *}"
        selected_names="${selected_names}${pname}"$'\n'
      done <<<"$picked"
    else
      # Fallback: numbered toggle loop (no fzf)
      local chosen=""
      local total=0 choice
      while IFS='|' read -r _ _ _ _; do total=$((total + 1)); done <<<"$registry"
      while true; do
        echo "Skill-sync agents (toggle number, blank or 'done' to confirm):"
        local idx=0 n d sr desc mark tname
        while IFS='|' read -r n d sr desc; do
          [ -z "$n" ] && continue
          idx=$((idx + 1))
          mark=" "
          if printf '%s\n' "$chosen" | grep -qx "$n"; then mark="x"; fi
          printf '  [%s] %d) %-10s %s  (%s)\n' "$mark" "$idx" "$n" "$desc" "$d"
        done <<<"$registry"
        printf 'choice> '
        read -r choice
        [ -z "$choice" ] && break
        [ "$choice" = "done" ] && break
        case "$choice" in
          *[!0-9]*) echo "  invalid: '$choice' (enter a number)"; continue ;;
        esac
        if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total" ]; then
          echo "  out of range: $choice"
          continue
        fi
        idx=0
        tname=""
        while IFS='|' read -r n d sr desc; do
          [ -z "$n" ] && continue
          idx=$((idx + 1))
          [ "$idx" = "$choice" ] && { tname="$n"; break; }
        done <<<"$registry"
        if printf '%s\n' "$chosen" | grep -qx "$tname"; then
          chosen="$(printf '%s\n' "$chosen" | grep -vx "$tname")"
        else
          chosen="${chosen}${tname}"$'\n'
        fi
      done
      selected_names="$chosen"
    fi
  fi

  if [ -z "$selected_names" ]; then
    echo "No agents selected."
    return 0
  fi

  # Helper: backup an existing path to .bkup (timestamped if .bkup exists).
  _ss_backup_path() {
    local target_path="$1"
    local backup="${target_path}.bkup"
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      backup="${backup}.$(date +%Y%m%d%H%M%S)"
    fi
    /bin/cp -R "$target_path" "$backup"
    echo "$backup"
  }

  # Helper: replace dest with symlink to src dir, backing up if needed.
  _ss_link_dir() {
    local src="$1"
    local dest="$2"
    local label="$3"
    if [ -L "$dest" ]; then
      local cur
      cur="$(readlink "$dest")"
      if [ "$cur" = "$src" ]; then
        echo "  $label already synced"
      else
        ln -sfn "$src" "$dest"
        echo "  updated $label (symlink refreshed)"
      fi
    elif [ -e "$dest" ]; then
      local backup
      backup="$(_ss_backup_path "$dest")"
      rm -rf "$dest"
      ln -sfn "$src" "$dest"
      echo "  replaced $label (backup: $backup)"
    else
      ln -sfn "$src" "$dest"
      echo "  linked $label"
    fi
  }

  local aname adir asr sname spath rname rpath
  while IFS= read -r aname; do
    [ -z "$aname" ] && continue
    adir=""; asr=""
    while IFS='|' read -r n d sr desc; do
      [ -z "$n" ] && continue
      [ "$n" = "$aname" ] && { adir="$d"; asr="$sr"; break; }
    done <<<"$registry"
    [ -z "$adir" ] && continue

    echo "Syncing skills -> $aname ($adir)"
    mkdir -p "$adir"
    while IFS='|' read -r sname spath; do
      [ -z "$sname" ] && continue
      _ss_link_dir "$spath" "$adir/$sname" "$aname: skill/$sname"
    done <<<"$skill_dirs"

    if [ "$asr" = "true" ] && [ -n "$rule_dirs" ]; then
      echo "Syncing rules as skills -> $aname"
      while IFS='|' read -r rname rpath; do
        [ -z "$rname" ] && continue
        _ss_link_dir "$rpath" "$adir/$rname" "$aname: rule/$rname"
      done <<<"$rule_dirs"
    fi
  done <<<"$selected_names"

  echo "Done."
  unset -f _ss_backup_path _ss_link_dir
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
