#!/bin/bash

# Predefined % command map
declare -A AGENT_COMMANDS=(
  ["analyze"]="analyze_log_file"
  ["summarize"]="summarize_file"
  ["status"]="system_status_check"
  ["deploy"]="run_deploy_script"
  ["set"]="set_config_value"
  ["show"]="show_config_value"
  ["refresh"]="refresh_shell_env"
  ["list"]="list_config_values"
  ["unset"]="unset_config_value"
  ["backup"]="backup_config"
  ["restore"]="restore_config"
)

run_agent_task() {
  local input_str="$1"
  # Parse first word as command, rest as args
  local cmd="${input_str%% *}"
  local args="${input_str#* }"
  # If no space in input, args == cmd, so fix that:
  if [ "$args" = "$cmd" ]; then args=""; fi

  if [[ -z "${AGENT_COMMANDS[$cmd]}" ]]; then
    echo "❌ Unknown agent command: $cmd"
    return 1
  fi

  local handler="${AGENT_COMMANDS[$cmd]}"
  # Call handler with args split as words (handles multiple args properly)
  read -r -a arg_array <<< "$args"
  $handler "${arg_array[@]}"
}

# === Existing handlers ===

analyze_log_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"; return 1
  fi
  local data
  data=$(tail -n 50 "$file")
  ai "Analyze the following log file for warnings, errors, or trends:\n\n$data"
}

summarize_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"; return 1
  fi
  local content
  content=$(< "$file")
  ai "Summarize the following content:\n\n$content"
}

system_status_check() {
  local stats
  stats="$(uptime; df -h /)"
  ai "Give a quick health check summary for this system output:\n\n$stats"
}

run_deploy_script() {
  echo "🚀 Running deploy script..."
  bash ./deploy.sh --no-cache
}

# === New handlers for config management ===

set_config_value() {
  local key="$1"
  shift
  local value="$*"

  if [[ -z "$key" ]]; then
    echo "Usage: % set <key> [value]"
    return 1
  fi

  # Load allowed models from env (make sure .ai_conf is sourced before)
  local allowed_openai_models="${OPENAI_MODELS:-}"
  local allowed_gemini_models="${GEMINI_MODELS:-}"

  key_upper=$(echo "$key" | tr 'a-z' 'A-Z')

  case "$key_upper" in
    OPENAI_API_KEY|GEMINI_API_KEY|META_API_KEY)
      if [[ -z "$value" ]]; then
        # Prompt interactively without echoing input
        read -rsp "Enter your $key_upper: " value
        echo
      fi
      update_config "$key_upper" "$value"
      echo "$key_upper updated."
      ;;
    ACTIVE_AI|AI_RESPONSE_FORMAT)
      if [[ -z "$value" ]]; then
        local current_val
        current_val=$(get_config_value "$key_upper")
        echo "Current $key_upper: $current_val"
        echo "To change: % set $key <new_value>"
        return 0
      fi
      update_config "$key_upper" "$value"
      echo "$key_upper set to '$value'"
      ;;
    OPENAI_MODEL)
      if [[ -z "$value" ]]; then
        local current_val
        current_val=$(get_config_value "$key_upper")
        echo "Current $key_upper: $current_val"
        echo "To change: % set $key <new_value>"
        return 0
      fi
      # Validate against allowed OpenAI models
      if [[ ! " $allowed_openai_models " =~ " $value " ]]; then
        echo "❌ Invalid OPENAI_MODEL: $value"
        echo "Valid options: $allowed_openai_models"
        return 1
      fi
      update_config "$key_upper" "$value"
      echo "$key_upper set to '$value'"
      ;;
    GEMINI_MODEL)
      if [[ -z "$value" ]]; then
        local current_val
        current_val=$(get_config_value "$key_upper")
        echo "Current $key_upper: $current_val"
        echo "To change: % set $key <new_value>"
        return 0
      fi
      # Validate against allowed Gemini models
      if [[ ! " $allowed_gemini_models " =~ " $value " ]]; then
        echo "❌ Invalid GEMINI_MODEL: $value"
        echo "Valid options: $allowed_gemini_models"
        return 1
      fi
      update_config "$key_upper" "$value"
      echo "$key_upper set to '$value'"
      ;;
    META_MODEL)
      if [[ -z "$value" ]]; then
        local current_val
        current_val=$(get_config_value "$key_upper")
        echo "Current $key_upper: $current_val"
        echo "To change: % set $key <new_value>"
        return 0
      fi
      update_config "$key_upper" "$value"
      echo "$key_upper set to '$value'"
      ;;
    *)
      echo "Unknown key: $key"
      ;;
  esac
}

show_config_value() {
  local key="$1"
  if [[ -z "$key" ]]; then
    echo "Usage: % show <key>"
    echo "Supported keys: ACTIVE_AI, AI_RESPONSE_FORMAT, OPENAI_MODEL, GEMINI_MODEL, META_MODEL"
    return 1
  fi

  key_upper=$(echo "$key" | tr 'a-z' 'A-Z')

  case "$key_upper" in
    ACTIVE_AI|AI_RESPONSE_FORMAT|OPENAI_MODEL|GEMINI_MODEL|META_MODEL)
      local val
      val=$(get_config_value "$key_upper")
      echo "$key_upper: $val"
      ;;
    *)
      echo "Unknown key or cannot show: $key"
      ;;
  esac
}

refresh_shell_env() {
  echo "Refreshing shell environment by sourcing ~/.bashrc..."
  if [[ -n "$ZSH_VERSION" ]]; then
    source ~/.zshrc
  else
    source ~/.bashrc
  fi
  echo "Done."
}

list_config_values() {
  local file="$HOME/.ai_conf"
  echo "Current config values:"
  grep -E '^(ACTIVE_AI|AI_RESPONSE_FORMAT|OPENAI_MODEL|GEMINI_MODEL|META_MODEL)=' "$file" 2>/dev/null || echo "No config found."
}

unset_config_value() {
  local key="$1"
  if [[ -z "$key" ]]; then
    echo "Usage: % unset <key>"
    return 1
  fi
  key_upper=$(echo "$key" | tr 'a-z' 'A-Z')

  if grep -q "^$key_upper=" "$HOME/.ai_conf"; then
    sed -i "/^$key_upper=/d" "$HOME/.ai_conf"
    echo "$key_upper removed from config."
  else
    echo "$key_upper not found in config."
  fi
}

backup_config() {
  local src="$HOME/.ai_conf"
  local dest="$HOME/.ai_conf.backup.$(date +%Y%m%d%H%M%S)"
  if [[ -f "$src" ]]; then
    cp "$src" "$dest"
    echo "Backup created at $dest"
  else
    echo "No config file found to backup."
  fi
}

restore_config() {
  local backup_file="$1"
  if [[ -z "$backup_file" ]]; then
    echo "Usage: % restore <backup-file>"
    echo "Available backups:"
    ls -1 "$HOME"/.ai_conf.backup.* 2>/dev/null || echo "No backups found."
    return 1
  fi

  if [[ ! -f "$backup_file" ]]; then
    echo "Backup file not found: $backup_file"
    return 1
  fi

  cp "$backup_file" "$HOME/.ai_conf"
  echo "Config restored from $backup_file"
}

# --- Utility functions ---

get_config_value() {
  local key="$1"
  grep "^$key=" "$HOME/.ai_conf" 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"'
}

update_config() {
  local key="$1"
  local value="$2"
  local file="$HOME/.ai_conf"

  local safe_value
  safe_value=$(printf '%s\n' "$value" | sed 's/[\/&]/\\&/g')

  if grep -q "^$key=" "$file" 2>/dev/null; then
    sed -i "s/^$key=.*/$key=\"$safe_value\"/" "$file"
  else
    echo "$key=\"$value\"" >> "$file"
  fi
}

