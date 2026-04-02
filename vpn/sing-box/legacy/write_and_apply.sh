#!/bin/bash
# This script takes the configuration content as the first argument
# and pipes it to the apply_config.sh script.
# This works around the lack of direct stdin support in some Quickshell versions.

CONFIG_CONTENT="$1"
SCRIPT_DIR=$(dirname "$0")

echo "$CONFIG_CONTENT" | bash "$SCRIPT_DIR/apply_config.sh"
