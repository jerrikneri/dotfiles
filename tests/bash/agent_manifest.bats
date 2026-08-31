#!/usr/bin/env bats

setup() {
  DOTFILES_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_TMPDIR="$(mktemp -d)"
  FAKE_HOME="$TEST_TMPDIR/home"
  FAKE_PROJECT="$TEST_TMPDIR/project"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "--help exits 0 with usage" {
  run bash "$DOTFILES_ROOT/.scripts/agent_manifest.sh" --help
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q 'Usage'
}

@test "missing dirs are skipped without error" {
  run bash "$DOTFILES_ROOT/.scripts/agent_manifest.sh" \
    --home "$TEST_TMPDIR/no-home" --project "$TEST_TMPDIR/no-project"
  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q '# summary'
}

@test "scans fixtures: flags, symlink resolution, JSONC config parsing" {
  command -v jq >/dev/null 2>&1 || skip "jq not installed"

  mkdir -p "$FAKE_HOME/.config/opencode" \
    "$FAKE_HOME/.claude/skills/withfm" \
    "$FAKE_HOME/.claude/skills/nofm" \
    "$FAKE_PROJECT/.ai-agents/skills/src-skill"

  printf -- '---\nname: withfm\ndescription: "has frontmatter"\n---\nbody\n' \
    >"$FAKE_HOME/.claude/skills/withfm/SKILL.md"
  printf '# nofm\n\nbody without frontmatter\n' >"$FAKE_HOME/.claude/skills/nofm/SKILL.md"
  printf -- '---\nname: src-skill\ndescription: "source skill"\n---\nsource\n' \
    >"$FAKE_PROJECT/.ai-agents/skills/src-skill/SKILL.md"
  ln -s "$FAKE_PROJECT/.ai-agents/skills/src-skill" "$FAKE_HOME/.claude/skills/linked"
  ln -s "$TEST_TMPDIR/does-not-exist" "$FAKE_HOME/.claude/skills/orphan"

  printf '{\n  // commented entry\n  "instructions": ["AGENTS.md"],\n  "mcp": { "demo": { "type": "local", "command": ["echo"] } }\n}\n' \
    >"$FAKE_HOME/.config/opencode/opencode.json"
  printf '# agents\n' >"$FAKE_PROJECT/AGENTS.md"

  run bash "$DOTFILES_ROOT/.scripts/agent_manifest.sh" \
    --home "$FAKE_HOME" --project "$FAKE_PROJECT"

  [ "$status" -eq 0 ]
  printf '%s\n' "$output" | grep -q $'category\tname\tharness'
  printf '%s\n' "$output" | grep -q $'skill\twithfm\tclaude-global'
  printf '%s\n' "$output" | grep -q 'no-frontmatter'
  printf '%s\n' "$output" | grep -q 'orphan-symlink'
  printf '%s\n' "$output" | grep -q 'missing-skmd'
  printf '%s\n' "$output" | grep -q "$FAKE_PROJECT/.ai-agents/skills/src-skill"
  printf '%s\n' "$output" | grep -q $'instruction-file\tAGENTS.md'
  printf '%s\n' "$output" | grep -q $'mcp\tdemo\t'
  printf '%s\n' "$output" | grep -q '# summary'
}

@test "git dates resolve through symlinked config dirs" {
  command -v git >/dev/null 2>&1 || skip "git not installed"

  REPO="$TEST_TMPDIR/repo"
  mkdir -p "$REPO/.config/opencode/commands"
  printf -- '---\ndescription: "d"\n---\nbody\n' >"$REPO/.config/opencode/commands/foo.md"
  git init -q "$REPO"
  git -C "$REPO" config user.email test@test.invalid
  git -C "$REPO" config user.name test
  git -C "$REPO" add -A
  git -C "$REPO" commit -qm init
  mkdir -p "$FAKE_HOME/.config"
  ln -s "$REPO/.config/opencode" "$FAKE_HOME/.config/opencode"

  run bash "$DOTFILES_ROOT/.scripts/agent_manifest.sh" \
    --home "$FAKE_HOME" --project "$TEST_TMPDIR/empty-project"

  [ "$status" -eq 0 ]
  commit_date="$(git -C "$REPO" log -1 --format=%cs)"
  printf '%s\n' "$output" | grep $'command\tfoo\topencode-global' | grep -q "$commit_date"
}

@test "read-only: modifies nothing under scanned dirs" {
  command -v jq >/dev/null 2>&1 || skip "jq not installed"

  mkdir -p "$FAKE_HOME/.claude/skills/ok" "$FAKE_HOME/.config/opencode" "$FAKE_PROJECT"
  printf -- '---\nname: ok\ndescription: "d"\n---\nbody\n' \
    >"$FAKE_HOME/.claude/skills/ok/SKILL.md"
  printf '{"instructions": []}\n' >"$FAKE_HOME/.config/opencode/opencode.json"

  touch "$TEST_TMPDIR/checkpoint"

  run bash "$DOTFILES_ROOT/.scripts/agent_manifest.sh" \
    --home "$FAKE_HOME" --project "$FAKE_PROJECT"

  [ "$status" -eq 0 ]
  modified="$(find "$FAKE_HOME" "$FAKE_PROJECT" -newer "$TEST_TMPDIR/checkpoint" -print 2>/dev/null)"
  [ -z "$modified" ]
}
