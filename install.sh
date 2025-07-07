#!/bin/bash

set -e

CONFIG_FILE="$HOME/.ai_conf"

function prompt_for_input() {
  local var_name="$1"
  local prompt_text="$2"
  read -rp "$prompt_text: " input
  echo "$var_name=\"$input\"" >> "$CONFIG_FILE"
}

function prompt_for_openai_model() {
	echo "Select OpenAI model to use:"
	echo "1) gpt-3.5-turbo (lowest cost)"
	echo "2) gpt-4.1-nano (low-cost GPT-4)"
	echo "3) gpt-4.1-mini (mid-range GPT-4)"
	echo "4) gpt-4o-mini (alternate GPT-4 mini)"
	read -rp "Enter choice [1-4, default 1]: " model_choice
	case "$model_choice" in
	  2) selected_model="gpt-4.1-nano" ;;
	  3) selected_model="gpt-4.1-mini" ;;
	  4) selected_model="gpt-4o-mini" ;;
	  *) selected_model="gpt-3.5-turbo" ;;
	esac
	echo "OPENAI_MODEL=\"$selected_model\"" >> "$CONFIG_FILE"
}

function setup_config() {
  echo "# AI Shell Plugin Configuration" > "$CONFIG_FILE"
  prompt_for_input "OPENAI_API_KEY" "Enter your OpenAI API Key"
  prompt_for_input "GEMINI_API_KEY" "Enter your Gemini API Key (optional)"
  prompt_for_input "META_API_KEY" "Enter your Meta API Key (optional)"
  prompt_for_input "ACTIVE_AI" "Set default AI vendor (openai/gemini/meta)"

  # Read PRETTY_NAME from /etc/os-release, fallback to generic "Linux"
  if [ -r /etc/os-release ]; then
    os_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  else
    os_name="Linux"
  fi

  echo "AI_SYSTEM_PROMPT_CMD=\"You are a $os_name expert. Respond ONLY with the exact shell command requested. Do NOT include explanations, comments, or polite phrases. Plain text only, no formatting.\"" >> "$CONFIG_FILE"
  echo "AI_SYSTEM_PROMPT_EXPLAIN=\"You are a $os_name expert. Provide clear, helpful explanations or troubleshooting advice as appropriate.\"" >> "$CONFIG_FILE"

  prompt_for_input "AI_RESPONSE_FORMAT" "Preferred response format (plaintext/json/shell)"
  prompt_for_openai_model

  read -rp "Enter workspace directory [default: $HOME/ai_workspace]: " workspace_dir
  workspace_dir=${workspace_dir:-"$HOME/ai_workspace"}
  echo "AI_WORKSPACE_DIR=\"$workspace_dir\"" >> "$CONFIG_FILE"
  echo "AI_HISTORY_FILE=\"$HOME/.ai_history.json\"" >> "$CONFIG_FILE"
}

function update_shell_profile() {
  local profile_file="$HOME/.bashrc"
  [[ $SHELL == */zsh ]] && profile_file="$HOME/.zshrc"

  # Remove existing AISH block to avoid duplicates
  sed -i '/#BEGIN_AISH/,/#END_AISH/d' "$profile_file"

  echo "" >> "$profile_file"  # Proper newline
  echo "#BEGIN_AISH" >> "$profile_file"
  echo "# Load AI Shell Plugin" >> "$profile_file"
  echo "[ -f $PWD/ai.sh ] && source $PWD/ai.sh" >> "$profile_file"
  echo "[ -f $CONFIG_FILE ] && source $CONFIG_FILE" >> "$profile_file"
  echo "#END_AISH" >> "$profile_file"

  echo "✅ Shell profile updated ($profile_file). Please restart your terminal or run:"
  echo "source $profile_file"
}

function ensure_deps() {
  for dep in jq curl; do
    if ! command -v $dep >/dev/null; then
      echo "Missing dependency: $dep"
      exit 1
    fi
  done
}

function main() {
  echo "🧠 Installing AI Shell Plugin..."
  ensure_deps
  setup_config
  update_shell_profile
  echo "🎉 Installation complete."
}

main
