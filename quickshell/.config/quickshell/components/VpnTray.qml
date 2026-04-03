import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: "transparent"
    radius: 4
    
    implicitWidth: 24
    implicitHeight: 24

    property bool vpnEnabled: false

    Process {
        id: vpnStatusProc
        command: ["bash", "-c", "while true; do ip addr show zen-tun >/dev/null 2>&1 && echo 'on' || echo 'off'; sleep 2; done"]
        running: true
        stdout: SplitParser {
            onRead: msg => { 
                root.vpnEnabled = (msg.trim() === "on");
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipController.show(vpnEnabled ? "VPN: Connected (zen-tun)" : "VPN: Disconnected", root)
        onExited: TooltipController.hide()
        onClicked: {
            root.Shell.root.vpnConfig.isOpen = !root.Shell.root.vpnConfig.isOpen;
        }
    }

    // Hover highlight matching other tray items
    Rectangle {
        anchors.fill: parent
        color: Theme.text
        opacity: mouseArea.containsMouse ? 0.1 : 0
        radius: 4
    }

    Image {
        id: ghostImg
        anchors.fill: parent
        anchors.margins: 4
        source: "../assets/vpn-ghost.svg"
        fillMode: Image.PreserveAspectFit
        visible: false // Hidden so the ColorOverlay can use it
    }

    ColorOverlay {
        anchors.fill: ghostImg
        source: ghostImg
        color: vpnEnabled ? Theme.mauve : Theme.surface2
        opacity: vpnEnabled ? 1.0 : 0.5
        
        Behavior on color { ColorAnimation { duration: 300 } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
}
