#!/usr/bin/env bash
set -euo pipefail

# subagent.sh — tmux pane management for autonomous sub-agents.
# Wraps the tmux mechanics described in .ai-agents/skills/tmux-subagents.md.
# Supports opencode (default) and Claude Code (SUBAGENT_CLI=claude).

# ── Config ──

SUBAGENT_CLI="${SUBAGENT_CLI:-opencode}"
SUBAGENT_SHELL_READY_DELAY_MS="${SUBAGENT_SHELL_READY_DELAY_MS:-500}"
SUBAGENT_POLL_INTERVAL="${SUBAGENT_POLL_INTERVAL:-2}"   # seconds
SUBAGENT_LAYOUT="${SUBAGENT_LAYOUT:-even-horizontal}"

# Registry dir keyed by parent tmux pane (one orchestrator per pane).
REGISTRY_DIR="${TMPDIR:-/tmp}/opencode-subagents-${TMUX_PANE:-nopane}"
mkdir -p "$REGISTRY_DIR"

# ── Helpers ──

_die() { echo "subagent: $*" >&2; exit 1; }

_shell_escape() {
  local s=$1
  s=${s//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

_get_shell_ready_delay() {
  local ms="$SUBAGENT_SHELL_READY_DELAY_MS"
  # Convert ms to seconds (fractional)
  awk -v ms="$ms" 'BEGIN { printf "%.3f", ms / 1000 }'
}

# Write a .meta file for a subagent (key=value lines)
_write_meta() {
  local name=$1 key=$2 val=$3
  local file="$REGISTRY_DIR/$name.meta"
  if [ -f "$file" ]; then
    # Replace existing key or append
    if grep -q "^${key}=" "$file"; then
      local tmp="$file.tmp"
      awk -v k="$key" -v v="$val" '$0 ~ k"=" { print k"="v; next } { print }' "$file" > "$tmp"
      mv "$tmp" "$file"
    else
      printf '%s=%s\n' "$key" "$val" >> "$file"
    fi
  else
    printf '%s=%s\n' "$key" "$val" > "$file"
  fi
}

_read_meta() {
  local name=$1 key=$2
  local file="$REGISTRY_DIR/$name.meta"
  [ -f "$file" ] || return 1
  grep "^${key}=" "$file" | head -1 | cut -d= -f2-
}

_meta_keys() {
  local file="$REGISTRY_DIR/$1.meta"
  [ -f "$file" ] || return 1
  cut -d= -f1 "$file"
}

_rebalance_layout() {
  [ -n "${TMUX_PANE:-}" ] || return 0
  tmux select-layout -t "$TMUX_PANE" "$SUBAGENT_LAYOUT" 2>/dev/null || true
}

_unique_name() {
  local base=$1
  if [ ! -f "$REGISTRY_DIR/$base.meta" ]; then
    echo "$base"
    return
  fi
  local n=2
  while [ -f "$REGISTRY_DIR/$base-$n.meta" ]; do
    n=$((n + 1))
  done
  echo "$base-$n"
}

# ── Commands ──

cmd_spawn() {
  [ -n "${TMUX_PANE:-}" ] || _die "not inside tmux. start with: tmux new -A -s opencode 'opencode'"
  command -v tmux >/dev/null 2>&1 || _die "tmux not found"

  local agent="" name="" cwd="" model="" task="" interactive=false
  while [ $# -gt 0 ]; do
    case "$1" in
      --name)   name=$2; shift 2 ;;
      --cwd)    cwd=$2; shift 2 ;;
      --model)  model=$2; shift 2 ;;
      --interactive|-i) interactive=true; shift ;;
      --*)      _die "unknown flag: $1" ;;
      *)        if [ -z "$agent" ]; then agent=$1; else task="$task $1"; fi; shift ;;
    esac
  done
  task="${task# }"
  [ -n "$agent" ] || _die "usage: subagent spawn <agent> [--name <name>] [--cwd <dir>] [--model <m>] [--interactive] \"<task>\""
  [ -n "$task" ]  || _die "task is required"

  # Default name to agent name, deduplicated
  [ -n "$name" ] || name=$(_unique_name "$agent")

  # Resolve cwd
  if [ -n "$cwd" ]; then
    case "$cwd" in
      /*) : ;;
      *) cwd="$(pwd)/$cwd" ;;
    esac
  else
    cwd="$(pwd)"
  fi

  # Create tmux pane (right split off parent)
  local pane
  pane=$(tmux split-window -d -h -t "$TMUX_PANE" -P -F '#{pane_id}')
  [ -n "$pane" ] || _die "failed to create tmux pane"

  sleep "$(_get_shell_ready_delay)"

  # Output file for headless mode
  local output_file=""
  local launch_script="$REGISTRY_DIR/$name-launch.sh"

  if [ "$interactive" = true ]; then
    # Interactive: launch TUI, user drives. No sentinel — user exits pane when done.
    local cli_cmd
    if [ "$SUBAGENT_CLI" = claude ]; then
      cli_cmd="claude"
      [ -n "$model" ] && cli_cmd="$cli_cmd --model $(_shell_escape "$model")"
      cli_cmd="$cli_cmd --agent $(_shell_escape "$agent")"
    else
      cli_cmd="opencode"
      [ -n "$model" ] && cli_cmd="$cli_cmd -m $(_shell_escape "$model")"
      cli_cmd="$cli_cmd --agent $(_shell_escape "$agent")"
    fi
    cat > "$launch_script" << EOF
#!/bin/bash
cd $(_shell_escape "$cwd")
$cli_cmd
EOF
    chmod +x "$launch_script"
  else
    # Autonomous: headless run, redirect output, emit sentinel
    output_file="$REGISTRY_DIR/$name-output.jsonl"
    local cli_cmd
    if [ "$SUBAGENT_CLI" = claude ]; then
      cli_cmd="claude --dangerously-skip-permissions -p $(_shell_escape "$task")"
      [ -n "$model" ] && cli_cmd="$cli_cmd --model $(_shell_escape "$model")"
      [ -n "$agent" ] && cli_cmd="$cli_cmd --agent $(_shell_escape "$agent")"
    else
      cli_cmd="opencode run --agent $(_shell_escape "$agent") --auto"
      [ -n "$model" ] && cli_cmd="$cli_cmd --model $(_shell_escape "$model")"
      cli_cmd="$cli_cmd --format json --dir $(_shell_escape "$cwd") $(_shell_escape "$task")"
    fi

    cat > "$launch_script" << EOF
#!/bin/bash
cd $(_shell_escape "$cwd")
$cli_cmd > $(_shell_escape "$output_file") 2>&1
echo "__SUBAGENT_DONE_\$?__"
EOF
    chmod +x "$launch_script"
  fi

  # Send the launch script to the pane
  tmux send-keys -t "$pane" -l "bash $(_shell_escape "$launch_script")"
  tmux send-keys -t "$pane" Enter

  # Record metadata
  _write_meta "$name" "name" "$name"
  _write_meta "$name" "agent" "$agent"
  _write_meta "$name" "pane" "$pane"
  _write_meta "$name" "cwd" "$cwd"
  _write_meta "$name" "status" "running"
  _write_meta "$name" "started_at" "$(date +%s)"
  _write_meta "$name" "interactive" "$interactive"
  [ -n "$model" ] && _write_meta "$name" "model" "$model"
  [ -n "$output_file" ] && _write_meta "$name" "output_file" "$output_file"

  _rebalance_layout

  echo "$name $pane"
}

cmd_poll() {
  local name=$1; shift || true
  local timeout=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --timeout) timeout=$2; shift 2 ;;
      *) shift ;;
    esac
  done
  [ -n "$name" ] || _die "usage: subagent poll <name> [--timeout <sec>]"

  local pane status
  pane=$(_read_meta "$name" pane) || _die "no subagent named '$name'"
  status=$(_read_meta "$name" status) || status="unknown"

  if [ "$status" = "done" ] || [ "$status" = "failed" ] || [ "$status" = "killed" ]; then
    echo "$status"
    return 0
  fi

  local start=$SECONDS
  while true; do
    local screen
    screen=$(tmux capture-pane -p -t "$pane" -S -5 2>/dev/null || echo "")
    if echo "$screen" | grep -q '__SUBAGENT_DONE_'; then
      local exit_code
      exit_code=$(echo "$screen" | grep -o '__SUBAGENT_DONE_[0-9]*__' | grep -o '[0-9]*' | head -1)
      [ -z "$exit_code" ] && exit_code=0
      if [ "$exit_code" = "0" ]; then
        _write_meta "$name" "status" "done"
      else
        _write_meta "$name" "status" "failed"
      fi
      _write_meta "$name" "exit_code" "$exit_code"
      _write_meta "$name" "finished_at" "$(date +%s)"
      _read_meta "$name" status
      return 0
    fi

    # Check if pane is gone (killed externally)
    if ! tmux list-panes -F '#{pane_id}' 2>/dev/null | grep -q "^${pane}$"; then
      _write_meta "$name" "status" "killed"
      echo "killed"
      return 0
    fi

    if [ "$timeout" -gt 0 ] && [ $((SECONDS - start)) -ge "$timeout" ]; then
      echo "timeout"
      return 1
    fi

    sleep "$SUBAGENT_POLL_INTERVAL"
  done
}

cmd_output() {
  local name=$1; shift || true
  [ -n "$name" ] || _die "usage: subagent output <name>"

  local output_file
  output_file=$(_read_meta "$name" output_file) || _die "no output file for '$name' (interactive subagents have no captured output)"

  [ -f "$output_file" ] || _die "output file not found: $output_file"

  # Try to extract the last assistant message from JSON output
  if command -v jq >/dev/null 2>&1; then
    local msg
    msg=$(jq -r 'select(.type == "message" and .role == "assistant") | .content' "$output_file" 2>/dev/null | tail -1)
    if [ -n "$msg" ] && [ "$msg" != "null" ]; then
      echo "$msg"
      return 0
    fi
  fi

  # Fallback: print the raw file (strips JSON noise as best effort)
  cat "$output_file"
}

cmd_status() {
  printf '%-8s %-14s %-10s %-6s %-8s %s\n' "AGENT" "NAME" "STATUS" "TIME" "PANE" "EXIT"
  for meta_file in "$REGISTRY_DIR"/*.meta; do
    [ -f "$meta_file" ] || continue
    local name agent status pane started_at finished_at exit_code
    name=$(grep '^name=' "$meta_file" | cut -d= -f2-)
    agent=$(grep '^agent=' "$meta_file" | cut -d= -f2-)
    status=$(grep '^status=' "$meta_file" | cut -d= -f2-)
    pane=$(grep '^pane=' "$meta_file" | cut -d= -f2-)
    started_at=$(grep '^started_at=' "$meta_file" | cut -d= -f2-)
    exit_code=$(grep '^exit_code=' "$meta_file" 2>/dev/null | cut -d= -f2-)
    [ -n "$exit_code" ] || exit_code="-"

    local elapsed="-"
    if [ -n "$started_at" ]; then
      local now
      now=$(date +%s)
      if [ "$status" = "running" ]; then
        elapsed=$(( now - started_at ))
      else
        finished_at=$(grep '^finished_at=' "$meta_file" 2>/dev/null | cut -d= -f2-)
        [ -n "$finished_at" ] && elapsed=$(( finished_at - started_at ))
      fi
      [ "$elapsed" != "-" ] && elapsed="${elapsed}s"
    fi

    printf '%-8s %-14s %-10s %-6s %-8s %s\n' "$agent" "$name" "$status" "$elapsed" "$pane" "$exit_code"
  done
}

cmd_kill() {
  local name=$1; shift || true
  [ -n "$name" ] || _die "usage: subagent kill <name>"

  local pane
  pane=$(_read_meta "$name" pane) || _die "no subagent named '$name'"

  tmux kill-pane -t "$pane" 2>/dev/null || true
  _write_meta "$name" "status" "killed"
  _write_meta "$name" "finished_at" "$(date +%s)"
  _rebalance_layout
  echo "killed $name"
}

cmd_resume() {
  local name=$1; shift || true
  local message=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --*) shift ;;
      *) message="$message $1"; shift ;;
    esac
  done
  message="${message# }"
  [ -n "$name" ] || _die "usage: subagent resume <name> \"<message>\""
  [ -n "$message" ] || _die "message is required"

  local pane cwd agent
  pane=$(_read_meta "$name" pane) || _die "no subagent named '$name'"
  cwd=$(_read_meta "$name" cwd) || cwd="$(pwd)"
  agent=$(_read_meta "$name" agent) || agent=""

  # Reuse the existing pane if still open, else create a new one
  if ! tmux list-panes -F '#{pane_id}' 2>/dev/null | grep -q "^${pane}$"; then
    pane=$(tmux split-window -d -h -t "$TMUX_PANE" -P -F '#{pane_id}')
    sleep "$(_get_shell_ready_delay)"
    _write_meta "$name" "pane" "$pane"
  fi

  _write_meta "$name" "status" "running"
  _write_meta "$name" "started_at" "$(date +%s)"

  local output_file
  output_file="$REGISTRY_DIR/$name-output.jsonl"

  local launch_script="$REGISTRY_DIR/$name-resume.sh"
  if [ "$SUBAGENT_CLI" = claude ]; then
    cat > "$launch_script" << EOF
#!/bin/bash
cd $(_shell_escape "$cwd")
claude --resume $(_shell_escape "$name") -p $(_shell_escape "$message") --output-format json > $(_shell_escape "$output_file") 2>&1
echo "__SUBAGENT_DONE_\$?__"
EOF
  else
    cat > "$launch_script" << EOF
#!/bin/bash
cd $(_shell_escape "$cwd")
opencode run -c -s $(_shell_escape "$name") --auto --format json $(_shell_escape "$message") > $(_shell_escape "$output_file") 2>&1
echo "__SUBAGENT_DONE_\$?__"
EOF
  fi
  chmod +x "$launch_script"

  tmux send-keys -t "$pane" -l "bash $(_shell_escape "$launch_script")"
  tmux send-keys -t "$pane" Enter

  _rebalance_layout
  echo "resumed $name"
}

cmd_steer() {
  local name=$1; shift || true
  local message=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --*) shift ;;
      *) message="$message $1"; shift ;;
    esac
  done
  message="${message# }"
  [ -n "$name" ] || _die "usage: subagent steer <name> \"<message>\""
  [ -n "$message" ] || _die "message is required"

  local pane
  pane=$(_read_meta "$name" pane) || _die "no subagent named '$name'"

  # Flatten newlines (each Enter submits a turn in interactive TUI)
  message=$(echo "$message" | tr '\n' ' ')

  tmux send-keys -t "$pane" -l "$message"
  tmux send-keys -t "$pane" Enter
  echo "steered $name"
}

cmd_cleanup() {
  for meta_file in "$REGISTRY_DIR"/*.meta; do
    [ -f "$meta_file" ] || continue
    local name pane status
    name=$(grep '^name=' "$meta_file" | cut -d= -f2-)
    pane=$(grep '^pane=' "$meta_file" | cut -d= -f2-)
    status=$(grep '^status=' "$meta_file" | cut -d= -f2-)
    if [ "$status" = "running" ]; then
      tmux kill-pane -t "$pane" 2>/dev/null || true
      _write_meta "$name" "status" "killed"
    fi
  done
  echo "cleaned up running subagents"
}

# ── Main ──

main() {
  local cmd=${1:-help}
  shift || true

  case "$cmd" in
    spawn)    cmd_spawn "$@" ;;
    poll)     cmd_poll "$@" ;;
    output)   cmd_output "$@" ;;
    status)   cmd_status ;;
    kill)     cmd_kill "$@" ;;
    resume)   cmd_resume "$@" ;;
    steer)    cmd_steer "$@" ;;
    cleanup)  cmd_cleanup ;;
    help|-h|--help)
      cat << 'USAGE'
subagent — tmux pane management for autonomous sub-agents

Commands:
  spawn <agent> [--name <name>] [--cwd <dir>] [--model <m>] [--interactive] "<task>"
      Spawn a sub-agent in a new tmux pane. Returns "<name> <pane_id>".
  poll <name> [--timeout <sec>]
      Block until the sub-agent finishes or timeout. Prints status.
  output <name>
      Print the sub-agent's captured output (final assistant message).
  status
      List all known subagents with state and elapsed time.
  kill <name>
      Kill the pane and mark as killed.
  resume <name> "<message>"
      Resume a finished sub-agent with a follow-up message in the same pane.
  steer <name> "<message>"
      Send a message to a running interactive sub-agent's pane.
  cleanup
      Kill all running subagents.

Environment:
  SUBAGENT_CLI                 opencode (default) or claude
  SUBAGENT_SHELL_READY_DELAY_MS  delay before sending command (default 500)
  SUBAGENT_POLL_INTERVAL        poll interval in seconds (default 2)
  SUBAGENT_LAYOUT               tmux layout name (default even-horizontal)
USAGE
      ;;
    *) _die "unknown command '$cmd'. run 'subagent help' for usage." ;;
  esac
}

main "$@"
