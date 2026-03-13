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
        // Improved command to return one line: SSID|SIGNAL|ENABLED
        command: ["bash", "-c", "printf '%s|%s\\n' \"$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | cut -d: -f2,3)\" \"$(nmcli radio wifi)\""]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const mainParts = msg.trim().split("|");
                if (mainParts.length >= 2) {
                    const statusPart = mainParts[0]; // "SSID:SIGNAL"
                    const enabledPart = mainParts[1]; // "enabled" or "disabled"
                    
                    if (statusPart.includes(":")) {
                        const statusParts = statusPart.split(":");
                        root.ssid = statusParts[0];
                        root.signal = parseInt(statusParts[1]) / 100.0;
                    } else {
                        root.ssid = "Disconnected";
                        root.signal = 0.0;
                    }
                    root.wifiEnabled = (enabledPart === "enabled");
                }
            }
        }
    }

    Timer {
        interval: 10000; repeat: true; running: true
        onTriggered: netProc.running = true
    }

    function getWifiIcon() {
        if (!root.wifiEnabled) return "󰤭"; // WiFi Off
        if (!root.connected) return "󰤮";   // Disconnected
        return "󰤨";                        // Connected
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

    RowLayout {
        id: layout
        anchors.centerIn: parent

        ProgressCircle {
            value: root.connected ? root.signal : 0.0
            color: !root.wifiEnabled ? Theme.surface1 : (root.connected ? Theme.sapphire : Theme.red)
            
            Text {
                anchors.centerIn: parent
                text: root.getWifiIcon()
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: parent.color
            }
        }
    }
}
