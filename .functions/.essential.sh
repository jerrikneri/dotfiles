# Git
gclb() {
  git fetch -p &&
  for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do
    git branch -D "$branch"
  done
}

gwt() {
  local folder_name="$1"
  local branch="$2"
  local base_ref="$3"
  local target_dir
  local repo_root

  if [ -z "$folder_name" ] || [ -z "$branch" ]; then
    echo "Usage: gwt <folder-name> <branch> [base-ref]" >&2
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: current directory is not a git repository." >&2
    return 1
  fi

  repo_root="$(git rev-parse --show-toplevel)" || return 1
  target_dir="../worktree/$folder_name"

  if [ -d "$target_dir" ] && [ -n "$(ls -A "$target_dir" 2>/dev/null)" ]; then
    echo "Error: target directory exists and is not empty: $target_dir" >&2
    return 1
  fi

  git fetch --all --prune || return 1

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$target_dir" "$branch" || return 1
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git worktree add --track -b "$branch" "$target_dir" "origin/$branch" || return 1
  else
    if [ -z "$base_ref" ]; then
      if git show-ref --verify --quiet "refs/remotes/origin/main"; then
        base_ref="origin/main"
      elif git show-ref --verify --quiet "refs/heads/main"; then
        base_ref="main"
      else
        base_ref="HEAD"
      fi
    fi

    if ! git rev-parse --verify --quiet "${base_ref}^{commit}" >/dev/null; then
      echo "Error: base ref not found: $base_ref" >&2
      return 1
    fi

    git worktree add -b "$branch" "$target_dir" "$base_ref" || return 1
  fi

  echo "Worktree ready: $target_dir"
  echo "Branch: $branch"
  echo "Next: cd \"$target_dir\""
}

gwt-rm() {
  local target="$1"
  local mode="${2:-}"
  local repo_root
  local path=""
  local default_layout_path=""
  local current_path=""
  local current_branch=""

  if [ -z "$target" ]; then
    echo "Usage: gwt-rm <folder-name|worktree-path|branch> [--force]" >&2
    return 1
  fi

  if [ -n "$mode" ] && [ "$mode" != "--force" ]; then
    echo "Error: unknown option '$mode'" >&2
    echo "Usage: gwt-rm <folder-name|worktree-path|branch> [--force]" >&2
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: current directory is not a git repository." >&2
    return 1
  fi

  repo_root="$(git rev-parse --show-toplevel)" || return 1

  default_layout_path="../worktree/$target"

  if [ -d "$target" ]; then
    path="$target"
  elif [ -d "$default_layout_path" ]; then
    path="$default_layout_path"
  else
    while IFS= read -r line; do
      case "$line" in
        worktree\ *)
          current_path="${line#worktree }"
          ;;
        branch\ refs/heads/*)
          current_branch="${line#branch refs/heads/}"
          if [ "$current_branch" = "$target" ]; then
            path="$current_path"
            break
          fi
          ;;
      esac
    done < <(git worktree list --porcelain)
  fi

  if [ -z "$path" ]; then
    echo "Error: could not find worktree for '$target'." >&2
    return 1
  fi

  if [ "$(cd "$repo_root" 2>/dev/null && pwd -P)" = "$(cd "$path" 2>/dev/null && pwd -P)" ]; then
    echo "Error: refusing to remove the primary worktree: $path" >&2
    return 1
  fi

  if [ ! -d "$path" ]; then
    echo "Worktree path no longer exists on disk: $path"
    git worktree prune || return 1
    echo "Pruned stale worktree metadata."
    return 0
  fi

  if [ "$mode" != "--force" ] && [ -n "$(git -C "$path" status --porcelain 2>/dev/null)" ]; then
    echo "Error: worktree has uncommitted changes: $path" >&2
    echo "Use --force to remove it anyway." >&2
    return 1
  fi

  if [ "$mode" = "--force" ]; then
    git worktree remove --force "$path" || return 1
  else
    git worktree remove "$path" || return 1
  fi

  git worktree prune || return 1
  echo "Removed worktree: $path"
  echo "Pruned stale worktree metadata."
}

# Processes | PID
kp() {
  if [ -z "$1" ]
  then
    echo "Process name required."
  else
    kill -9 `ps aux | grep $1 | awk '{print $2}'`
  fi
}
