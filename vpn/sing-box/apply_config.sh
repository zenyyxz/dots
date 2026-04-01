#!/bin/bash

# Configuration
VPN_DIR="/home/zenyyxz/dotfiles/vpn/sing-box"
CONFIG="$VPN_DIR/config.json"
TOGGLE_SCRIPT="$VPN_DIR/toggle_vpn.sh"
CONVERTER="$VPN_DIR/vless_converter.py"

# Get input from file or stdin
if [ -n "$1" ] && [ -f "$1" ]; then
    RAW_INPUT=$(cat "$1")
else
    RAW_INPUT=$(cat)
fi

# Convert VLESS link to JSON if needed
if [[ "$RAW_INPUT" == vless://* ]]; then
    PROCESSED_JSON=$(echo "$RAW_INPUT" | python3 "$CONVERTER")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse VLESS link."
        exit 1
    fi
else
    PROCESSED_JSON="$RAW_INPUT"
fi

# Validate JSON with jq
if ! echo "$PROCESSED_JSON" | jq . > /dev/null 2>&1; then
    echo "Error: Invalid JSON configuration."
    exit 1
fi

# Check if the VPN is currently running
WAS_RUNNING=false
if [ "$("$TOGGLE_SCRIPT" status)" == "on" ]; then
    WAS_RUNNING=true
    "$TOGGLE_SCRIPT" stop
fi

# Overwrite the config
echo "$PROCESSED_JSON" | jq . > "$CONFIG"

# Restart if it was running
if [ "$WAS_RUNNING" == "true" ]; then
    "$TOGGLE_SCRIPT" start
fi

echo "Success: VPN configuration updated and applied."
