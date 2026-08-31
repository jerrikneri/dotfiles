#!/usr/bin/env bash
# agent_manifest.sh -- read-only inventory of AI-agent harness components.
# Companion scan script for the manifest skill: .ai-agents/skills/manifest/SKILL.md
#
# Enumerates instruction files, skills, rules, commands, agents, plugins, MCP
# servers, and config files across opencode, Claude Code, Claude Desktop,
# Cursor, and Gemini -- wherever they are installed.
#
# Output (TSV), one row per component:
#   category  name  harness  path  resolved  lines  est_tokens  last_commit  flags
# Lines starting with '#' on stderr are metadata/notes; on stdout they are the
# summary block. est_tokens = bytes/4 (rough estimate).
#
# Usage:
#   agent_manifest.sh [--home DIR] [--project DIR]
#
# Dependencies: git (commit dates), jq (config parsing) -- degrades gracefully
# without them. Strictly read-only: writes nothing outside its own output.

set -uo pipefail

usage() {
  cat <<'EOF'
Usage: agent_manifest.sh [--home DIR] [--project DIR]

--home     Home directory to scan (default: $HOME)
--project  Project directory to scan (default: $PWD)
-h|--help  Show this help

Read-only inventory of AI-agent harness components (opencode, Claude Code,
Claude Desktop, Cursor, Gemini). Prints TSV rows:
category, name, harness, path, resolved, lines, est_tokens, last_commit, flags
EOF
}

HOME_DIR="${HOME:-$PWD}"
PROJECT_DIR="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --home)
      [ $# -ge 2 ] || { printf '%s needs a value\n' "$1" >&2; exit 2; }
      HOME_DIR="$2"; shift 2
      ;;
    --project)
      [ $# -ge 2 ] || { printf '%s needs a value\n' "$1" >&2; exit 2; }
      PROJECT_DIR="$2"; shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
  esac
done

NOW_EPOCH="$(date +%s)"
STALE_CUT=$((NOW_EPOCH - 182 * 24 * 60 * 60))
if command -v jq >/dev/null 2>&1; then HAS_JQ=1; else HAS_JQ=0; fi

OUT_TMP="$(mktemp "${TMPDIR:-/tmp}/agent_manifest.XXXXXX")"
[ -n "$OUT_TMP" ] || { printf 'mktemp failed\n' >&2; exit 1; }
trap 'rm -f "$OUT_TMP"' EXIT

printf 'category\tname\tharness\tpath\tresolved\tlines\test_tokens\tlast_commit\tflags\n' >>"$OUT_TMP"

printf '# agent_manifest %s home=%s project=%s jq=%s\n' \
  "$(date +%Y-%m-%dT%H:%M:%S)" "$HOME_DIR" "$PROJECT_DIR" "$HAS_JQ" >&2

emit() { # category name harness path resolved lines tokens commit flags
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" >>"$OUT_TMP"
}

note() { printf '# note: %s\n' "$1" >&2; }

resolve_path() {
  local p="$1" r=""
  if command -v realpath >/dev/null 2>&1; then
    r="$(realpath "$p" 2>/dev/null)" || r=""
  fi
  if [ -z "$r" ] && command -v perl >/dev/null 2>&1; then
    r="$(perl -MCwd=abs_path -e 'print abs_path($ARGV[0])' "$p" 2>/dev/null)" || r=""
  fi
  [ -n "$r" ] || r="$p"
  printf '%s\n' "$r"
}

last_commit() { # path -> LAST_COMMIT_DATE (+ LAST_EPOCH for staleness)
  local p="$1" dir out
  dir="$(dirname -- "$p")"
  LAST_COMMIT_DATE="-"
  LAST_EPOCH=""
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  # basename pathspec: an absolute path through a symlink (e.g. ~/.config/opencode)
  # does not match the physical worktree prefix and would falsely report untracked
  out="$(git -C "$dir" log -1 --format='%ct %cs' -- "$(basename -- "$p")" 2>/dev/null)" || out=""
  if [ -n "$out" ]; then
    LAST_EPOCH="${out%% *}"
    LAST_COMMIT_DATE="${out##* }"
  else
    LAST_COMMIT_DATE="untracked"
  fi
}

file_stats() { # path -> STATS_LINES, STATS_BYTES, STATS_TOKENS
  local p="$1"
  STATS_LINES="-"
  STATS_BYTES="-"
  STATS_TOKENS="-"
  [ -f "$p" ] || return 0
  STATS_LINES="$(wc -l <"$p" 2>/dev/null | tr -d '[:space:]')"
  STATS_BYTES="$(wc -c <"$p" 2>/dev/null | tr -d '[:space:]')"
  case "$STATS_BYTES" in
    ''|*[!0-9]*) return 0 ;;
    *) STATS_TOKENS=$((STATS_BYTES / 4)) ;;
  esac
}

desc_flags() { # file expected_name -> DESC_FLAG (frontmatter sanity)
  local p="$1" expected="$2" first fm_name has_desc
  DESC_FLAG=""
  [ -f "$p" ] || return 0
  first=""
  IFS= read -r first <"$p" 2>/dev/null || true
  if [ "$first" != "---" ]; then
    DESC_FLAG="no-frontmatter"
    return 0
  fi
  has_desc="$(awk 'NR>1 && /^---[[:space:]]*$/ {exit} NR>1 && /^description:/ {print 1; exit}' "$p" 2>/dev/null)"
  [ "$has_desc" = "1" ] || DESC_FLAG="no-description"
  fm_name="$(awk 'NR>1 && /^---[[:space:]]*$/ {exit} NR>1 && /^name:/ {sub(/^name:[[:space:]]*/, ""); print; exit}' "$p" 2>/dev/null | tr -d '" \r')"
  if [ -n "$fm_name" ] && [ "$fm_name" != "$expected" ]; then
    DESC_FLAG="${DESC_FLAG:+$DESC_FLAG,}name-mismatch"
  fi
}

scan_skill_dir() { # base_dir harness category -- <name>/SKILL.md layouts
  local base="$1" harness="$2" category="$3"
  local d dir name sk target flags
  [ -d "$base" ] || return 0
  for d in "$base"/*; do
    [ -d "$d" ] || [ -L "$d" ] || continue
    dir="${d%/}"
    name="${dir##*/}"
    flags=""
    if [ -L "$dir" ]; then
      target="$(readlink "$dir")"
      case "$target" in
        /*) : ;;
        *) target="$(dirname -- "$dir")/$target" ;;
      esac
      [ -e "$dir" ] || flags="orphan-symlink"
    else
      target="$dir"
    fi
    target="$(resolve_path "$target")"
    sk="$dir/SKILL.md"
    if [ ! -f "$sk" ]; then
      flags="${flags:+$flags,}missing-skmd"
      emit "$category" "$name" "$harness" "$dir" "$target" - - - "$flags"
      continue
    fi
    desc_flags "$sk" "$name"
    [ -n "$DESC_FLAG" ] && flags="${flags:+$flags,}$DESC_FLAG"
    file_stats "$sk"
    last_commit "$sk"
    if [ -n "$LAST_EPOCH" ] && [ "$LAST_EPOCH" -lt "$STALE_CUT" ]; then
      flags="${flags:+$flags,}stale>6mo"
    fi
    emit "$category" "$name" "$harness" "$sk" "$target" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
  done
}

scan_md_dir() { # base_dir harness category -- flat *.md layouts
  local base="$1" harness="$2" category="$3"
  local f name flags
  [ -d "$base" ] || return 0
  for f in "$base"/*.md; do
    [ -f "$f" ] || continue
    name="$(basename -- "$f" .md)"
    flags=""
    desc_flags "$f" "$name"
    [ -n "$DESC_FLAG" ] && flags="$DESC_FLAG"
    file_stats "$f"
    last_commit "$f"
    if [ -n "$LAST_EPOCH" ] && [ "$LAST_EPOCH" -lt "$STALE_CUT" ]; then
      flags="${flags:+$flags,}stale>6mo"
    fi
    emit "$category" "$name" "$harness" "$f" "$(resolve_path "$f")" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
  done
}

scan_plugin_dir() { # base_dir harness -- *.ts/*.js plugin files
  local base="$1" harness="$2"
  local f name flags
  [ -d "$base" ] || return 0
  for f in "$base"/*.ts "$base"/*.js; do
    [ -f "$f" ] || continue
    name="$(basename -- "$f")"
    flags=""
    file_stats "$f"
    last_commit "$f"
    if [ -n "$LAST_EPOCH" ] && [ "$LAST_EPOCH" -lt "$STALE_CUT" ]; then
      flags="${flags:+$flags,}stale>6mo"
    fi
    emit "plugin" "$name" "$harness" "$f" "$(resolve_path "$f")" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
  done
}

scan_plugin_installs() { # base_dir harness -- claude-style install subdirs
  local base="$1" harness="$2"
  local d dir flags
  [ -d "$base" ] || return 0
  for d in "$base"/*; do
    [ -d "$d" ] || [ -L "$d" ] || continue
    dir="${d%/}"
    flags="install-dir"
    [ -e "$dir" ] || flags="orphan-symlink,install-dir"
    emit "plugin" "${dir##*/}" "$harness" "$dir" "$(resolve_path "$dir")" - - - "$flags"
  done
}

strip_jsonc() { # file -> json on stdout with full-line // comments removed
  sed -E 's|^[[:space:]]*//.*$||' "$1" 2>/dev/null
}

cfg_val() { # config_file jq_filter -> values (empty if absent/unparseable)
  local cfg="$1" q="$2"
  [ -f "$cfg" ] || return 0
  if [ "$HAS_JQ" -eq 0 ]; then
    note "jq not found -- skipped config parsing for $cfg"
    return 0
  fi
  strip_jsonc "$cfg" | jq -r "$q" 2>/dev/null || note "jq failed to parse $cfg"
}

emit_declared() { # category harness config_file jq_filter
  local category="$1" harness="$2" cfg="$3" filter="$4"
  local lines x
  [ -f "$cfg" ] || return 0
  lines="$(cfg_val "$cfg" "$filter")"
  while IFS= read -r x; do
    [ -n "$x" ] || continue
    emit "$category" "$x" "$harness" "$cfg" "-" - - - "declared"
  done <<<"$lines"
}

instruction_resolve() { # config_file entry -> resolved file paths, one per line
  local cfg="$1" entry="$2" base hits
  case "$entry" in
    /*) [ -f "$entry" ] && printf '%s\n' "$entry"; return 0 ;;
    \~*) entry="${HOME_DIR}/${entry#\~/}"; [ -f "$entry" ] && printf '%s\n' "$entry"; return 0 ;;
  esac
  for base in "$(dirname -- "$cfg")" "$PROJECT_DIR" "$HOME_DIR"; do
    if [ -f "$base/$entry" ]; then
      printf '%s\n' "$base/$entry"
      return 0
    fi
  done
  case "$entry" in
    *\?*|*\**)
      for base in "$(dirname -- "$cfg")" "$PROJECT_DIR" "$HOME_DIR"; do
        hits="$(find "$base" -maxdepth 4 -path "$base/$entry" -type f 2>/dev/null | head -n 20 || true)"
        if [ -n "$hits" ]; then
          printf '%s\n' "$hits"
          return 0
        fi
      done
      ;;
  esac
  printf 'MISSING\n'
}

scan_instructions() { # config_file harness
  local cfg="$1" harness="$2" entries entry p flags
  [ -f "$cfg" ] || return 0
  entries="$(cfg_val "$cfg" '.instructions[]?')"
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    case "$entry" in
      http://*|https://*)
        emit "instruction-file" "$entry" "$harness" "$entry" "-" - - - "remote"
        continue
        ;;
    esac
    while IFS= read -r p; do
      if [ "$p" = "MISSING" ]; then
        emit "instruction-file" "$entry" "$harness" "$entry" "-" - - - "unresolved"
        continue
      fi
      flags="from-config"
      file_stats "$p"
      last_commit "$p"
      if [ -n "$LAST_EPOCH" ] && [ "$LAST_EPOCH" -lt "$STALE_CUT" ]; then
        flags="${flags},stale>6mo"
      fi
      emit "instruction-file" "$(basename -- "$p")" "$harness" "$p" "$(resolve_path "$p")" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
    done <<<"$(instruction_resolve "$cfg" "$entry")"
  done <<<"$entries"
}

emit_instruction_autoload() { # path harness -- AGENTS.md / CLAUDE.md files
  local p="$1" harness="$2" flags="auto-loaded"
  [ -f "$p" ] || return 0
  case "$(basename -- "$p")" in
    AGENTS.local.md) flags="auto-loaded,local-overlay" ;;
  esac
  file_stats "$p"
  last_commit "$p"
  if [ -n "$LAST_EPOCH" ] && [ "$LAST_EPOCH" -lt "$STALE_CUT" ]; then
    flags="${flags},stale>6mo"
  fi
  emit "instruction-file" "$(basename -- "$p")" "$harness" "$p" "$(resolve_path "$p")" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
}

scan_mcp_config() { # config_file harness jq_filter -> "name|type|enabled" lines
  local cfg="$1" harness="$2" filter="$3"
  local lines line name rest mtype enabled flags
  [ -f "$cfg" ] || return 0
  lines="$(cfg_val "$cfg" "$filter")"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line%%|*}"
    rest="${line#*|}"
    mtype="${rest%%|*}"
    enabled="${rest##*|}"
    flags="type:$mtype"
    [ "$enabled" = "false" ] && flags="${flags},disabled"
    emit "mcp" "$name" "$harness" "$cfg" "-" - - - "$flags"
  done <<<"$lines"
}

claude_projects_mcp() { # claude.json per-project mcpServers
  local cfg="$1" lines line name rest mtype enabled proj flags
  [ -f "$cfg" ] || return 0
  # shellcheck disable=SC2016
  lines="$(cfg_val "$cfg" '(.projects // {}) | to_entries[] | select((.value.mcpServers // {}) | length > 0) | .key as $p | (.value.mcpServers // {}) | to_entries[] | "\(.key)|\(.value.type // "?")|\(.value.enabled // true)|\($p)"')"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    name="${line%%|*}"
    rest="${line#*|}"
    mtype="${rest%%|*}"
    rest="${rest#*|}"
    enabled="${rest%%|*}"
    proj="${rest##*|}"
    flags="type:$mtype,project:$proj"
    [ "$enabled" = "false" ] && flags="${flags},disabled"
    emit "mcp" "$name" "claude-code-project" "$cfg" "-" - - - "$flags"
  done <<<"$lines"
}

emit_config() { # path harness
  local p="$1" harness="$2" flags=""
  [ -f "$p" ] || return 0
  grep -qE '^[[:space:]]*//' "$p" 2>/dev/null && flags="jsonc-comments"
  grep -q '"hooks"' "$p" 2>/dev/null && flags="${flags:+$flags,}has-hooks"
  file_stats "$p"
  last_commit "$p"
  emit "config" "$(basename -- "$p")" "$harness" "$p" "$(resolve_path "$p")" "$STATS_LINES" "$STATS_TOKENS" "$LAST_COMMIT_DATE" "$flags"
}

# --- configs --------------------------------------------------------------

OPENCODE_GLOBAL="$HOME_DIR/.config/opencode/opencode.json"
OPENCODE_PROJECT=""
for p in "$PROJECT_DIR/opencode.json" "$PROJECT_DIR/.opencode/opencode.json"; do
  if [ -f "$p" ]; then OPENCODE_PROJECT="$p"; break; fi
done

CLAUDE_DESKTOP_CFG="$HOME_DIR/Library/Application Support/Claude/claude_desktop_config.json"

emit_config "$OPENCODE_GLOBAL" "opencode-global"
emit_config "$OPENCODE_PROJECT" "opencode-project"
emit_config "$HOME_DIR/.claude.json" "claude-code"
emit_config "$HOME_DIR/.claude/settings.json" "claude-global"
emit_config "$PROJECT_DIR/.claude/settings.json" "claude-project"
emit_config "$PROJECT_DIR/.mcp.json" "claude-project"
emit_config "$CLAUDE_DESKTOP_CFG" "claude-desktop"
emit_config "$HOME_DIR/.cursor/mcp.json" "cursor"
emit_config "$PROJECT_DIR/.cursor/mcp.json" "cursor-project"
emit_config "$HOME_DIR/.gemini/settings.json" "gemini"

# --- instruction files (always-on cost) ------------------------------------

scan_instructions "$OPENCODE_GLOBAL" "opencode-global"
scan_instructions "$OPENCODE_PROJECT" "opencode-project"

emit_instruction_autoload "$PROJECT_DIR/AGENTS.md" "project"
emit_instruction_autoload "$PROJECT_DIR/AGENTS.local.md" "project"
emit_instruction_autoload "$PROJECT_DIR/CLAUDE.md" "project"
emit_instruction_autoload "$HOME_DIR/.claude/CLAUDE.md" "claude-global"
emit_instruction_autoload "$HOME_DIR/.config/opencode/AGENTS.md" "opencode-global"

# --- skills ----------------------------------------------------------------

scan_skill_dir "$HOME_DIR/.config/opencode/skills" "opencode-global" "skill"
scan_skill_dir "$PROJECT_DIR/.opencode/skills" "opencode-project" "skill"
scan_skill_dir "$HOME_DIR/.claude/skills" "claude-global" "skill"
scan_skill_dir "$PROJECT_DIR/.claude/skills" "claude-project" "skill"
scan_skill_dir "$HOME_DIR/.agents/skills" "agents-global" "skill"
scan_skill_dir "$PROJECT_DIR/.agents/skills" "agents-project" "skill"

# --- rules ------------------------------------------------------------------

scan_md_dir "$HOME_DIR/.config/opencode/rules" "opencode-global" "rule"
scan_md_dir "$PROJECT_DIR/.opencode/rules" "opencode-project" "rule"
scan_md_dir "$HOME_DIR/.claude/rules" "claude-global" "rule"
scan_md_dir "$PROJECT_DIR/.claude/rules" "claude-project" "rule"

# --- commands ---------------------------------------------------------------

scan_md_dir "$HOME_DIR/.config/opencode/commands" "opencode-global" "command"
scan_md_dir "$PROJECT_DIR/.opencode/commands" "opencode-project" "command"
scan_md_dir "$HOME_DIR/.claude/commands" "claude-global" "command"
scan_md_dir "$PROJECT_DIR/.claude/commands" "claude-project" "command"

# --- agents -----------------------------------------------------------------

scan_md_dir "$HOME_DIR/.config/opencode/agent" "opencode-global" "agent"
scan_md_dir "$HOME_DIR/.config/opencode/agents" "opencode-global" "agent"
scan_md_dir "$PROJECT_DIR/.opencode/agent" "opencode-project" "agent"
scan_md_dir "$PROJECT_DIR/.opencode/agents" "opencode-project" "agent"
scan_md_dir "$HOME_DIR/.claude/agents" "claude-global" "agent"
scan_md_dir "$PROJECT_DIR/.claude/agents" "claude-project" "agent"

# --- plugins ------------------------------------------------------------------

scan_plugin_dir "$HOME_DIR/.config/opencode/plugin" "opencode-global"
scan_plugin_dir "$HOME_DIR/.config/opencode/plugins" "opencode-global"
scan_plugin_dir "$PROJECT_DIR/.opencode/plugin" "opencode-project"
scan_plugin_dir "$PROJECT_DIR/.opencode/plugins" "opencode-project"
scan_plugin_installs "$HOME_DIR/.claude/plugins" "claude-global"
scan_plugin_installs "$PROJECT_DIR/.claude/plugins" "claude-project"

# --- mcp servers ---------------------------------------------------------------

MCP_FILTER='(.mcpServers // .mcp.servers // {}) | to_entries[] | "\(.key)|\(.value.type // "?")|\(.value.enabled // true)"'

scan_mcp_config "$OPENCODE_GLOBAL" "opencode-global" '(.mcp // {}) | to_entries[] | "\(.key)|\(.value.type // "?")|\(.value.enabled // true)"'
scan_mcp_config "$OPENCODE_PROJECT" "opencode-project" '(.mcp // {}) | to_entries[] | "\(.key)|\(.value.type // "?")|\(.value.enabled // true)"'
scan_mcp_config "$HOME_DIR/.claude.json" "claude-code" '(.mcpServers // {}) | to_entries[] | "\(.key)|\(.value.type // "?")|true"'
claude_projects_mcp "$HOME_DIR/.claude.json"
scan_mcp_config "$PROJECT_DIR/.mcp.json" "claude-project" "$MCP_FILTER"
scan_mcp_config "$CLAUDE_DESKTOP_CFG" "claude-desktop" "$MCP_FILTER"
scan_mcp_config "$HOME_DIR/.cursor/mcp.json" "cursor" "$MCP_FILTER"
scan_mcp_config "$PROJECT_DIR/.cursor/mcp.json" "cursor-project" "$MCP_FILTER"
scan_mcp_config "$HOME_DIR/.gemini/settings.json" "gemini" "$MCP_FILTER"

# --- declarations inside opencode configs --------------------------------------

emit_declared "plugin" "opencode-global" "$OPENCODE_GLOBAL" '.plugin[]? | (if type == "array" then .[0] else . end) | tostring'
emit_declared "plugin" "opencode-project" "$OPENCODE_PROJECT" '.plugin[]? | (if type == "array" then .[0] else . end) | tostring'
emit_declared "agent" "opencode-global" "$OPENCODE_GLOBAL" '(.agent // {}) | keys[]'
emit_declared "agent" "opencode-project" "$OPENCODE_PROJECT" '(.agent // {}) | keys[]'
emit_declared "command" "opencode-global" "$OPENCODE_GLOBAL" '(.command // {}) | keys[]'
emit_declared "command" "opencode-project" "$OPENCODE_PROJECT" '(.command // {}) | keys[]'

for cfg in "$OPENCODE_GLOBAL" "$OPENCODE_PROJECT"; do
  [ -f "$cfg" ] || continue
  extra_paths="$(cfg_val "$cfg" '.skills.paths[]?')"
  while IFS= read -r x; do
    [ -n "$x" ] || continue
    case "$x" in
      /*) : ;;
      \~*) x="${HOME_DIR}/${x#\~/}" ;;
      *) x="$PROJECT_DIR/$x" ;;
    esac
    scan_skill_dir "$x" "opencode-extra" "skill"
  done <<<"$extra_paths"
done

# --- dotfiles single-source-of-truth (for sync-drift checks) -------------------

if [ -n "${DOTFILES:-}" ] && [ -d "$DOTFILES/.ai-agents" ]; then
  scan_skill_dir "$DOTFILES/.ai-agents/skills" "dotfiles-source" "skill"
  scan_skill_dir "$DOTFILES/.ai-agents/rules" "dotfiles-source" "rule"
fi
if [ -d "$PROJECT_DIR/.ai-agents" ]; then
  if [ -z "${DOTFILES:-}" ] || \
     [ "$(resolve_path "$PROJECT_DIR/.ai-agents")" != "$(resolve_path "$DOTFILES/.ai-agents")" ]; then
    scan_skill_dir "$PROJECT_DIR/.ai-agents/skills" "project-source" "skill"
    scan_skill_dir "$PROJECT_DIR/.ai-agents/rules" "project-source" "rule"
  fi
fi

# --- output --------------------------------------------------------------------

cat "$OUT_TMP"
printf '# summary\n'
awk -F'\t' 'NR>1 { c[$1]++; if ($7 ~ /^[0-9]+$/) t[$1]+=$7 } END { for (k in c) printf "# %s: %d rows, ~%d tokens\n", k, c[k], t[k] }' "$OUT_TMP" | sort
awk -F'\t' 'NR>1 && ($1 == "instruction-file" || $1 == "rule") { n++; if ($7 ~ /^[0-9]+$/) t+=$7 } END { printf "# always-on (instruction-file + rule): %d rows, ~%d tokens per session\n", n, t }' "$OUT_TMP"
awk -F'\t' 'NR>1 && $1 == "mcp" { n++ } END { printf "# mcp servers: %d (every enabled server adds tool schemas to each request)\n", n+0 }' "$OUT_TMP"
