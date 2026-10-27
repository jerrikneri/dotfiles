# Safe Homebrew upgrade: holds back formulas/casks whose current version has
# been in homebrew-core / homebrew-cask for less than BREW_MIN_AGE_DAYS days,
# to mitigate 0-day supply-chain risk. Mirrors the "wait N days" pattern some
# people apply to npm updates.
#
# Age source: GitHub commits API for the formula/cask .rb file. The oldest
# recent commit whose message contains the current version approximates when
# that version was introduced.
#
# Env:
#   BREW_MIN_AGE_DAYS                   minimum days available (default 7)
#   GITHUB_TOKEN / HOMEBREW_GITHUB_API_TOKEN   raises API rate limit (optional)
# Usage:
#   brewu-safe                       upgrade aged, hold new, then cleanup
#   brewu-safe --dry-run             preview only (no update/upgrade/cleanup)
#   brewu-safe --min-age 14          custom threshold
#   brewu-safe --no-casks            formulae only
#   brewu-safe --only ripgrep        check one package
#   brewu-safe --allow-on-failure    upgrade even when age can't be verified (risky)

brewu-safe() {
  local min_age="${BREW_MIN_AGE_DAYS:-7}"
  local dry_run=0
  local do_casks=1
  local only=""
  local allow_on_failure=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --min-age) min_age="$2"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      --no-casks) do_casks=0; shift ;;
      --only) only="$2"; shift 2 ;;
      --allow-on-failure) allow_on_failure=1; shift ;;
      -h|--help)
        echo "Usage: brewu-safe [--min-age N] [--dry-run] [--no-casks]"
        echo "                   [--only <name>] [--allow-on-failure]"
        echo "Env:   BREW_MIN_AGE_DAYS (default 7), GITHUB_TOKEN (optional)"
        return 0 ;;
      *) echo "Error: unknown option: $1" >&2; return 1 ;;
    esac
  done

  command -v brew >/dev/null 2>&1 || { echo "Error: brew required" >&2; return 1; }
  command -v curl >/dev/null 2>&1 || { echo "Error: curl required" >&2; return 1; }
  command -v python3 >/dev/null 2>&1 || { echo "Error: python3 required" >&2; return 1; }

  local gh_token="${GITHUB_TOKEN:-${HOMEBREW_GITHUB_API_TOKEN:-}}"
  local rate_limited=0
  local upgraded=() held=() skipped_pinned=() failed=()

  # ISO date -> integer days since now
  _brewu_age_days() {
    python3 -c 'import sys,datetime
d=datetime.datetime.strptime(sys.argv[1],"%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
print(int((datetime.datetime.now(datetime.timezone.utc)-d).total_seconds()//86400))' "$1"
  }

  # Query GitHub commits for a formula/cask file and find the oldest commit
  # whose message contains the current version. Prints one of:
  #   DATE:<iso>  - matched, use this date
  #   NONE        - history exists but version not in recent window (=> aged)
  #   EMPTY       - no history found (=> unverified, hold)
  #   APIERROR:<msg> | ERROR
  _brewu_version_date() {
    local repo="$1" file_path="$2" version="$3"
    local curl_args=( -s --max-time 15 -H "Accept: application/vnd.github+json" )
    [ -n "$gh_token" ] && curl_args+=( -H "Authorization: Bearer $gh_token" )
    local body
    body=$(curl "${curl_args[@]}" \
      "https://api.github.com/repos/${repo}/commits?path=${file_path}&per_page=30")
    printf '%s' "$body" | python3 -c 'import sys,json
v=sys.argv[1]
try: d=json.load(sys.stdin)
except Exception: print("ERROR");sys.exit(0)
if isinstance(d,dict) and d.get("message"): print("APIERROR:"+str(d.get("message"))[:80]);sys.exit(0)
if not isinstance(d,list): print("ERROR");sys.exit(0)
if len(d)==0: print("EMPTY");sys.exit(0)
m=[]
for c in d:
    msg=(c.get("commit",{}).get("message") or "")
    msg=msg.splitlines()[0] if msg else ""
    dt=c.get("commit",{}).get("author",{}).get("date") or c.get("commit",{}).get("committer",{}).get("date")
    if dt and v in msg: m.append(dt)
print("DATE:"+sorted(m)[0]) if m else print("NONE")' "$version"
  }

  if [ "$dry_run" -eq 0 ]; then
    echo "==> brew update"
    brew update || { echo "Error: brew update failed" >&2; return 1; }
  fi

  local outdated_json
  outdated_json=$(brew outdated --json=v2 2>/dev/null)
  if [ -z "$outdated_json" ]; then
    echo "Error: brew outdated failed" >&2
    return 1
  fi

  # Flatten to "kind|name|current_version|pinned" (kind = formula|cask)
  local entries
  entries=$(printf '%s' "$outdated_json" | python3 -c 'import sys,json
d=json.load(sys.stdin)
for kind in ("formulae","casks"):
    for e in d.get(kind,[]):
        print(kind[:-1]+"|"+e["name"]+"|"+str(e.get("current_version",""))+"|"+("1" if e.get("pinned") else "0"))')

  if [ -z "$entries" ]; then
    echo "Nothing outdated."
    [ "$dry_run" -eq 0 ] && brew cleanup
    return 0
  fi

  local kind name version pinned first repo file_path result iso age rest line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    kind="${line%%|*}"; rest="${line#*|}"
    name="${rest%%|*}"; rest="${rest#*|}"
    version="${rest%%|*}"; pinned="${rest#*|}"

    if [ "$kind" = "cask" ] && [ "$do_casks" -eq 0 ]; then continue; fi
    if [ -n "$only" ] && [ "$only" != "$name" ]; then continue; fi
    if [ "$pinned" = "1" ]; then skipped_pinned+=("$name"); continue; fi

    first="${name:0:1}"
    if [ "$kind" = "formula" ]; then
      repo="Homebrew/homebrew-core"; file_path="Formula/${first}/${name}.rb"
    else
      repo="Homebrew/homebrew-cask"; file_path="Casks/${first}/${name}.rb"
    fi

    if [ "$rate_limited" -eq 1 ]; then
      result="APIERROR:rate-limited earlier"
    else
      result=$(_brewu_version_date "$repo" "$file_path" "$version")
      case "$result" in
        APIERROR:*)
          if [[ "$result" == *"rate limit"* || "$result" == *"rate-limited"* ]]; then
            rate_limited=1
            echo "Warning: GitHub API rate limit hit; holding remaining packages." >&2
          else
            echo "Warning: API error for $name ($result)" >&2
          fi
          ;;
      esac
    fi

    age=""
    case "$result" in
      DATE:*)
        iso="${result#DATE:}"
        age=$(_brewu_age_days "$iso")
        ;;
      NONE)
        age="$((min_age + 1))"
        ;;
      *)
        # EMPTY / APIERROR / ERROR -> unverified
        if [ "$allow_on_failure" -eq 1 ]; then
          age="$((min_age + 1))"
        else
          age=""
        fi
        ;;
    esac

    if [ -z "$age" ]; then
      failed+=("$name")
      echo "?? skipping $kind $name $version (age unverified)"
      continue
    fi

    if [ "$age" -ge "$min_age" ]; then
      if [ "$dry_run" -eq 1 ]; then
        echo "[dry-run] upgrade $kind $name $version (age ${age}d >= ${min_age}d)"
      else
        echo "==> upgrade $kind $name $version (age ${age}d)"
        if [ "$kind" = "cask" ]; then
          brew upgrade --cask "$name" && upgraded+=("$name") || failed+=("$name")
        else
          brew upgrade "$name" && upgraded+=("$name") || failed+=("$name")
        fi
      fi
    else
      held+=("$name $version (${age}d)")
      if [ "$dry_run" -eq 1 ]; then
        echo "[dry-run] HOLD   $kind $name $version (age ${age}d < ${min_age}d)"
      else
        echo "-- hold   $kind $name $version (age ${age}d < ${min_age}d)"
      fi
    fi
    sleep 0.2
  done < <(printf '%s\n' "$entries")

  echo
  echo "Summary (min-age ${min_age}d):"
  echo "  upgraded: ${#upgraded[@]}"
  echo "  held:     ${#held[@]}"
  [ ${#skipped_pinned[@]} -gt 0 ] && echo "  pinned:   ${#skipped_pinned[@]} (${skipped_pinned[*]})"
  [ ${#failed[@]} -gt 0 ] && echo "  unverified: ${#failed[@]} (${failed[*]})"
  if [ ${#held[@]} -gt 0 ]; then echo "  held list:"; printf '    %s\n' "${held[@]}"; fi

  if [ "$dry_run" -eq 0 ] && [ ${#upgraded[@]} -gt 0 ]; then
    echo "==> brew cleanup"
    brew cleanup
  fi
}
