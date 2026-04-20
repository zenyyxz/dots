#!/bin/bash
# Fetch chess stats for zen_dx
# Usage: ./get_chess_stats.sh

USERNAME="zen_dx"
STATE_FILE="$(dirname "$0")/chess_state.json"
TODAY=$(date +%Y-%m-%d)

# Ensure state file exists and is valid JSON
if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ] || ! jq . "$STATE_FILE" >/dev/null 2>&1; then
    echo "{\"date\": \"\", \"baseline\": 0, \"last_known\": 0}" > "$STATE_FILE"
fi

# Fetch current stats
RAW_RESPONSE=$(curl -s --connect-timeout 5 "https://api.chess.com/pub/player/${USERNAME}/stats")
CURRENT_RATING=$(echo "$RAW_RESPONSE" | jq -r '.chess_rapid.last.rating // empty' 2>/dev/null)

# Read current state
SAVED_DATE=$(jq -r '.date // empty' "$STATE_FILE" 2>/dev/null || echo "")
BASELINE=$(jq -r '.baseline // 0' "$STATE_FILE" 2>/dev/null || echo 0)
LAST_KNOWN=$(jq -r '.last_known // 0' "$STATE_FILE" 2>/dev/null || echo 0)

# If fetch was successful (CURRENT_RATING is not empty and is a number)
if [[ "$CURRENT_RATING" =~ ^[0-9]+$ ]]; then
    LAST_KNOWN=$CURRENT_RATING
    
    # Check if we need to update baseline (it's a new day or baseline is 0)
    if [ "$SAVED_DATE" != "$TODAY" ] || [ "$BASELINE" -eq 0 ]; then
        BASELINE=$CURRENT_RATING
        SAVED_DATE=$TODAY
    fi
    
    # Save updated state
    jq -n --arg date "$SAVED_DATE" --argjson baseline "$BASELINE" --argjson last_known "$LAST_KNOWN" \
        '{date: $date, baseline: $baseline, last_known: $last_known}' > "$STATE_FILE"
else
    # Fetch failed, use last known rating if available
    CURRENT_RATING=$LAST_KNOWN
fi

# Always output valid JSON
echo "{\"current\": ${CURRENT_RATING:-0}, \"baseline\": ${BASELINE:-0}}"
