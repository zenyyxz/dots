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
    border.width: Theme.borderWidth
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    property string localIp: "Offline"
    property bool vpnActive: false

    Process {
        id: targetProc
        // More robust IP detection: looks for the first non-loopback IPv4 address
        command: ["bash", "-c", "ip -4 addr show | grep -v '127.0.0.1' | grep inet | head -n 1 | awk '{print $2}' | cut -d/ -f1 && (ip addr show tun0 &>/dev/null && echo true || echo false)"]
        running: true
        
        stdout: SplitParser {
            onRead: (msg, index) => {
                if (index == 0) root.localIp = msg.trim() || "Offline";
                else if (index == 1) root.vpnActive = (msg.trim() === "true");
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: targetProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: root.vpnActive ? "󰖂" : "󱂇"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: root.vpnActive ? Theme.green : Theme.subtext0 // Subtle colors for the clean vibe
        }

        Text {
            text: root.localIp
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
}
