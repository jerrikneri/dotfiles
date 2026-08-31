#!/usr/bin/env bats

setup() {
  DOTFILES_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "sync-ai-md symlinks AGENTS.md when missing" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/AGENTS.md" ]
  [ "$(readlink "$TARGET_DIR/AGENTS.md")" = "$DOTFILES_ROOT/AGENTS.md" ]
}

@test "sync-ai-md links AGENTS.local.md and adds reference when AGENTS.md already exists" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  printf "# Project instructions\n" > "$TARGET_DIR/AGENTS.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/AGENTS.local.md" ]
  [ "$(readlink "$TARGET_DIR/AGENTS.local.md")" = "$DOTFILES_ROOT/AGENTS.md" ]
  run grep -c "BEGIN DOTFILES AGENTS LOCAL REF" "$TARGET_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "sync-ai-md is idempotent for AGENTS.local reference block" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  printf "# Project instructions\n" > "$TARGET_DIR/AGENTS.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'
  [ "$status" -eq 0 ]

  first_hash="$(shasum "$TARGET_DIR/AGENTS.md" | awk '{print $1}')"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'
  [ "$status" -eq 0 ]

  second_hash="$(shasum "$TARGET_DIR/AGENTS.md" | awk '{print $1}')"
  [ "$first_hash" = "$second_hash" ]

  run grep -c "BEGIN DOTFILES AGENTS LOCAL REF" "$TARGET_DIR/AGENTS.md"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "sync-ai-md leaves AGENTS.md untouched when it is already a symlink" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  ln -s "$TEST_TMPDIR/external_agents.md" "$TARGET_DIR/AGENTS.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/AGENTS.md" ]
  [ "$(readlink "$TARGET_DIR/AGENTS.md")" = "$TEST_TMPDIR/external_agents.md" ]
  [ ! -e "$TARGET_DIR/AGENTS.local.md" ]
}

@test "sync-ai-md leaves .ai-agents untouched when it is already a symlink" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  ln -s "$TEST_TMPDIR/external_ai_agents" "$TARGET_DIR/.ai-agents"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/.ai-agents" ]
  [ "$(readlink "$TARGET_DIR/.ai-agents")" = "$TEST_TMPDIR/external_ai_agents" ]
}

@test "sync-ai-md creates .ai-agents directory structure when missing" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -d "$TARGET_DIR/.ai-agents" ]
  [ -L "$TARGET_DIR/.ai-agents/skills" ]
  [ -L "$TARGET_DIR/.ai-agents/rules" ]
  [ "$(readlink "$TARGET_DIR/.ai-agents/skills")" = "$DOTFILES_ROOT/.ai-agents/skills" ]
  [ "$(readlink "$TARGET_DIR/.ai-agents/rules")" = "$DOTFILES_ROOT/.ai-agents/rules" ]
}

@test "sync-ai-md creates backup when replacing existing AGENTS.local.md" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  echo "# Existing AGENTS.md" > "$TARGET_DIR/AGENTS.md"
  echo "# Old local content" > "$TARGET_DIR/AGENTS.local.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/AGENTS.local.md" ]
  [ -f "$TARGET_DIR/AGENTS.local.md.bkup" ]
  grep -q "Old local content" "$TARGET_DIR/AGENTS.local.md.bkup"
}

@test "sync-ai-md creates timestamped backup when .bkup already exists" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  echo "# Existing AGENTS.md" > "$TARGET_DIR/AGENTS.md"
  echo "# First version" > "$TARGET_DIR/AGENTS.local.md"
  echo "# Old backup" > "$TARGET_DIR/AGENTS.local.md.bkup"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  # Should have original .bkup and a new timestamped one
  [ -f "$TARGET_DIR/AGENTS.local.md.bkup" ]
  run find "$TARGET_DIR" -name "AGENTS.local.md.bkup.*" -type f
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "sync-ai-md merges .agentsignore patterns into .gitignore" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  echo "node_modules/" > "$TARGET_DIR/.gitignore"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -f "$TARGET_DIR/.gitignore" ]
  grep -q "node_modules/" "$TARGET_DIR/.gitignore"
  grep -q ".env" "$TARGET_DIR/.gitignore"
}

@test "sync-ai-md creates .gitignore with patterns when missing" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -f "$TARGET_DIR/.gitignore" ]
  grep -q ".env" "$TARGET_DIR/.gitignore"
}

@test "sync-ai-md skips duplicate patterns in .gitignore" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  printf ".env\nnode_modules/\n" > "$TARGET_DIR/.gitignore"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  # Count occurrences of .env - should be exactly 1
  run grep -c "^.env$" "$TARGET_DIR/.gitignore"
  [ "$output" -eq 1 ]
}

@test "sync-ai-md handles missing DOTFILES environment variable" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"

  # Create a minimal test script that sources the function and runs it without DOTFILES
  cat > "$TEST_TMPDIR/test_no_dotfiles.sh" << 'EOF'
#!/bin/bash
source "$1/.functions/.ai.sh"
unset DOTFILES
sync-ai-md "$2"
EOF
  chmod +x "$TEST_TMPDIR/test_no_dotfiles.sh"

  run bash "$TEST_TMPDIR/test_no_dotfiles.sh" "$DOTFILES_ROOT" "$TARGET_DIR"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "DOTFILES environment variable not set" ]]
}

@test "sync-ai-md handles non-existent target directory" {
  TARGET_DIR="$TEST_TMPDIR/nonexistent"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR" 2>&1'

  [ "$status" -eq 1 ]
  [[ "$output" =~ "does not exist" ]]
}

@test "sync-ai-md prevents syncing to dotfiles repo itself" {
  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$DOTFILES_ROOT" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$DOTFILES" 2>&1'

  [ "$status" -eq 1 ]
  [[ "$output" =~ "target is the dotfiles repo itself" ]]
}

@test "sync-ai-md skips file replacement when content already matches" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  # Create AGENTS.md first so AGENTS.local.md will be created
  echo "# Project AGENTS" > "$TARGET_DIR/AGENTS.md"
  # Copy the actual AGENTS.md content to simulate matching content
  cp "$DOTFILES_ROOT/AGENTS.md" "$TARGET_DIR/AGENTS.local.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  # Should not create backup since content already matches
  [ ! -f "$TARGET_DIR/AGENTS.local.md.bkup" ]
  [[ "$output" =~ "already synced" ]]
}

@test "sync-ai-md updates symlink when pointing to wrong target" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  mkdir -p "$TARGET_DIR/.ai-agents"
  # Create symlink pointing to wrong location
  ln -s "/some/wrong/path" "$TARGET_DIR/.ai-agents/skills"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -L "$TARGET_DIR/.ai-agents/skills" ]
  [ "$(readlink "$TARGET_DIR/.ai-agents/skills")" = "$DOTFILES_ROOT/.ai-agents/skills" ]
  [[ "$output" =~ "symlink refreshed" ]]
}

@test "sync-ai-md handles .claudeignore and .opencodeignore" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  echo "*.tmp" > "$TARGET_DIR/.claudeignore"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  [ -f "$TARGET_DIR/.claudeignore" ]
  [ -f "$TARGET_DIR/.opencodeignore" ]
  grep -q ".env" "$TARGET_DIR/.claudeignore"
  grep -q ".env" "$TARGET_DIR/.opencodeignore"
  # Original content preserved
  grep -q "*.tmp" "$TARGET_DIR/.claudeignore"
}

@test "sync-ai-md preserves whitespace in AGENTS.md when adding reference" {
  TARGET_DIR="$TEST_TMPDIR/project"
  mkdir -p "$TARGET_DIR"
  # Create AGENTS.md with specific whitespace pattern
  printf "# Project\n\nContent\n\n\n" > "$TARGET_DIR/AGENTS.md"

  run env DOTFILES="$DOTFILES_ROOT" TARGET_DIR="$TARGET_DIR" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-ai-md "$TARGET_DIR"'

  [ "$status" -eq 0 ]
  # Should trim trailing blank lines before adding reference
  ! tail -n2 "$TARGET_DIR/AGENTS.md" | head -n1 | grep -q '^$'
  grep -q "BEGIN DOTFILES AGENTS LOCAL REF" "$TARGET_DIR/AGENTS.md"
}

# ---------------------------------------------------------------------------
# sync-skills
# ---------------------------------------------------------------------------

@test "sync-skills --list shows registered agents" {
  run env DOTFILES="$DOTFILES_ROOT" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills --list'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "claude"
  echo "$output" | grep -q "opencode"
}

@test "sync-skills symlinks each skill dir to the claude target" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/pre-flight" ]
  [ "$(readlink "$FAKE_HOME/.claude/skills/pre-flight")" = "$DOTFILES_ROOT/.ai-agents/skills/pre-flight" ]
  [ -L "$FAKE_HOME/.claude/skills/teach-me" ]
  [ "$(readlink "$FAKE_HOME/.claude/skills/teach-me")" = "$DOTFILES_ROOT/.ai-agents/skills/teach-me" ]
}

@test "sync-skills syncs rules as skills for claude (except permissions)" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/session-management" ]
  [ "$(readlink "$FAKE_HOME/.claude/skills/session-management")" = "$DOTFILES_ROOT/.ai-agents/rules/session-management" ]
  [ -L "$FAKE_HOME/.claude/skills/agent-meta-protocol" ]
  [ ! -e "$FAKE_HOME/.claude/skills/permissions" ]
}

@test "sync-skills does not sync rules for opencode" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills opencode'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.config/opencode/skills/teach-me" ]
  [ ! -e "$FAKE_HOME/.config/opencode/skills/session-management" ]
}

@test "sync-skills --all syncs every registered agent" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills --all'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/teach-me" ]
  [ -L "$FAKE_HOME/.config/opencode/skills/teach-me" ]
}

@test "sync-skills accepts multiple agent args" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude opencode'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/pre-flight" ]
  [ -L "$FAKE_HOME/.config/opencode/skills/pre-flight" ]
}

@test "sync-skills is idempotent on re-run" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME"
  env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude' >/dev/null
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/pre-flight" ]
  [ "$(readlink "$FAKE_HOME/.claude/skills/pre-flight")" = "$DOTFILES_ROOT/.ai-agents/skills/pre-flight" ]
}

@test "sync-skills backs up an existing real skill dir before linking" {
  FAKE_HOME="$TEST_TMPDIR/home"
  mkdir -p "$FAKE_HOME/.claude/skills/pre-flight"
  printf "old project content\n" > "$FAKE_HOME/.claude/skills/pre-flight/SKILL.md"
  run env DOTFILES="$DOTFILES_ROOT" HOME="$FAKE_HOME" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills claude'
  [ "$status" -eq 0 ]
  [ -L "$FAKE_HOME/.claude/skills/pre-flight" ]
  [ -d "$FAKE_HOME/.claude/skills/pre-flight.bkup" ]
}

@test "sync-skills errors on unknown agent" {
  run env DOTFILES="$DOTFILES_ROOT" bash -lc 'source "$DOTFILES/.functions/.ai.sh"; sync-skills nope'
  [ "$status" -ne 0 ]
}

@test "sync-skills errors when DOTFILES is unset" {
  run bash -lc 'unset DOTFILES; source "$(pwd)/.functions/.ai.sh"; sync-skills --list'
  [ "$status" -ne 0 ]
}
