#!/bin/bash

# Configuration
VPN_DIR="/home/zenyyxz/dotfiles/vpn/sing-box"
BINARY="$VPN_DIR/sing-box"
CONFIG="$VPN_DIR/config.json"
PID_FILE="/tmp/sing-box-vpn.pid"

status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        return 0 # Running
    else
        return 1 # Not running
    fi
}

start() {
    if status; then
        echo "VPN is already running."
        exit 0
    fi
    
    echo "Starting VPN..."
    # No sudo here - depends on setcap being run once manually:
    # sudo setcap cap_net_admin,cap_net_bind_service=+ep /home/zenyyxz/dotfiles/vpn/sing-box/sing-box
    "$BINARY" run -c "$CONFIG" > /dev/null 2>&1 &
    
    echo $! > "$PID_FILE"
    echo "VPN started."
}

stop() {
    if ! status; then
        echo "VPN is not running."
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo "Stopping VPN..."
    PID=$(cat "$PID_FILE")
    kill $PID
    rm -f "$PID_FILE"
    echo "VPN stopped."
}

case "$1" in
    start) start ;;
    stop) stop ;;
    toggle)
        if status; then
            stop
        else
            start
        fi
        ;;
    status)
        if status; then
            echo "on"
        else
            echo "off"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|status}"
        exit 1
        ;;
esac
