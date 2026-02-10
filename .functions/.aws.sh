#!/bin/bash
# =============================================================================
# AWS CloudWatch Logs Insights CLI Helpers
# =============================================================================
#
# Grep-like searching for AWS CloudWatch Logs from the command line.
# Requires: AWS CLI v2 configured with appropriate permissions
#
# SINGLE LOG GROUP WORKFLOW:
#   awslogfind <pattern>     Find and set a single log group interactively
#   awslogset <log-group>    Set log group directly
#   awslogs <pattern>        Search current log group
#   awslogsq <query>         Run custom Insights query
#   awslogtail [pattern]     Real-time tail (like tail -f)
#
# MULTIPLE LOG GROUPS WORKFLOW:
#   awslogsfind <pattern>    Find and add multiple log groups
#   awslogsadd <log-group>   Add a log group to the list
#   awslogsshow              Show current log groups list
#   awslogsrm <index>        Remove a log group by index
#   awslogsclear             Clear all log groups
#   awslogsm <pattern>       Search across all log groups
#
# UTILITIES:
#   awsloggroups [filter]    List available log groups
#
# ENVIRONMENT VARIABLES:
#   AWS_LOG_GROUP            Single log group for awslogs/awslogsq/awslogtail
#   AWS_LOG_GROUPS           Array of log groups for awslogsm
#
# =============================================================================

# --- Logging Helpers ---

_awslog_info() {
  echo "[info] $1"
}

_awslog_success() {
  echo "[ok] $1"
}

_awslog_warn() {
  echo "[warn] $1"
}

_awslog_error() {
  echo "[error] $1" >&2
}

# Check AWS CLI availability
_awslog_check_cli() {
  if ! command -v aws &> /dev/null; then
    _awslog_error "AWS CLI not found. Install with: brew install awscli"
    return 1
  fi
  return 0
}

# Poll for query results with status updates
_awslog_poll_query() {
  local query_id="$1"
  local status="Running"
  local elapsed=0

  while [ "$status" = "Running" ] || [ "$status" = "Scheduled" ]; do
    sleep 1
    elapsed=$((elapsed + 1))
    printf "\r[info] Query running... %ds" "$elapsed"
    status=$(aws logs get-query-results --query-id "$query_id" --output text --query 'status' 2>/dev/null)
    if [ -z "$status" ]; then
      echo ""
      _awslog_error "Failed to get query status. Check AWS credentials and permissions."
      return 1
    fi
  done
  echo ""

  if [ "$status" = "Complete" ]; then
    local results=$(aws logs get-query-results --query-id "$query_id" --output json 2>/dev/null)
    local count=$(echo "$results" | grep -o '"results"' | wc -l | tr -d ' ')
    count=$(echo "$results" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('results',[])))" 2>/dev/null || echo "?")
    _awslog_success "Query complete. Found $count results in ${elapsed}s."
    aws logs get-query-results --query-id "$query_id" \
      --query 'results[*].[field, value]' --output table
    return 0
  elif [ "$status" = "Failed" ]; then
    _awslog_error "Query failed. Check query syntax and log group permissions."
    return 1
  elif [ "$status" = "Cancelled" ]; then
    _awslog_warn "Query was cancelled."
    return 1
  else
    _awslog_error "Query ended with unexpected status: $status"
    return 1
  fi
}

# =============================================================================
# SINGLE LOG GROUP FUNCTIONS
# =============================================================================

# Find and set log group interactively
# Usage: awslogfind <pattern>
# Example: awslogfind my-api
awslogfind() {
  _awslog_check_cli || return 1

  if [ -z "$1" ]; then
    _awslog_error "Missing pattern argument"
    echo "Usage: awslogfind <pattern>"
    echo "Example: awslogfind lambda-api"
    return 1
  fi

  _awslog_info "Searching for log groups matching '$1'..."

  local matches=$(aws logs describe-log-groups \
    --query "logGroups[?contains(logGroupName, '$1')].logGroupName" \
    --output text 2>/dev/null | tr '\t' '\n' | grep .)

  if [ -z "$matches" ]; then
    _awslog_warn "No log groups found matching '$1'"
    echo "Tip: Use 'awsloggroups' to list all available log groups"
    return 1
  fi

  local count=$(echo "$matches" | wc -l | tr -d ' ')

  if [ "$count" -eq 1 ]; then
    export AWS_LOG_GROUP="$matches"
    _awslog_success "AWS_LOG_GROUP set to: $AWS_LOG_GROUP"
    return 0
  fi

  # Multiple matches - let user pick
  _awslog_info "Found $count log groups:"
  echo "$matches" | nl -w2 -s') '
  echo ""
  printf "Select [1-$count]: "
  read selection

  if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
    _awslog_error "Invalid selection: $selection (expected 1-$count)"
    return 1
  fi

  export AWS_LOG_GROUP=$(echo "$matches" | sed -n "${selection}p")
  _awslog_success "AWS_LOG_GROUP set to: $AWS_LOG_GROUP"
}

# Set the default log group directly
# Usage: awslogset <log-group>
# Example: awslogset /aws/lambda/my-func
awslogset() {
  if [ -z "$1" ]; then
    if [ -z "$AWS_LOG_GROUP" ]; then
      _awslog_warn "No log group currently set"
      echo "Usage: awslogset <log-group>"
      echo "Or use: awslogfind <pattern> (interactive)"
    else
      _awslog_info "Current log group: $AWS_LOG_GROUP"
    fi
    return 0
  fi
  export AWS_LOG_GROUP="$1"
  _awslog_success "AWS_LOG_GROUP set to: $AWS_LOG_GROUP"
}

# Quick grep-like search on CloudWatch Logs
# Usage: awslogs <pattern> [hours-back]
# Example: awslogs "ERROR" 24
awslogs() {
  _awslog_check_cli || return 1

  if [ -z "$AWS_LOG_GROUP" ]; then
    _awslog_error "No log group set"
    echo "Set one with: awslogset <log-group>"
    echo "Or find one:  awslogfind <pattern>"
    return 1
  fi

  if [ -z "$1" ]; then
    _awslog_error "Missing search pattern"
    echo "Usage: awslogs <pattern> [hours-back]"
    echo "Example: awslogs \"ERROR\" 24"
    echo ""
    _awslog_info "Current log group: $AWS_LOG_GROUP"
    return 1
  fi

  local pattern="$1"
  local hours="${2:-1}"
  local end_time=$(($(date +%s) * 1000))
  local start_time=$((end_time - (hours * 3600 * 1000)))
  local start_date=$(date -r $((start_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((start_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)
  local end_date=$(date -r $((end_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((end_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)

  local query="fields @timestamp, @message | filter @message like /$pattern/ | sort @timestamp desc | limit 100"

  _awslog_info "Log group: $AWS_LOG_GROUP"
  _awslog_info "Pattern: '$pattern'"
  _awslog_info "Time range: $start_date to $end_date (${hours}h)"

  local query_id=$(aws logs start-query \
    --log-group-name "$AWS_LOG_GROUP" \
    --start-time "$start_time" \
    --end-time "$end_time" \
    --query-string "$query" \
    --output text --query 'queryId' 2>&1)

  if [ -z "$query_id" ] || [[ "$query_id" == *"error"* ]] || [[ "$query_id" == *"Error"* ]]; then
    _awslog_error "Failed to start query"
    echo "$query_id"
    echo ""
    echo "Possible causes:"
    echo "  - Log group does not exist"
    echo "  - Insufficient IAM permissions (logs:StartQuery)"
    echo "  - Invalid query syntax"
    return 1
  fi

  _awslog_poll_query "$query_id"
}

# Run a custom Logs Insights query
# Usage: awslogsq <query> [hours-back]
# Example: awslogsq "fields @message | stats count(*) by bin(5m)" 24
awslogsq() {
  _awslog_check_cli || return 1

  if [ -z "$AWS_LOG_GROUP" ]; then
    _awslog_error "No log group set"
    echo "Set one with: awslogset <log-group>"
    echo "Or find one:  awslogfind <pattern>"
    return 1
  fi

  if [ -z "$1" ]; then
    _awslog_error "Missing query"
    echo "Usage: awslogsq <query> [hours-back]"
    echo "Example: awslogsq \"fields @message | stats count(*) by bin(5m)\" 24"
    return 1
  fi

  local query="$1"
  local hours="${2:-1}"
  local end_time=$(($(date +%s) * 1000))
  local start_time=$((end_time - (hours * 3600 * 1000)))
  local start_date=$(date -r $((start_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((start_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)
  local end_date=$(date -r $((end_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((end_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)

  _awslog_info "Log group: $AWS_LOG_GROUP"
  _awslog_info "Time range: $start_date to $end_date (${hours}h)"

  local query_id=$(aws logs start-query \
    --log-group-name "$AWS_LOG_GROUP" \
    --start-time "$start_time" \
    --end-time "$end_time" \
    --query-string "$query" \
    --output text --query 'queryId' 2>&1)

  if [ -z "$query_id" ] || [[ "$query_id" == *"error"* ]] || [[ "$query_id" == *"Error"* ]]; then
    _awslog_error "Failed to start query"
    echo "$query_id"
    return 1
  fi

  _awslog_poll_query "$query_id"
}

# Tail logs in real-time (like tail -f)
# Usage: awslogtail [filter-pattern]
# Example: awslogtail "ERROR"
awslogtail() {
  _awslog_check_cli || return 1

  if [ -z "$AWS_LOG_GROUP" ]; then
    _awslog_error "No log group set"
    echo "Set one with: awslogset <log-group>"
    echo "Or find one:  awslogfind <pattern>"
    return 1
  fi

  _awslog_info "Tailing: $AWS_LOG_GROUP"
  if [ -n "$1" ]; then
    _awslog_info "Filter: $1"
  fi
  _awslog_info "Press Ctrl+C to stop"
  echo ""

  if [ -z "$1" ]; then
    aws logs tail "$AWS_LOG_GROUP" --follow
  else
    aws logs tail "$AWS_LOG_GROUP" --follow --filter-pattern "$1"
  fi
}

# =============================================================================
# MULTIPLE LOG GROUPS FUNCTIONS
# =============================================================================

# Initialize array if not set
[[ -z "$AWS_LOG_GROUPS" ]] && AWS_LOG_GROUPS=()

# Find log groups by pattern and add all matches
# Usage: awslogsfind <pattern>
# Example: awslogsfind api
awslogsfind() {
  _awslog_check_cli || return 1

  if [ -z "$1" ]; then
    _awslog_error "Missing pattern argument"
    echo "Usage: awslogsfind <pattern>"
    echo "Example: awslogsfind api"
    return 1
  fi

  _awslog_info "Searching for log groups matching '$1'..."

  local matches=$(aws logs describe-log-groups \
    --query "logGroups[?contains(logGroupName, '$1')].logGroupName" \
    --output text 2>/dev/null | tr '\t' '\n' | grep .)

  if [ -z "$matches" ]; then
    _awslog_warn "No log groups found matching '$1'"
    echo "Tip: Use 'awsloggroups' to list all available log groups"
    return 1
  fi

  local count=$(echo "$matches" | wc -l | tr -d ' ')
  _awslog_info "Found $count log groups matching '$1':"
  echo "$matches" | nl -w2 -s') '
  echo ""
  printf "Add all to AWS_LOG_GROUPS? [y/N]: "
  read confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    local added=0
    local skipped=0
    while IFS= read -r group; do
      if [[ ! " ${AWS_LOG_GROUPS[*]} " =~ " ${group} " ]]; then
        AWS_LOG_GROUPS+=("$group")
        added=$((added + 1))
      else
        skipped=$((skipped + 1))
      fi
    done <<< "$matches"
    _awslog_success "Added $added log groups (skipped $skipped duplicates)"
    _awslog_info "Total log groups: ${#AWS_LOG_GROUPS[@]}"
    awslogsshow
  else
    _awslog_info "Cancelled. No log groups added."
  fi
}

# Add a specific log group to the list
# Usage: awslogsadd <log-group>
# Example: awslogsadd /aws/lambda/my-func
awslogsadd() {
  if [ -z "$1" ]; then
    _awslog_error "Missing log group argument"
    echo "Usage: awslogsadd <log-group>"
    return 1
  fi
  if [[ ! " ${AWS_LOG_GROUPS[*]} " =~ " $1 " ]]; then
    AWS_LOG_GROUPS+=("$1")
    _awslog_success "Added: $1"
    _awslog_info "Total log groups: ${#AWS_LOG_GROUPS[@]}"
  else
    _awslog_warn "Already in list: $1"
  fi
}

# Show current log groups list
# Usage: awslogsshow
awslogsshow() {
  if [ ${#AWS_LOG_GROUPS[@]} -eq 0 ]; then
    _awslog_warn "No log groups in AWS_LOG_GROUPS"
    echo "Add some with: awslogsfind <pattern>"
    echo "Or directly:   awslogsadd <log-group>"
    return 0
  fi
  _awslog_info "AWS_LOG_GROUPS (${#AWS_LOG_GROUPS[@]} total):"
  printf '%s\n' "${AWS_LOG_GROUPS[@]}" | nl -w2 -s') '
}

# Clear the log groups list
# Usage: awslogsclear
awslogsclear() {
  local count=${#AWS_LOG_GROUPS[@]}
  AWS_LOG_GROUPS=()
  _awslog_success "Cleared $count log groups from AWS_LOG_GROUPS"
}

# Remove a log group from the list by index
# Usage: awslogsrm <index>
# Example: awslogsrm 2
awslogsrm() {
  if [ -z "$1" ]; then
    _awslog_error "Missing index argument"
    echo "Usage: awslogsrm <index>"
    awslogsshow
    return 1
  fi

  if [ ${#AWS_LOG_GROUPS[@]} -eq 0 ]; then
    _awslog_warn "No log groups to remove"
    return 1
  fi

  local idx=$(($1 - 1))
  if [ $idx -ge 0 ] && [ $idx -lt ${#AWS_LOG_GROUPS[@]} ]; then
    local removed="${AWS_LOG_GROUPS[$idx]}"
    AWS_LOG_GROUPS=("${AWS_LOG_GROUPS[@]:0:$idx}" "${AWS_LOG_GROUPS[@]:$((idx + 1))}")
    _awslog_success "Removed: $removed"
    _awslog_info "Remaining: ${#AWS_LOG_GROUPS[@]} log groups"
  else
    _awslog_error "Invalid index: $1 (valid range: 1-${#AWS_LOG_GROUPS[@]})"
    awslogsshow
    return 1
  fi
}

# Search across multiple log groups
# Usage: awslogsm <pattern> [hours-back]
# Example: awslogsm "ERROR" 24
awslogsm() {
  _awslog_check_cli || return 1

  if [ ${#AWS_LOG_GROUPS[@]} -eq 0 ]; then
    _awslog_error "No log groups in AWS_LOG_GROUPS"
    echo "Add some with: awslogsfind <pattern>"
    echo "Or directly:   awslogsadd <log-group>"
    return 1
  fi

  if [ -z "$1" ]; then
    _awslog_error "Missing search pattern"
    echo "Usage: awslogsm <pattern> [hours-back]"
    echo "Example: awslogsm \"ERROR\" 24"
    echo ""
    awslogsshow
    return 1
  fi

  local pattern="$1"
  local hours="${2:-1}"
  local end_time=$(($(date +%s) * 1000))
  local start_time=$((end_time - (hours * 3600 * 1000)))
  local start_date=$(date -r $((start_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((start_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)
  local end_date=$(date -r $((end_time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$((end_time / 1000))" "+%Y-%m-%d %H:%M" 2>/dev/null)

  local query="fields @timestamp, @logStream, @message | filter @message like /$pattern/ | sort @timestamp desc | limit 100"

  _awslog_info "Searching ${#AWS_LOG_GROUPS[@]} log groups"
  _awslog_info "Pattern: '$pattern'"
  _awslog_info "Time range: $start_date to $end_date (${hours}h)"

  local query_id=$(aws logs start-query \
    --log-group-names "${AWS_LOG_GROUPS[@]}" \
    --start-time "$start_time" \
    --end-time "$end_time" \
    --query-string "$query" \
    --output text --query 'queryId' 2>&1)

  if [ -z "$query_id" ] || [[ "$query_id" == *"error"* ]] || [[ "$query_id" == *"Error"* ]]; then
    _awslog_error "Failed to start query"
    echo "$query_id"
    echo ""
    echo "Possible causes:"
    echo "  - One or more log groups do not exist"
    echo "  - Insufficient IAM permissions (logs:StartQuery)"
    echo "  - Too many log groups (AWS limit: 50)"
    return 1
  fi

  _awslog_poll_query "$query_id"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# List available log groups (with optional filter)
# Usage: awsloggroups [filter]
# Example: awsloggroups lambda
awsloggroups() {
  _awslog_check_cli || return 1

  if [ -z "$1" ]; then
    _awslog_info "Listing all log groups..."
    aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table
  else
    _awslog_info "Listing log groups matching '$1'..."
    local results=$(aws logs describe-log-groups \
      --query "logGroups[?contains(logGroupName, '$1')].logGroupName" \
      --output table 2>/dev/null)
    if [ -z "$results" ] || [[ "$results" == *"None"* ]]; then
      _awslog_warn "No log groups found matching '$1'"
      return 1
    fi
    echo "$results"
  fi
}
