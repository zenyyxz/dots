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
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    property real volume: 0.0
    property bool muted: false

    Process {
        id: volProc
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const trimmed = msg.trim();
                if (trimmed.startsWith("Volume:")) {
                    root.muted = trimmed.includes("[MUTED]");
                    root.volume = parseFloat(trimmed.split(/\s+/)[1]);
                }
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: volProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipController.show(root.muted ? "Audio Muted" : "Volume: " + Math.round(root.volume * 100) + "%", root)
        onExited: TooltipController.hide()
        onClicked: Quickshell.run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    function getVolIcon() {
        if (root.muted) return "󰝟";
        if (root.volume > 0.6) return "󰕾";
        if (root.volume > 0.3) return "󰖀";
        return "󰕿";
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: getVolIcon()
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: root.muted ? Theme.red : Theme.mauve
        }

        Text {
            text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.red : Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
}
