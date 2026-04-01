#!/bin/bash

# Configuration
VPN_DIR="/home/zenyyxz/dotfiles/vpn/sing-box"
PROFILES_FILE="$VPN_DIR/profiles.json"
APPLY_SCRIPT="$VPN_DIR/apply_config.sh"
CONVERTER="$VPN_DIR/vless_converter.py"
LOG_FILE="/tmp/vpn_manager.log"

# Use absolute paths for commands to be safe
JQ_BIN=$(command -v jq)
PYTHON_BIN=$(command -v python3)

echo "--- $(date) ---" >> "$LOG_FILE"
echo "Command: $1" >> "$LOG_FILE"
echo "Arg 2: $2" >> "$LOG_FILE"

mkdir -p "$VPN_DIR"
[ ! -f "$PROFILES_FILE" ] && echo "[]" > "$PROFILES_FILE"

case "$1" in
    list)
        "$JQ_BIN" -r '.[] | .name' "$PROFILES_FILE" 2>> "$LOG_FILE"
        ;;
    
    add)
        CONTENT="$2"
        NAME=""
        
        if [[ "$CONTENT" == vless://* ]]; then
            NAME=$(echo "$CONTENT" | grep -o '#.*' | sed 's/#//' | "$PYTHON_BIN" -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>> "$LOG_FILE")
        fi
        
        if [ -z "$NAME" ]; then
            NAME="Profile-$(date +%u%H%M%S)"
        fi
        
        # Check for duplicates and rename if necessary
        FINAL_NAME="$NAME"
        COUNTER=1
        while "$JQ_BIN" -e ".[] | select(.name == \"$FINAL_NAME\")" "$PROFILES_FILE" > /dev/null 2>&1; do
            FINAL_NAME="${NAME}-${COUNTER}"
            COUNTER=$((COUNTER + 1))
        done
        
        TMP_FILE=$(mktemp)
        "$JQ_BIN" --arg n "$FINAL_NAME" --arg c "$CONTENT" '. += [{"name": $n, "content": $c}]' "$PROFILES_FILE" > "$TMP_FILE" 2>> "$LOG_FILE"
        if [ $? -eq 0 ]; then
            mv "$TMP_FILE" "$PROFILES_FILE"
            echo "Added: $FINAL_NAME"
        else
            echo "Error: jq failed to add profile." >> "$LOG_FILE"
            exit 1
        fi
        ;;

    delete)
        NAME="$2"
        TMP_FILE=$(mktemp)
        "$JQ_BIN" --arg n "$NAME" 'del(.[] | select(.name == $n))' "$PROFILES_FILE" > "$TMP_FILE" 2>> "$LOG_FILE" && mv "$TMP_FILE" "$PROFILES_FILE"
        echo "Deleted: $NAME"
        ;;

    apply)
        NAME="$2"
        CONTENT=$("$JQ_BIN" -r ".[] | select(.name == \"$NAME\") | .content" "$PROFILES_FILE" 2>> "$LOG_FILE")
        if [ -z "$CONTENT" ] || [ "$CONTENT" == "null" ]; then
            echo "Error: Profile not found." >> "$LOG_FILE"
            exit 1
        fi
        
        echo "$CONTENT" | bash "$APPLY_SCRIPT" 2>> "$LOG_FILE"
        TMP_FILE=$(mktemp)
        "$JQ_BIN" --arg n "$NAME" 'map(.active = (.name == $n))' "$PROFILES_FILE" > "$TMP_FILE" 2>> "$LOG_FILE" && mv "$TMP_FILE" "$PROFILES_FILE"
        ;;
    
    active)
        "$JQ_BIN" -r '.[] | select(.active == true) | .name' "$PROFILES_FILE" 2>> "$LOG_FILE"
        ;;

    *)
        echo "Usage: $0 {list|add|delete|apply|active} [args]"
        exit 1
        ;;
esac
