#!/bin/bash

ai_gemini() {
  local prompt="$1"
  curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"contents\": [{\"parts\": [{\"text\": \"$prompt\"}]}]
    }" | jq -r '.candidates[0].content.parts[0].text'
}
