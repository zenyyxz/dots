#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$SCRIPT_DIR/sing-box"
CONFIG="$SCRIPT_DIR/config.json"
PID_FILE="/tmp/sing-box-vpn.pid"
RESOLV_BAK="/tmp/resolv.conf.vpn.bak"

# Helper to run commands as root
run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

status() {
    # Check if process is running and interface is up
    if pgrep -x "sing-box" >/dev/null && ip addr show tun0 &>/dev/null; then
        return 0
    else
        return 1
    fi
}


fix_dns() {
    echo "Forcing system DNS to sing-box (127.0.0.1)..."
    run_as_root cp /etc/resolv.conf "$RESOLV_BAK"
    echo "nameserver 127.0.0.1" | run_as_root tee /etc/resolv.conf > /dev/null
}

restore_dns() {
    if [ -f "$RESOLV_BAK" ]; then
        echo "Restoring system DNS..."
        run_as_root cp "$RESOLV_BAK" /etc/resolv.conf
        run_as_root rm -f "$RESOLV_BAK"
    fi
}

start() {
    if status; then
        echo "VPN is already running."
        exit 0
    fi
    
    echo "Starting VPN..."
    
    # 1. Ensure binary has capabilities (just in case)
    run_as_root setcap cap_net_admin,cap_net_bind_service=+ep "$BINARY"
    
    # 2. Start sing-box
    # We run it as root if the script is already root (pkexec), otherwise standard
    if [ "$(id -u)" -eq 0 ]; then
        "$BINARY" run -c "$CONFIG" > /dev/null 2>&1 &
    else
        sudo "$BINARY" run -c "$CONFIG" > /dev/null 2>&1 &
    fi
    echo $! > "$PID_FILE"
    
    # 3. Wait for tun0 to appear (up to 5 seconds)
    echo "Waiting for interface..."
    for i in {1..10}; do
        if ip addr show tun0 &>/dev/null; then
            break
        fi
        sleep 0.5
    done

    if ! ip addr show tun0 &>/dev/null; then
        echo "Error: tun0 interface failed to appear. Check your vless config."
        stop
        exit 1
    fi
    
    # 4. Apply DNS fix
    fix_dns
    echo "VPN started successfully."
}

stop() {
    echo "Stopping VPN..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        run_as_root kill $PID
        rm -f "$PID_FILE" 2>/dev/null
    fi
    
    restore_dns
    echo "VPN stopped."
}

case "$1" in
    start) start ;;
    stop) stop ;;
    toggle)
        if status; then stop; else start; fi
        ;;
    status)
        if status; then echo "on"; else echo "off"; fi
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|status}"
        exit 1
        ;;
esac
