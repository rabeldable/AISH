#!/bin/bash

OPENAI_API_URL=https://api.openai.com/v1/chat/completions

ai_openai() {
  local json_payload="$1"
  curl -s -X POST "$OPENAI_API_URL" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$json_payload" | jq -r '.choices[0].message.content'
}
