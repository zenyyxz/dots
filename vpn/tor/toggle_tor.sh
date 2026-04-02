#!/bin/bash
ACTION=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$ACTION" == "start" ]; then
    systemctl start tor
    bash "$SCRIPT_DIR/tor_proxy.sh" start
else
    systemctl stop tor
    bash "$SCRIPT_DIR/tor_proxy.sh" stop
fi
