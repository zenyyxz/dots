#!/bin/bash

# Configuration
VPN_DIR="/home/zenyyxz/dotfiles/vpn/sing-box"
BINARY="$VPN_DIR/sing-box"
CONFIG="$VPN_DIR/config.json"
PID_FILE="/tmp/sing-box-vpn.pid"
RESOLV_BAK="/tmp/resolv.conf.vpn.bak"

status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        return 0 # Running
    else
        return 1 # Not running
    fi
}

fix_dns() {
    echo "Forcing system DNS to sing-box (127.0.0.1)..."
    sudo cp /etc/resolv.conf "$RESOLV_BAK"
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null
}

restore_dns() {
    if [ -f "$RESOLV_BAK" ]; then
        echo "Restoring system DNS..."
        sudo cp "$RESOLV_BAK" /etc/resolv.conf
        sudo rm -f "$RESOLV_BAK"
    fi
}

start() {
    if status; then
        echo "VPN is already running."
        exit 0
    fi
    
    echo "Starting VPN..."
    # Ensure sing-box has permissions:
    # sudo setcap cap_net_admin,cap_net_bind_service=+ep /home/zenyyxz/dotfiles/vpn/sing-box/sing-box
    
    # Start sing-box
    "$BINARY" run -c "$CONFIG" > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    
    # Wait a moment for tun to initialize
    sleep 2
    
    # The Winning Move
    fix_dns
    
    echo "VPN started."
}

stop() {
    if ! status; then
        echo "VPN is not running."
        restore_dns # Just in case
        rm -f "$PID_FILE"
        exit 0
    fi
    
    echo "Stopping VPN..."
    PID=$(cat "$PID_FILE")
    kill $PID
    rm -f "$PID_FILE"
    
    restore_dns
    
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
