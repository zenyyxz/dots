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
    # We use sudo because TUN mode needs it. 
    # To avoid password prompt, add this to /etc/sudoers:
    # %wheel ALL=(ALL) NOPASSWD: /home/zenyyxz/dotfiles/vpn/sing-box/sing-box
    sudo "$BINARY" run -c "$CONFIG" > /tmp/sing-box-vpn.log 2>&1 &
    
    echo $! > "$PID_FILE"
    echo "VPN started."
}

stop() {
    if ! status; then
        echo "VPN is not running."
        # Cleanup orphan pids if any
        sudo pkill -f "$BINARY run -c $CONFIG"
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo "Stopping VPN..."
    PID=$(cat "$PID_FILE")
    sudo kill $PID
    sudo pkill -f "$BINARY run -c $CONFIG"
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
