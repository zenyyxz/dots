#!/bin/bash

# Configuration
TOR_CONFIG="/etc/tor/torrc"
USER_NAME=$(whoami)

echo "Starting Tor auto-configuration..."

# 1. Check if Tor is installed
if ! command -v tor &> /dev/null; then
    echo "Error: Tor is not installed. Please install it first (e.g., sudo pacman -S tor)."
    exit 1
fi

# 2. Add required lines to torrc if they don't exist
declare -a LINES=(
    "TransPort 0.0.0.0:9040"
    "DNSPort 0.0.0.0:5353"
    "VirtualAddrNetworkIPv4 10.192.0.0/10"
    "AutomapHostsOnResolve 1"
    "ControlPort 9051"
    "CookieAuthentication 1"
    "CookieAuthFileGroupReadable 1"
    "DataDirectoryGroupReadable 1"
)

NEED_RESTART=false

for line in "${LINES[@]}"; do
    if ! grep -Fxq "$line" "$TOR_CONFIG"; then
        echo "Adding '$line' to $TOR_CONFIG..."
        echo "$line" | sudo tee -a "$TOR_CONFIG" > /dev/null
        NEED_RESTART=true
    fi
done

# 3. Add user to tor group
if ! groups "$USER_NAME" | grep -q "\btor\b"; then
    echo "Adding $USER_NAME to the 'tor' group..."
    sudo usermod -aG tor "$USER_NAME"
    NEED_RESTART=true
fi

# 4. Set directory permissions for cookie access
if [ "$(sudo stat -c %a /var/lib/tor)" != "750" ]; then
    echo "Fixing /var/lib/tor permissions..."
    sudo chmod 750 /var/lib/tor
    NEED_RESTART=true
fi

# 5. Restart Tor if changes were made
if [ "$NEED_RESTART" = true ]; then
    echo "Restarting Tor service..."
    sudo systemctl restart tor
    echo "Setup complete! Please LOG OUT and LOG BACK IN to refresh group permissions."
else
    echo "Tor configuration is already up to date."
fi
