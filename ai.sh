#!/bin/bash

# Load configuration
[ -f "$HOME/.ai_conf" ] && source "$HOME/.ai_conf"

# Load utilities
source "$(dirname "$BASH_SOURCE")/utils/history.sh"
source "$(dirname "$BASH_SOURCE")/utils/security.sh"
source "$(dirname "$BASH_SOURCE")/utils/context.sh"

# Load AI vendor routers
source "$(dirname "$BASH_SOURCE")/vendors/openai.sh"
source "$(dirname "$BASH_SOURCE")/vendors/gemini.sh"
source "$(dirname "$BASH_SOURCE")/vendors/meta.sh"

# Load agent logic
source "$(dirname "$BASH_SOURCE")/agent.sh"

ai() {
  args=("$@")
  # Log the raw input line (joined)
  log_history "@" "${args[*]}"

  system_prompt=""
  user_input=""

  # Determine system prompt from prefix (first arg)
  if [[ "${args[0]}" == "cmd" ]]; then
    system_prompt="$AI_SYSTEM_PROMPT_CMD"
  elif [[ "${args[0]}" == "explain" ]]; then
    system_prompt="$AI_SYSTEM_PROMPT_EXPLAIN"
  else
    system_prompt="$AI_SYSTEM_PROMPT_CMD"
  fi

  # Combine args after prefix as initial input (skip prefix if recognized)
  if [[ "${args[0]}" == "cmd" || "${args[0]}" == "explain" ]]; then
    user_input="${args[@]:1}"
  else
    user_input="${args[@]}"
  fi

  echo "Enter your input. End with a single '.' on a line by itself or press Ctrl-D."

  # Read additional multiline input, append if any
  while IFS= read -r line; do
    [[ "$line" == "." ]] && break
    user_input+=$'\n'"$line"
  done

  # Remove trailing newline if any
  user_input="${user_input%$'\n'}"

  # Build JSON payload for Chat Completion API
  messages_json=$(jq -n --arg sp "$system_prompt" --arg ui "$user_input" --arg model "$OPENAI_MODEL" '
  {
    "model": $model,
    "messages": [
      {"role": "system", "content": $sp},
      {"role": "user", "content": $ui}
    ]
  }')

  # Route to active AI vendor
  case "$ACTIVE_AI" in
    openai)
      response=$(ai_openai "$messages_json")
      ;;
    gemini)
      response=$(ai_gemini "$messages_json")
      ;;
    meta)
      response=$(ai_meta "$messages_json")
      ;;
    *)
      echo "❌ Unknown ACTIVE_AI: $ACTIVE_AI"
      return 1
      ;;
  esac

  # Output AI response
  echo "$response"
}

agent() {
  input="$*"
  log_history "%" "$input"
  run_agent_task "$input"
}

search_history() {
  grep -i "$1" "$AI_HISTORY_FILE"
}

alias @='ai'
alias %='agent'
alias _='search_history'

