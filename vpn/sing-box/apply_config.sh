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

# Always run through converter to ensure logging config is injected
PROCESSED_JSON=$(echo "$RAW_INPUT" | python3 "$CONVERTER")
if [ $? -ne 0 ] || [ -z "$PROCESSED_JSON" ]; then
    echo "Error: Failed to process configuration."
    exit 1
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
