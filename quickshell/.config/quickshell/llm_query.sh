#!/bin/bash
# Script to call Gemini API using the key from .env

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load .env from dotfiles root
if [ -f "$DOTFILES_ROOT/.env" ]; then
    export $(grep -v '^#' "$DOTFILES_ROOT/.env" | xargs)
fi

API_KEY="${GEMINI_API_KEY}"
USER_INPUT="$1"

if [ -z "$API_KEY" ]; then
    echo "Error: GEMINI_API_KEY not found in .env"
    echo "Please add GEMINI_API_KEY=your_key_here to $DOTFILES_ROOT/.env"
    exit 1
fi

# Simple curl call to Gemini Pro (adjust model if needed)
curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent?alt=sse&key=${API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
      "contents": [{
        "parts":[{"text": "'"${USER_INPUT}"'"}]
      }]
    }' | grep -v 'data: ' | grep -v '\[DONE\]' | jq -r '.candidates[0].content.parts[0].text // empty' 2>/dev/null
