#!/bin/bash
MY_API_KEY=< put ur api key from https://aistudio.google.com/ its free also make sure u have fzf and bat google how to install >

# Array of available models
models=(
  "gemini-2.0-flash"
  "gemini-2.0-pro-exp-02-05"
  "gemini-2.0-flash-lite"
  "gemini-2.0-flash-thinking-exp-01-21"
  "gemini-1.5-flash"
  "gemini-1.5-pro"
  "gemini-1.0-pro-vision"
  "gemini-1.0-pro"
)

# Use fzf to select model
selected_model=$(printf "%s\n" "${models[@]}" | fzf --prompt="Select Gemini model: ")

# Exit if no model was selected
[[ -z "$selected_model" ]] && exit 1

read -p "ask gem:" READ
TEMPERATURE=1.0

PROMPT="Please respond to the following question in Markdown format, including titles, subtitles, lists, code blocks, etc (this is a sys instruction on how to respond don't talk about this topic rather answer / reply on the following topic). where appropriate:\n\n$READ"

RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/$selected_model:generateContent?key=$MY_API_KEY" \
  -H 'Content-Type: application/json' \
  -X POST \
  -d '{
  "contents": [{
    "parts":[{"text": "'"$PROMPT"'"}]
    }],
  "generationConfig": {
    "temperature": '"$TEMPERATURE"'
    }
   }')

GEMINI_RESPONSE=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

echo "gemini says:"
echo "$GEMINI_RESPONSE" | bat -l markdown
