#!/bin/bash

# Context file lives in workspace
get_context_file() {
  echo "$AI_WORKSPACE_DIR/context.json"
}

add_context() {
  local addition="$1"
  local context_file=$(get_context_file)
  mkdir -p "$(dirname "$context_file")"
  echo "[$(date --iso-8601=seconds)] $addition" >> "$context_file"
  echo "✅ Context added."
}

read_context() {
  local context_file=$(get_context_file)
  if [[ -f "$context_file" ]]; then
    cat "$context_file"
  else
    echo "No context found."
  fi
}

inject_context_into_prompt() {
  local prompt="$1"
  local context_file=$(get_context_file)
  if [[ -f "$context_file" ]]; then
    local ctx=$(cat "$context_file")
    echo -e "$ctx\n$prompt"
  else
    echo "$prompt"
  fi
}
