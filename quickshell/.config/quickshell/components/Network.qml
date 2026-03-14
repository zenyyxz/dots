import QtQuick
import QtQuick.Layouts
import QtQuick.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: 40
    implicitHeight: 32

    property string ssid: ""
    property real signal: 0.0
    property bool wifiEnabled: true
    readonly property bool connected: ssid !== "" && ssid !== "Disconnected"

    Process {
        id: netProc
        command: ["bash", "-c", "printf '%s|%s\\n' \"$(nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | cut -d: -f2,3)\" \"$(nmcli radio wifi)\""]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const mainParts = msg.trim().split("|");
                if (mainParts.length >= 2) {
                    const statusPart = mainParts[0];
                    const enabledPart = mainParts[1];
                    
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

    function getWifiIconName() {
        if (!root.wifiEnabled) return "network-wireless-disabled-symbolic";
        if (!root.connected) return "network-wireless-offline-symbolic";

        if (root.signal >= 0.8) return "network-wireless-signal-excellent-symbolic";
        if (root.signal >= 0.6) return "network-wireless-signal-good-symbolic";
        if (root.signal >= 0.4) return "network-wireless-signal-ok-symbolic";
        return "network-wireless-signal-weak-symbolic";
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

    Image {
        id: wifiIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        source: Quickshell.iconPath(root.getWifiIconName())
        smooth: true
        
        layer.enabled: true
        layer.effect: Colorize {
            color: !root.wifiEnabled ? Theme.surface1 : (root.connected ? Theme.sapphire : Theme.red)
        }
    }
}
