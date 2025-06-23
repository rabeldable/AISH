#!/bin/bash

ai_meta() {
  local prompt="$1"
  curl -s -X POST "http://localhost:11434/api/generate" \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"llama\",
      \"prompt\": \"$prompt\"
    }" | jq -r '.response'
}
