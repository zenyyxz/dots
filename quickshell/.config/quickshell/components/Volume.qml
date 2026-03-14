import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0.0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? true

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipController.show(root.muted ? "Audio Muted" : "Volume: " + Math.round(root.volume * 100) + "%", root)
        onExited: TooltipController.hide()
        onClicked: {
            if (Pipewire.defaultAudioSink) {
                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }
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
