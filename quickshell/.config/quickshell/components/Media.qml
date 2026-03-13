import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    // Use 'Mpris' singleton instead of 'MprisController'
    readonly property MprisPlayer player: Mpris.activePlayer

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: MediaController.show(player?.trackTitle || "", player?.trackArtist || "", player?.trackArt || "", player?.playbackState === Mpris.Playing, root)
        onExited: MediaController.hide()
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) player?.togglePlaying();
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        ProgressCircle {
            value: (player && player.length > 0) ? (player.position / player.length) : 0
            color: Theme.mauve
            
            Text {
                anchors.centerIn: parent
                text: player && player.playbackState === Mpris.Playing ? "󰏤" : "󰝚"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: parent.color
            }
        }

        Text {
            text: {
                if (!player) return "No Media";
                return (player.trackTitle || "Unknown") + (player.trackArtist ? " • " + player.trackArtist : "");
            }
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
            elide: Text.ElideRight
            Layout.maximumWidth: 180
        }
    }
}
