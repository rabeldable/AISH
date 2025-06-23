#!/bin/bash

log_history() {
  local prefix="$1"  # '@' or '%'
  local input="$2"
  local timestamp=$(date --iso-8601=seconds)

  mkdir -p "$(dirname "$AI_HISTORY_FILE")"
  echo "{"timestamp": "$timestamp", "type": "$prefix", "input": "$input"}" >> "$AI_HISTORY_FILE"
}
