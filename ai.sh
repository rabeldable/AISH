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
  input="$*"
  log_history "@" "$input"

  # Build prompt with optional system prefix
  prompt="${AI_SYSTEM_PROMPT:+$AI_SYSTEM_PROMPT\n}$input"

  # Route to active vendor
  case "$ACTIVE_AI" in
    openai)
      response=$(ai_openai "$prompt")
      ;;
    gemini)
      response=$(ai_gemini "$prompt")
      ;;
    meta)
      response=$(ai_meta "$prompt")
      ;;
    *)
      echo "❌ Unknown ACTIVE_AI: $ACTIVE_AI"
      return 1
      ;;
  esac

  # Security check
  check_response_security "$response"
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
alias /='search_history'
