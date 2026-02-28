#!/usr/bin/env bats

setup() {
  DOTFILES_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TEST_TMPDIR="$(mktemp -d)"
  REPO_DIR="$TEST_TMPDIR/repo"

  mkdir -p "$REPO_DIR"
  git -C "$REPO_DIR" init -q
  git -C "$REPO_DIR" config user.name "Dotfiles Test"
  git -C "$REPO_DIR" config user.email "dotfiles-test@example.com"

  printf "hello\n" > "$REPO_DIR/README.md"
  git -C "$REPO_DIR" add README.md
  git -C "$REPO_DIR" commit -qm "initial"
  git -C "$REPO_DIR" branch -M main
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "gwt returns usage error without required params" {
  run env DOTFILES_ROOT="$DOTFILES_ROOT" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; gwt'

  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: gwt"* ]]
}

@test "gwt creates a new worktree from local main by default" {
  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt "test-folder" "feature/test"'

  [ "$status" -eq 0 ]
  [ -d "$TEST_TMPDIR/worktree/test-folder" ]

  branch_name="$(git -C "$TEST_TMPDIR/worktree/test-folder" branch --show-current)"
  [ "$branch_name" = "feature/test" ]
}

@test "gwt-rm blocks dirty worktree unless forced" {
  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt "dirty-folder" "feature/dirty"'
  [ "$status" -eq 0 ]

  printf "dirty\n" >> "$TEST_TMPDIR/worktree/dirty-folder/README.md"

  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt-rm "feature/dirty"'
  [ "$status" -eq 1 ]
  [[ "$output" == *"uncommitted changes"* ]]

  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt-rm "feature/dirty" --force'
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_TMPDIR/worktree/dirty-folder" ]
}

@test "gwt-rm removes worktree by path under new default layout" {
  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt "path-folder" "feature/path"'
  [ "$status" -eq 0 ]

  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt-rm "../worktree/path-folder"'
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_TMPDIR/worktree/path-folder" ]
}

@test "gwt-rm removes worktree by folder name under default layout" {
  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt "folder-rm" "feature/folder-rm"'
  [ "$status" -eq 0 ]

  run env DOTFILES_ROOT="$DOTFILES_ROOT" REPO_DIR="$REPO_DIR" bash -lc 'source "$DOTFILES_ROOT/.functions/.essential.sh"; cd "$REPO_DIR"; gwt-rm "folder-rm"'
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_TMPDIR/worktree/folder-rm" ]
}
