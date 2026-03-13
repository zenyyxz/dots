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

    property string ssid: "Disconnected"
    property real signal: 0.0

    Process {
        id: netProc
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi | grep '^yes' | awk -F: '{print $2 \"|\" $3}'"]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.split("|");
                if (parts.length >= 2) {
                    root.ssid = parts[0] || "Connected";
                    root.signal = parseInt(parts[1]) / 100.0;
                } else {
                    root.ssid = "Disconnected";
                    root.signal = 0.0;
                }
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: netProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        ProgressCircle {
            value: root.signal
            color: root.ssid === "Disconnected" ? Theme.red : Theme.sapphire
            
            // Wi-Fi Icon center
            Text {
                anchors.centerIn: parent
                text: "󰖩"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8
                color: parent.color
            }
        }

        Text {
            text: root.ssid
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.maximumWidth: 100
        }
    }
}
