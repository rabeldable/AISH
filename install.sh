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
  # Load models from config file for display
  local models
  models=$(grep '^OPENAI_MODELS=' "$CONFIG_FILE" | cut -d= -f2- | tr -d '"')
  IFS=' ' read -r -a model_array <<< "$models"

  echo "Select OpenAI model to use:"
  for i in "${!model_array[@]}"; do
    echo "$((i+1))) ${model_array[$i]}"
  done

  read -rp "Enter choice [1-${#model_array[@]}, default 1]: " model_choice
  if [[ "$model_choice" =~ ^[1-9][0-9]*$ ]] && (( model_choice >= 1 && model_choice <= ${#model_array[@]} )); then
    selected_model="${model_array[$((model_choice-1))]}"
  else
    selected_model="${model_array[0]}"
  fi
  echo "OPENAI_MODEL=\"$selected_model\"" >> "$CONFIG_FILE"
}

function prompt_for_gemini_model() {
  # Load Gemini models from config file for display
  local models
  models=$(grep '^GEMINI_MODELS=' "$CONFIG_FILE" | cut -d= -f2- | tr -d '"')
  IFS=' ' read -r -a model_array <<< "$models"

  echo "Select Gemini model to use:"
  for i in "${!model_array[@]}"; do
    echo "$((i+1))) ${model_array[$i]}"
  done

  read -rp "Enter choice [1-${#model_array[@]}, default 1]: " model_choice
  if [[ "$model_choice" =~ ^[1-9][0-9]*$ ]] && (( model_choice >= 1 && model_choice <= ${#model_array[@]} )); then
    selected_model="${model_array[$((model_choice-1))]}"
  else
    selected_model="${model_array[0]}"
  fi
  echo "GEMINI_MODEL=\"$selected_model\"" >> "$CONFIG_FILE"
}

function setup_config() {
  echo "# AI Shell Plugin Configuration" > "$CONFIG_FILE"

  # Write allowed models for OpenAI and Gemini
  echo 'OPENAI_MODELS="gpt-3.5-turbo gpt-4.1-nano gpt-4.1-mini gpt-4o-mini"' >> "$CONFIG_FILE"
  echo 'GEMINI_MODELS="gemini-2.5-flash gemini-2.5-flash-lite-preview-06-17 gemini-2.0-flash"' >> "$CONFIG_FILE"

  prompt_for_input "OPENAI_API_KEY" "Enter your OpenAI API Key"
  prompt_for_input "GEMINI_API_KEY" "Enter your Gemini API Key (optional)"
  prompt_for_input "META_API_KEY" "Enter your Meta API Key (optional)"
  prompt_for_input "ACTIVE_AI" "Set default AI vendor (openai/gemini/meta)"

  # Detect OS name for system prompt
  local os_name
  if [ -r /etc/os-release ]; then
    os_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
  else
    os_name="$(uname -s) $(uname -r)"
  fi

  echo "AI_SYSTEM_PROMPT_CMD=\"You are a $os_name expert. Respond ONLY with the exact shell command requested. Do NOT include explanations, comments, or polite phrases. Plain text only, no formatting.\"" >> "$CONFIG_FILE"
  echo "AI_SYSTEM_PROMPT_EXPLAIN=\"You are a $os_name expert. Provide clear, helpful explanations or troubleshooting advice as appropriate.\"" >> "$CONFIG_FILE"

  prompt_for_input "AI_RESPONSE_FORMAT" "Preferred response format (plaintext/json/shell)"

  prompt_for_openai_model
  prompt_for_gemini_model

  read -rp "Enter workspace directory [default: $HOME/ai_workspace]: " workspace_dir
  workspace_dir=${workspace_dir:-"$HOME/ai_workspace"}
  echo "AI_WORKSPACE_DIR=\"$workspace_dir\"" >> "$CONFIG_FILE"
  echo "AI_HISTORY_FILE=\"$HOME/.ai_history.json\"" >> "$CONFIG_FILE"
}

function update_shell_profile() {
  local profile_file="$HOME/.bashrc"
  [[ $SHELL == */zsh ]] && profile_file="$HOME/.zshrc"

  sed -i '/#BEGIN_AISH/,/#END_AISH/d' "$profile_file"

  {
    echo ""
    echo "#BEGIN_AISH"
    echo "# Load AI Shell Plugin"
    echo "[ -f $PWD/ai.sh ] && source $PWD/ai.sh"
    echo "[ -f $CONFIG_FILE ] && source $CONFIG_FILE"
    echo "#END_AISH"
  } >> "$profile_file"

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

