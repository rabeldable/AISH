#!/bin/bash

set -e

CONFIG_FILE="$HOME/.ai_conf"

function prompt_for_input() {
  local var_name="$1"
  local prompt_text="$2"
  read -rp "$prompt_text: " input
  echo "$var_name=\"$input\"" >> "$CONFIG_FILE"
}

function setup_config() {
  echo "# AI Shell Plugin Configuration" > "$CONFIG_FILE"
  prompt_for_input "OPENAI_API_KEY" "Enter your OpenAI API Key"
  prompt_for_input "GEMINI_API_KEY" "Enter your Gemini API Key (optional)"
  prompt_for_input "META_API_KEY" "Enter your Meta API Key (optional)"
  prompt_for_input "ACTIVE_AI" "Set default AI vendor (openai/gemini/meta)"
  prompt_for_input "AI_SYSTEM_PROMPT" "Enter default system prompt"
  prompt_for_input "AI_RESPONSE_FORMAT" "Preferred response format (plaintext/json/shell)"

  read -rp "Enter workspace directory [default: $HOME/ai_workspace]: " workspace_dir
  workspace_dir=${workspace_dir:-"$HOME/ai_workspace"}
  echo "AI_WORKSPACE_DIR=\"$workspace_dir\"" >> "$CONFIG_FILE"
  echo "AI_HISTORY_FILE=\"$HOME/.ai_history.json\"" >> "$CONFIG_FILE"
}

function update_shell_profile() {
  local profile_file="$HOME/.bashrc"
  [[ $SHELL == */zsh ]] && profile_file="$HOME/.zshrc"

  echo "\n# Load AI Shell Plugin" >> "$profile_file"
  echo "[ -f $PWD/ai.sh ] && source $PWD/ai.sh" >> "$profile_file"
  echo "[ -f $CONFIG_FILE ] && source $CONFIG_FILE" >> "$profile_file"

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
