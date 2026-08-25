# Tmux Subagents: Parallel Agent Panes

> Spawn autonomous sub-agents in dedicated tmux panes alongside the main session.
> Each sub-agent runs `opencode run` headless in its own pane, exits on completion,
> and the orchestrator detects a sentinel to collect results. Fully non-blocking:
> spawn several in parallel, keep working, collect each result as it finishes.
> Inspired by [pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents).
> Works with any AI coding agent that can run bash commands. Designed for opencode first.

---

## When to Use

- You need parallel investigation or implementation (scout two modules, research one API, implement a third)
- A sub-task would burn your context window if you did it inline (reading 20 files to find one pattern)
- You want to keep working while a long-running task executes (test suite, migration, build investigation)
- You need read-only recon without polluting your context with raw file contents
- You want to dispatch web research that returns a sourced brief, not raw HTML

**Trigger phrases:** "spawn a scout", "dispatch a subagent", "in parallel, also...", "meanwhile, check..."

---

## Requirements

- **tmux** running, with the orchestrator session inside it (`$TMUX` and `$TMUX_PANE` set)
- **opencode** on PATH
- **Bundled agent definitions** installed (see [Bundled Agents](#bundled-agents))
- Helper script `subagent.sh` on PATH or sourced (see [Helper Script](#helper-script))

Start opencode inside tmux:

```bash
tmux new -A -s opencode 'opencode'
```

---

## How It Works

```
┌─────────────────────┬──────────────────┐
│  Main session       │  scout (%12)     │
│  (orchestrator)     │  active 7m       │
│                     ├──────────────────┤
│  Keeps working      │  researcher (%13)│
│  while subagents    │  waiting 2m      │
│  run in parallel    │                  │
└─────────────────────┴──────────────────┘
```

1. Orchestrator calls `subagent spawn scout "task"` (returns immediately)
2. Helper script creates a tmux right-split pane and sends `opencode run --agent scout --auto ...`
3. The sub-agent runs autonomously, writes output to a file, then exits
4. Orchestrator polls `subagent poll scout` (or checks `subagent status`) for the sentinel
5. On completion, `subagent output scout` returns the result
6. Pane is closed automatically; layout is rebalanced

---

## Bundled Agents

Three agent definitions designed for autonomous tmux pane execution. Install them to `.opencode/agents/` (project) or `~/.config/opencode/agents/` (global):

| Agent | Tools | Role |
|-------|-------|------|
| **scout** | read, grep, glob | Fast read-only codebase recon |
| **researcher** | webfetch, websearch, bash | Web research, synthesized into a sourced brief |
| **worker** | read, edit, bash, webfetch, websearch, task | General implementer; may spawn its own scouts |

Agent definition files are in `.ai-agents/skills/examples/tmux-subagents/`. Copy them:

```bash
mkdir -p .opencode/agents
cp .ai-agents/skills/examples/tmux-subagents/*.md .opencode/agents/
```

### Custom agents

Create a `.md` file in `.opencode/agents/` (project) or `~/.config/opencode/agents/` (global):

```markdown
---
description: "Purpose of this agent"
mode: subagent
model: "openrouter/z-ai/glm-5.3"
tools:
  read: true
  edit: false
  bash: true
  glob: true
  grep: true
permission:
  bash: allow
  read: allow
---

You are a specialized agent that does X. Operate autonomously.
When finished, write your final summary and stop.
```

Discovery priority: **project > global**. A project-local file overrides a global one with the same name.

---

## Helper Script

The `subagent.sh` helper script (install from `.scripts/subagent.sh`) wraps the tmux mechanics. All commands return immediately unless noted.

| Command | Description |
|---------|-------------|
| `subagent spawn <agent> [--name <name>] [--cwd <dir>] [--model <m>] "<task>"` | Spawn a sub-agent in a new tmux pane. Returns the pane id and name. |
| `subagent poll <name> [--timeout <sec>]` | Poll for completion sentinel. Blocks until done or timeout. Returns exit code. |
| `subagent output <name>` | Print the sub-agent's captured output (final assistant message). |
| `subagent status` | List all known subagents with state and elapsed time. |
| `subagent kill <name>` | Kill the pane and mark as killed. |
| `subagent resume <name> "<message>"` | Resume a finished sub-agent with a follow-up message in the same pane. |
| `subagent steer <name> "<message>"` | Send a message to a running interactive sub-agent's pane. |

If the helper script is not installed, the orchestrator can use raw tmux commands directly (see [Raw tmux Protocol](#raw-tmux-protocol)).

---

## Core Protocol

### Phase 0: Pre-Flight

Before spawning, verify the environment:

```bash
# Must be inside tmux
test -n "$TMUX_PANE" || { echo "Not in tmux. Start with: tmux new -A -s opencode 'opencode'"; exit 1; }
command -v opencode >/dev/null 2>&1 || { echo "opencode not found"; exit 1; }
```

### Phase 1: Spawn

```bash
# Using the helper script (recommended)
subagent spawn scout --name recon --cwd src/auth "Map the authentication module: files, types, entry points"

# Spawn multiple in parallel (each returns immediately)
subagent spawn scout --name api-map "Map the REST API surface and handlers"
subagent spawn researcher --name lib-check "Find the idiomatic way to do X in library Y"
```

What happens under the hood:

1. Create a right-split pane off the parent: `tmux split-window -d -h -t "$TMUX_PANE" -P -F '#{pane_id}'`
2. Wait for shell ready: `sleep 0.5` (raise with `SUBAGENT_SHELL_READY_DELAY_MS=2500` if commands get dropped)
3. Write the launch command to a temp script (avoids tmux line-wrapping for long tasks)
4. Send: `tmux send-keys -t <pane> -l 'bash /tmp/subagent-<name>-<id>.sh'` then `Enter`
5. Record name -> pane mapping in the registry

The launch script runs:

```bash
opencode run --agent scout --auto --format json --dir "<cwd>" "<task>" > "<output_file>" 2>&1
echo "__SUBAGENT_DONE_$?__"
```

### Phase 2: Monitor

After spawning, keep working in the main session. Sub-agents run independently. To check status:

```bash
subagent status
#  scout  recon        running   7m   %12
#  scout  api-map      running   3m   %14
#  scout  lib-check    done      5m   %15  exit=0
```

To block-wait for a specific sub-agent:

```bash
subagent poll recon --timeout 300
# Returns when the sentinel is detected or timeout expires
```

Detection works by reading the pane screen for the sentinel:

```bash
tmux capture-pane -p -t "<pane>" -S -5 | grep -o '__SUBAGENT_DONE_[0-9]*__'
```

### Phase 3: Collect

When a sub-agent completes, read its output:

```bash
subagent output recon
# Prints the sub-agent's final assistant message (parsed from JSON output)
```

If the sub-agent failed (non-zero exit code), the output includes the error. The orchestrator decides whether to retry, resume, or change approach.

### Phase 4: Follow-Up

To send a follow-up message to a **finished** sub-agent (resumes its session):

```bash
subagent resume recon "Also check the middleware stack for auth header propagation"
```

This spawns `opencode run -c -s <session-id> --auto "<follow-up>"` in the same pane. The session continues with full context from the prior run. Fire-and-forget: the result arrives when the follow-up completes.

### Phase 5: Interactive Mode (optional)

For a sub-agent the user wants to drive directly (not autonomous):

```bash
# Launch opencode TUI in a new pane (not headless)
subagent spawn worker --name debugger --interactive "Debug the failing test in auth.test.ts"
```

The pane opens with `opencode --agent worker`. The user can type into it directly. The orchestrator does not poll for completion -- the user exits the pane when done. Use `subagent steer <name> "<msg>"` to inject a message from the orchestrator:

```bash
subagent steer debugger "Try checking the mock setup first"
```

### Phase 6: Close

Finished panes are closed automatically by the helper script after output is collected. To manually close:

```bash
subagent kill recon
```

---

## Parallel Spawns

Emit multiple `subagent spawn` calls in a single turn. They run concurrently in separate panes. The helper script debounces layout rebalancing (`tmux select-layout -t "$TMUX_PANE" even-horizontal`) so a burst of spawns collapses into one resize.

After dispatching parallel subagents, state what you are waiting for and stop the turn. Do not poll in a loop. Check `subagent status` when you need an update, or `subagent poll <name>` to block on a specific one.

---

## Raw tmux Protocol

If the helper script is unavailable, use these raw commands:

### Spawn

```bash
PANE=$(tmux split-window -d -h -t "$TMUX_PANE" -P -F '#{pane_id}')
sleep 0.5
OUTPUT_FILE="/tmp/subagent-output-$(date +%s).jsonl"
cat > "/tmp/subagent-launch-$PANE.sh" << EOF
#!/bin/bash
opencode run --agent scout --auto --format json --dir "$(pwd)" "task text here" > "$OUTPUT_FILE" 2>&1
echo "__SUBAGENT_DONE_\\\$?__"
EOF
chmod +x "/tmp/subagent-launch-$PANE.sh"
tmux send-keys -t "$PANE" -l "bash /tmp/subagent-launch-$PANE.sh"
tmux send-keys -t "$PANE" Enter
```

### Poll

```bash
tmux capture-pane -p -t "$PANE" -S -5 | grep -o '__SUBAGENT_DONE_[0-9]*__'
```

### Collect

```bash
# Read the last assistant message from JSON output
tail -n 20 "$OUTPUT_FILE" | grep '"role":"assistant"' | tail -1
# Or read the full file
cat "$OUTPUT_FILE"
```

### Kill

```bash
tmux kill-pane -t "$PANE"
tmux select-layout -t "$TMUX_PANE" even-horizontal
```

---

## Context Protection Strategy

Subagents exist to protect your context window. The orchestrator receives only the summary, never the raw file contents or intermediate steps.

### When to dispatch a scout vs. read directly

Dispatch a scout when:
- The task names a feature/area but not specific files ("fix the auth flow")
- You would need to grep + read 5+ files just to orient
- You only need to know *where* something lives or *what shape* it has

Read directly when:
- The task gives explicit file paths
- You already know the file you need to edit
- You need exact bytes for an edit (scouts return summaries, not verbatim source)

A good rhythm: **scout to find, read to edit.**

### When to dispatch a researcher vs. webfetch directly

Dispatch a researcher when:
- The question is open-ended ("what is the idiomatic way to X in Y")
- You would need to search + read 3+ pages to triangulate
- You want sources synthesized, not raw HTML

Fetch directly when:
- You already have the exact URL
- You need a single specific piece of information from one page

---

## Claude Code Variant

Claude Code can be used as the sub-agent runtime instead of opencode. The main differences:

| Feature | opencode | Claude Code |
|---------|----------|-------------|
| Headless run | `opencode run --auto "<task>"` | `claude --dangerously-skip-permissions -p "<task>"` |
| Agent selection | `--agent <name>` | `--agent <name>` (or system prompt) |
| Resume session | `opencode run -c -s <id> "<msg>"` | `claude --resume <id> -p "<msg>"` |
| Output format | `--format json` | `--output-format json` |
| Agent definitions | `.opencode/agents/*.md` | `.claude/agents/*.md` |

To use Claude Code as the sub-agent runtime, set the `SUBAGENT_CLI` environment variable before spawning:

```bash
export SUBAGENT_CLI=claude
subagent spawn scout "Map the auth module"
```

The helper script detects `SUBAGENT_CLI=claude` and builds the `claude` command instead of `opencode run`.

---

## Integration Guide

### opencode

1. Install agent definitions:

```bash
mkdir -p ~/.config/opencode/agents
cp .ai-agents/skills/examples/tmux-subagents/*.md ~/.config/opencode/agents/
```

2. Install the helper script:

```bash
cp .scripts/subagent.sh ~/.local/bin/subagent
chmod +x ~/.local/bin/subagent
```

3. Add this skill to `opencode.json` instructions:

```json
{
  "instructions": [
    ".ai-agents/skills/tmux-subagents.md"
  ]
}
```

4. Start opencode inside tmux:

```bash
tmux new -A -s opencode 'opencode'
```

### Claude Code

1. Symlink the skill:

```bash
mkdir -p .claude/skills/tmux-subagents
ln -s ~/code/dotfiles/.ai-agents/skills/tmux-subagents.md .claude/skills/tmux-subagents/SKILL.md
```

2. Install agent definitions to `.claude/agents/` (adapt frontmatter to Claude Code format).

3. Start Claude Code inside tmux:

```bash
tmux new -A -s claude 'claude'
```

---

## Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Poll in a loop burning turns | Spawn, state what you are waiting for, stop. Check `subagent status` when needed. |
| Read 20 files inline to find one pattern | Dispatch a scout. Receive a structured map. |
| Serialize independent investigations | Spawn parallel subagents in the same turn. |
| Send a multi-line task via raw send-keys | Use the helper script (writes to a temp .sh file to avoid line wrapping). |
| Forget to verify `$TMUX_PANE` | Always run Phase 0 pre-flight before spawning. |
| Spawn a subagent for a 1-file lookup | Read the file directly. Subagents have overhead. |
| Assume the subagent finished | Check for the sentinel explicitly via `subagent poll` or `subagent status`. |
