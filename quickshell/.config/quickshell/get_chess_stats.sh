#!/bin/bash
# Fetch chess stats for zen_dx
# Usage: ./get_chess_stats.sh [current|baseline]

USERNAME="zen_dx"
STATE_FILE="$(dirname "$0")/chess_state.json"
TODAY=$(date +%Y-%m-%d)

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo "{\"date\": \"\", \"baseline\": 0}" > "$STATE_FILE"
fi

CURRENT_RATING=$(curl -s "https://api.chess.com/pub/player/${USERNAME}/stats" | jq -r '.chess_rapid.last.rating')

# Check if we need to update baseline (it's a new day or baseline is 0)
SAVED_DATE=$(jq -r '.date' "$STATE_FILE")
if [ "$SAVED_DATE" != "$TODAY" ] || [ "$(jq -r '.baseline' "$STATE_FILE")" == "0" ]; then
    jq --arg date "$TODAY" --arg rating "$CURRENT_RATING" '.date = $date | .baseline = ($rating | tonumber)' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

BASELINE=$(jq -r '.baseline' "$STATE_FILE")

echo "{\"current\": $CURRENT_RATING, \"baseline\": $BASELINE}"
