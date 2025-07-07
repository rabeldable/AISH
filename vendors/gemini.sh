#!/bin/bash

ai_gemini() {
  local user_prompt="$1"
  local system_prompt="$2"  # pass this in from ai.sh (e.g. AI_SYSTEM_PROMPT_CMD)

  local model_id="${GEMINI_MODEL:-gemini-pro}"
  local api_method="${GEMINI_API_METHOD:-generateContent}"
  local endpoint="https://generativelanguage.googleapis.com/v1beta/models/${model_id}:${api_method}"

  if [[ -z "$GEMINI_API_KEY" ]]; then
    echo "❌ GEMINI_API_KEY not set"
    return 1
  fi

  if command -v jq >/dev/null 2>&1; then
    payload=$(jq -n \
      --arg system_prompt "$system_prompt" \
      --arg user_prompt "$user_prompt" \
      '{
        system_instruction: {
          parts: [{text: $system_prompt}]
        },
        contents: [{
          role: "user",
          parts: [{text: $user_prompt}]
        }],
        generationConfig: {
          thinkingConfig: {thinkingBudget: 0},
          responseMimeType: "text/plain"
        }
      }')
  else
    # fallback manual escaping (less safe)
    local esc_sys
    local esc_usr
    esc_sys=$(printf '%s' "$system_prompt" | sed 's/"/\\"/g')
    esc_usr=$(printf '%s' "$user_prompt" | sed 's/"/\\"/g')
    payload=$(cat <<EOF
{
  "system_instruction": {
    "parts": [{"text": "$esc_sys"}]
  },
  "contents": [{
    "role": "user",
    "parts": [{"text": "$esc_usr"}]
  }],
  "generationConfig": {
    "thinkingConfig": {"thinkingBudget": 0},
    "responseMimeType": "text/plain"
  }
}
EOF
)
  fi

  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    "${endpoint}?key=${GEMINI_API_KEY}" \
    -d "$payload")

  echo "$response" | jq -r '.candidates[0].content.parts[0].text // "❌ No content in response"'
}

