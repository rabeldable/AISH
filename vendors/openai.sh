#!/bin/bash

ai_openai() {
  local prompt="$1"
  curl -s -X POST "$OPENAI_API_URL" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"gpt-4\",
      \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
    }" | jq -r '.choices[0].message.content'
}
