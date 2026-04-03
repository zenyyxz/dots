#!/bin/bash
# setup_vpn_permissions.sh

CORE_PATH="/home/zenyyxz/dotfiles/vpn/arch-vpn/vpn-core"
POLICY_FILE="/usr/share/polkit-1/actions/org.archvpn.core.policy"

echo "Creating Polkit policy for Arch VPN..."

sudo tee "$POLICY_FILE" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="org.archvpn.core.run">
    <description>Run Arch VPN Core</description>
    <message>Authentication is required to start the VPN Core</message>
    <defaults>
      <allow_any>yes</allow_any>
      <allow_inactive>yes</allow_inactive>
      <allow_active>yes</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">$CORE_PATH</annotate>
  </action>
</policyconfig>
EOF

echo "Done! The VPN Core can now be started via pkexec without a password prompt."
