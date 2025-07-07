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

sanitize_line() {
  line="$1"
  # Escape backticks and dollar signs to treat them literally
  line=$(printf '%s' "$line" | sed -e 's/`/\\`/g' -e 's/\$/\\$/g' -e 's/!/\\!/g' -e 's/\*/\\*/g')
  printf '%s' "$line"
}

ai() {
  args=("$@")
  # Log the raw input line (joined)
  log_history "@" "${args[*]}"

  system_prompt=""
  user_input=""

  # Determine system prompt from prefix (first arg)
  if [ "${args[0]}" = "cmd" ]; then
    system_prompt="$AI_SYSTEM_PROMPT_CMD"
  elif [ "${args[0]}" = "explain" ]; then
    system_prompt="$AI_SYSTEM_PROMPT_EXPLAIN"
  else
    system_prompt="$AI_SYSTEM_PROMPT_CMD"
  fi

  # Combine args after prefix as initial input (skip prefix if recognized)
  if [ "${args[0]}" = "cmd" ] || [ "${args[0]}" = "explain" ]; then
    user_input="${args[@]:1}"
  else
    user_input="${args[@]}"
  fi

  echo "Enter your input. End with a single '.' on a line by itself or press Ctrl-D."

  # Read additional multiline input, sanitize and append each line
  while IFS= read -r line; do
    [ "$line" = "." ] && break
    line=$(sanitize_line "$line")
    user_input="$user_input
$line"
  done

  # Remove trailing newline if any
  user_input="${user_input%$'\n'}"

  # Build JSON payload for Chat Completion API
  case "$ACTIVE_AI" in
  openai)
    messages_json=$(jq -n --arg sp "$system_prompt" --arg ui "$user_input" --arg model "$OPENAI_MODEL" '
    {
      "model": $model,
      "messages": [
        {"role": "system", "content": $sp},
        {"role": "user", "content": $ui}
      ]
    }')
    ;;

  gemini)
    # Gemini expects a different payload format
    messages_json=$(jq -n --arg sp "$system_prompt" --arg ui "$user_input" --arg model "$GEMINI_MODEL" '
    {
      "model": $model,
      "system_instruction": {
        "parts": [ { "text": $sp } ]
      },
      "contents": [
        {
          "role": "user",
          "parts": [ { "text": $ui } ]
        }
      ],
      "generationConfig": {
        "thinkingConfig": { "thinkingBudget": 0 },
        "responseMimeType": "text/plain"
      }
    }')
    ;;

  meta)
    # Placeholder for Meta API payload construction
    messages_json="{}"
    ;;

  *)
    echo "Unsupported ACTIVE_AI: $ACTIVE_AI" >&2
    return 1
    ;;
  esac


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


__ai_agent_completions() {
  local cur prev opts keys safe_keys vendors backups
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # All keys including API keys
  keys="ACTIVE_AI AI_RESPONSE_FORMAT OPENAI_API_KEY GEMINI_API_KEY META_API_KEY GEMINI_MODEL META_MODEL OPENAI_MODEL"
  # Keys safe to show (no API keys)
  safe_keys="ACTIVE_AI AI_RESPONSE_FORMAT OPENAI_MODEL GEMINI_MODEL META_MODEL"
  vendors="openai gemini meta"

  # Load model lists dynamically from env (sourced from .ai_conf)
  local openai_models="${OPENAI_MODELS:-}"
  local gemini_models="${GEMINI_MODELS:-}"

  backups=$(ls -1 ~/.ai_conf.backup.* 2>/dev/null || echo "")

  if [[ ${COMP_CWORD} -eq 1 ]]; then
    opts="set show refresh analyze summarize status deploy list unset backup restore"
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    return 0
  fi

  if [[ ${COMP_CWORD} -eq 2 ]]; then
    case "${COMP_WORDS[1]}" in
      set|unset)
        COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
        return 0
        ;;
      show)
        COMPREPLY=( $(compgen -W "$safe_keys" -- "$cur") )
        return 0
        ;;
      restore)
        COMPREPLY=( $(compgen -W "$backups" -- "$cur") )
        return 0
        ;;
    esac
  fi

  if [[ ${COMP_CWORD} -eq 3 && "${COMP_WORDS[1]}" == "set" ]]; then
    case "${COMP_WORDS[2]}" in
      ACTIVE_AI|OPENAI_API_KEY|GEMINI_API_KEY|META_API_KEY)
        COMPREPLY=( $(compgen -W "$vendors" -- "$cur") )
        ;;
      OPENAI_MODEL)
        COMPREPLY=( $(compgen -W "$openai_models" -- "$cur") )
        ;;
      GEMINI_MODEL)
        COMPREPLY=( $(compgen -W "$gemini_models" -- "$cur") )
        ;;
      *)
        COMPREPLY=()
        ;;
    esac
    return 0
  fi
}


complete -F __ai_agent_completions %
