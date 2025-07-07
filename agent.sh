#!/bin/bash

# Predefined % command map
declare -A AGENT_COMMANDS=(
  ["analyze"]="analyze_log_file"
  ["summarize"]="summarize_file"
  ["status"]="system_status_check"
  ["deploy"]="run_deploy_script"
)

# Entry point for all % commands
agent_cli() {
  local cmd="$1"; shift

  if [[ -z "${AGENT_COMMANDS[$cmd]}" ]]; then
    echo "❌ Unknown command: $cmd"
    return 1
  fi

  local handler="${AGENT_COMMANDS[$cmd]}"
  "$handler" "$@"
}

# --- Handlers ---

# AI analysis of a log file
analyze_log_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"; return 1
  fi
  local data=$(tail -n 50 "$file")
  ai "Analyze the following log file for warnings, errors, or trends:\n\n$data"
}

# AI summary of a text file
summarize_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"; return 1
  fi
  local content=$(< "$file")
  ai "Summarize the following content:\n\n$content"
}

# Mixed shell + AI
system_status_check() {
  local stats="$(uptime; df -h /)"
  ai "Give a quick health check summary for this system output:\n\n$stats"
}

# Pure shell command
run_deploy_script() {
  echo "🚀 Running deploy script..."
  bash ./deploy.sh --no-cache
}

