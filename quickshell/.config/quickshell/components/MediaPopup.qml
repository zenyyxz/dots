import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../theme"

PanelWindow {
    id: popup
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "media-popup"
    
    // Use WlrLayershell.None instead of KeyboardFocus.None
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        top: true
        left: true
    }
    
    margins {
        left: MediaController.pos.x - (implicitWidth / 2)
        top: MediaController.pos.y + 12
    }

    // Use implicitWidth/Height to avoid deprecation warnings
    implicitWidth: 420
    implicitHeight: 180
    color: "transparent"
    
    visible: MediaController.shouldBeVisible || container.opacity > 0

    // Use 'Mpris' singleton
    readonly property MprisPlayer player: Mpris.activePlayer

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return m + ":" + s.toString().padStart(2, '0');
    }

    property real waveOffset: 0.0
    Timer {
        interval: 50
        running: player && player.playbackState === Mpris.Playing
        repeat: true
        onTriggered: popup.waveOffset += 0.15
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: MediaController.shouldBeVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: MediaController.popupHovered = true
            onExited: MediaController.popupHovered = false
            propagateComposedEvents: true
            onPressed: (mouse) => mouse.accepted = false
        }

        Image {
            id: bgArt
            anchors.fill: parent
            source: player?.trackArt || ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3
            visible: player?.trackArt !== ""
        }

        FastBlur {
            anchors.fill: bgArt
            source: bgArt
            radius: 64
            transparentBorder: true
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width + 20
            height: 80
            spacing: 2
            opacity: 0.25

            Repeater {
                model: 50
                delegate: Rectangle {
                    width: 6
                    height: {
                        if (!player || player.playbackState !== Mpris.Playing) return 4;
                        const s1 = Math.sin(index * 0.3 + popup.waveOffset) * 25;
                        const s2 = Math.sin(index * 0.7 - popup.waveOffset * 0.5) * 15;
                        return Math.max(4, 30 + s1 + s2 + (Math.random() * 5));
                    }
                    radius: 3
                    color: Theme.mauve
                    anchors.bottom: parent.bottom
                    Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            RowLayout {
                spacing: 20
                Layout.fillWidth: true

                Rectangle {
                    width: 100; height: 100; radius: 16
                    color: Theme.surface0
                    clip: true
                    
                    Image {
                        id: mainArt
                        anchors.fill: parent
                        source: player?.trackArt || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 32
                        visible: !player?.trackArt || mainArt.status !== Image.Ready
                        color: Theme.subtext0
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: player?.trackTitle || "No Media"
                            color: Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 18; font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: player?.trackArtist || "Unknown Artist"
                            color: Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    RowLayout {
                        spacing: 8
                        
                        MediaButton { 
                            icon: "󰒮"; size: 18; color: Theme.subtext0
                            onClicked: player?.previous()
                        }
                        MediaButton { 
                            icon: player?.playbackState === Mpris.Playing ? "󰏤" : "󰐊"; 
                            size: 32; primary: true
                            onClicked: player?.togglePlaying()
                        }
                        MediaButton { 
                            icon: "󰒭"; size: 18; color: Theme.subtext0
                            onClicked: player?.next()
                        }
                        
                        Item { width: 10 }

                        MediaButton { 
                            icon: "󰒝"; size: 14; 
                            color: player?.shuffle ? Theme.mauve : Theme.surface2
                            onClicked: player.shuffle = !player.shuffle
                        }
                        MediaButton { 
                            icon: "󰑖"; size: 14; 
                            color: player?.loopStatus !== Mpris.None ? Theme.mauve : Theme.surface2
                            onClicked: {
                                if (player.loopStatus === Mpris.None) player.loopStatus = Mpris.Playlist;
                                else player.loopStatus = Mpris.None;
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 6; radius: 3; color: Theme.surface0

                    Rectangle {
                        width: parent.width * ((player && player.length > 0) ? (player.position / player.length) : 0)
                        height: parent.height
                        radius: 3; color: Theme.mauve
                        Behavior on width { NumberAnimation { duration: 500 } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: popup.formatTime(player?.position || 0)
                        color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: popup.formatTime(player?.length || 0)
                        color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
