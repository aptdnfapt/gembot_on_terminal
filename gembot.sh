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

# Initialize chat variables
chat_history=""
continue_chat=true
selected_model=""

mkdir -p $HOME/gemchat/
touch /tmp/gemini_response.json

# Main chat loop
while $continue_chat; do
  if [ -z "$selected_model" ]; then
    selected_model=$(printf "%s\n" "${models[@]}" | fzf --prompt="Select Gemini model: ")
    [[ -z "$selected_model" ]] && exit 1
  fi

  read -p "ask gem (or 'q' to quit, 'wq filename' to save and quit): " READ

  if [[ "$READ" == "q" ]]; then
    exit 0
  elif [[ "$READ" =~ ^wq.* ]]; then
    filename=$(echo "$READ" | cut -d' ' -f2)
    echo "$chat_history" >"$HOME/gemchat/$filename"
    exit 0
  elif [[ -z "$READ" ]]; then
    continue
  fi

  TEMPERATURE=1.0
  PROMPT="Previous conversation:\n$chat_history\n\nNew question:\n$READ\n\nPlease respond in Markdown format."
  PROMPT_ESCAPED=$(echo "$PROMPT" | jq -R -s .)

  RESPONSE=$(curl -s -o /tmp/gemini_response.json -w "%{http_code}" \
    "https://generativelanguage.googleapis.com/v1beta/models/$selected_model:generateContent?key=$MY_API_KEY" \
    -H 'Content-Type: application/json' \
    -X POST \
    -d '{
        "contents": [{
            "parts":[{"text": '"$PROMPT_ESCAPED"'}]
            }],
        "generationConfig": {
            "temperature": '"$TEMPERATURE"'
            }
        }')

  HTTP_STATUS=$RESPONSE
  RESPONSE=$(cat /tmp/gemini_response.json)

  if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "Error: HTTP status $HTTP_STATUS"
    echo "$RESPONSE" | jq .
    continue
  fi

  GEMINI_RESPONSE=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text')

  if [ -z "$GEMINI_RESPONSE" ] || [ "$GEMINI_RESPONSE" == "null" ]; then
    echo "Error: No valid response from Gemini. Full API response:"
    echo "$RESPONSE" | jq .
  else
    echo "gemini says:"
    echo "$GEMINI_RESPONSE" | bat -l markdown
    chat_history+="User: $READ\n\nGemini: $GEMINI_RESPONSE\n\n---\n\n"
  fi
done
