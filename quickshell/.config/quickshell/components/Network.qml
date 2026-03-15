import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: 32
    implicitHeight: 32

    property string ssid: ""
    property real signal: 0.0
    property bool wifiEnabled: true
    readonly property bool connected: ssid !== "" && ssid !== "Disconnected"

    Process {
        id: netProc
        command: ["bash", "-c", "printf '%s|%s\\n' \"$(nmcli radio wifi)\" \"$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | cut -d: -f2,3)\""]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.trim().split("|");
                if (parts.length >= 2) {
                    root.wifiEnabled = (parts[0] === "enabled");
                    const statusStr = parts[1];
                    const lastColon = statusStr.lastIndexOf(":");
                    if (lastColon !== -1) {
                        root.ssid = statusStr.substring(0, lastColon);
                        root.signal = parseInt(statusStr.substring(lastColon + 1)) / 100.0;
                    } else {
                        root.ssid = "";
                        root.signal = 0.0;
                    }
                }
            }
        }
    }

    Timer {
        interval: 5000; repeat: true; running: true
        onTriggered: netProc.running = true
    }

    function getWifiIcon() {
        if (!root.wifiEnabled) return "󰤭"; // WiFi Disabled
        if (!root.connected) return "󰤮";   // Disconnected
        
        if (root.signal >= 0.75) return "󰤨"; // Excellent (4 bars)
        if (root.signal >= 0.5) return "󰤥";  // Good (3 bars)
        if (root.signal >= 0.25) return "󰤢"; // OK (2 bars)
        return "󰤟"; // Weak (1 bar)
    }

    function getWifiColor() {
        if (!root.wifiEnabled) return Theme.surface1;
        if (!root.connected) return Theme.red;
        
        if (root.signal >= 0.75) return Theme.blue;
        if (root.signal >= 0.5) return Theme.green;
        if (root.signal >= 0.25) return Theme.yellow;
        return Theme.maroon;
    }

    function getTooltipText() {
        if (!root.wifiEnabled) return "WiFi: Disabled";
        if (!root.connected) return "WiFi: Disconnected";
        return "WiFi: " + root.ssid + " (" + Math.round(root.signal * 100) + "%)";
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipController.show(root.getTooltipText(), root)
        onExited: TooltipController.hide()
    }

    Text {
        anchors.centerIn: parent
        text: root.getWifiIcon()
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        color: root.getWifiColor()
        
        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
