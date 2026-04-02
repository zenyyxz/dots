#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$SCRIPT_DIR/sing-box"
TOGGLE_SCRIPT="$SCRIPT_DIR/toggle_vpn.sh"
POLICY_FILE="/usr/share/polkit-1/actions/org.singbox.vpn.policy"

echo "Setting up Sing-box permissions..."

# 1. Give binary network capabilities
if [ -f "$BINARY" ]; then
    echo "Applying setcap to sing-box binary..."
    sudo setcap cap_net_admin,cap_net_bind_service=+ep "$BINARY"
fi

# 2. Create Polkit Policy for "Ask Once" behavior
echo "Creating Polkit policy..."
sudo bash -c "cat > $POLICY_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD polkit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/software/polkit/policyconfig-1.dtd">
<policyconfig>
  <action id="org.singbox.vpn.toggle">
    <description>Run Sing-box VPN Toggle</description>
    <message>Authentication is required to toggle the VPN tunnel</message>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">$TOGGLE_SCRIPT</annotate>
  </action>
</policyconfig>
EOF

echo "Setup complete! You can now toggle the VPN via the UI with a session-cached password."
