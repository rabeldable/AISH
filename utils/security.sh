#!/bin/bash

sanitize_prompt() {
  local input="$1"
  # Strip dangerous shell meta chars (basic)
  echo "$input" | sed 's/[;&|<>`]//g'
}

check_response_security() {
  local response="$1"
  local prompt="Perform a brief security audit of the following AI-generated response. Identify any potentially harmful code, commands, or behaviors. Output the result as a short security report:\n\n$response"

  case "$ACTIVE_AI" in
    openai)
      security_report=$(ai_openai "$prompt")
      ;;
    gemini)
      security_report=$(ai_gemini "$prompt")
      ;;
    meta)
      security_report=$(ai_meta "$prompt")
      ;;
    *)
      echo "Unknown vendor for security audit"
      return 1
      ;;
  esac

  echo "\n--- Security Report ---"
  echo "$security_report"
  echo "------------------------\n"
}
