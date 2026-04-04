import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

Rectangle {
    id: root
    
    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        if (players.length === 0) return null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === Mpris.Playing) return players[i];
        }
        return players[0];
    }

    readonly property bool isPlaying: player && player.playbackState === Mpris.Playing
    readonly property bool hasMedia: player !== null

    function getArt(art) {
        if (!art || art === "") return "";
        if (art.startsWith("file://") || art.startsWith("http")) return art;
        if (art.startsWith("/")) return "file://" + art;
        return art;
    }

    implicitWidth: hasMedia ? playingLayout.implicitWidth + 24 : idleLayout.implicitWidth + 20
    implicitHeight: 32
    radius: Theme.radius
    color: hasMedia ? Theme.sapphire : Theme.base
    border.color: isPlaying ? Qt.darker(Theme.sapphire, 1.2) : Theme.borderColor
    border.width: 1

    Behavior on implicitWidth { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on color { ColorAnimation { duration: 300 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) player?.togglePlaying();
        }
    }

    RowLayout {
        id: idleLayout
        anchors.centerIn: parent
        visible: !hasMedia
        spacing: 8
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Text { text: "󰝚"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Theme.subtext0 }
        Text { text: "No Media"; font.family: Theme.fontName; font.pixelSize: 11; color: Theme.subtext0 }
    }

    RowLayout {
        id: playingLayout
        anchors.centerIn: parent
        visible: hasMedia
        spacing: 12
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // --- CIRCULAR ROTATING ART ---
        Item {
            width: 26; height: 26
            
            Image {
                id: albumArtSource
                source: {
                    if (!player) return "";
                    let a = player.trackArt || player.metadata["mpris:artUrl"] || player.metadata["artUrl"] || "";
                    return root.getArt(a);
                }
                visible: false
                asynchronous: true
                onStatusChanged: if (status === Image.Ready) artCanvas.requestPaint()
            }

            Canvas {
                id: artCanvas
                anchors.fill: parent
                property real rotationAngle: 0
                
                RotationAnimation on rotationAngle {
                    from: 0; to: 360; duration: 8000
                    running: isPlaying
                    loops: Animation.Infinite
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var hasArt = (albumArtSource.status === Image.Ready);
                    
                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(width/2, height/2, width/2 - 1, 0, 2 * Math.PI);
                    ctx.clip();
                    
                    ctx.translate(width/2, height/2);
                    ctx.rotate(rotationAngle * Math.PI / 180);
                    ctx.translate(-width/2, -height/2);
                    
                    if (hasArt) {
                        ctx.drawImage(albumArtSource, 0, 0, width, height);
                    } else {
                        ctx.fillStyle = Theme.mantle;
                        ctx.fill();
                    }
                    ctx.restore();

                    // Fallback icon drawn over the circle if no art
                    if (!hasArt) {
                        ctx.fillStyle = Theme.base;
                        ctx.font = "12px 'JetBrainsMono Nerd Font'";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        ctx.fillText(isPlaying ? "󰏤" : "󰝚", width/2, height/2);
                    }

                // Progress Ring (Outer)
                var progress = (player && player.length > 0) ? (player.position / player.length) : 0;
                ctx.beginPath();
                ctx.arc(width/2, height/2, width/2 - 1, -Math.PI/2, progress * 2 * Math.PI - Math.PI/2);
                ctx.strokeStyle = Theme.mauve;
                ctx.lineWidth = 2;
                ctx.stroke();
            }

            // Real-time progress update timer (Fast & Constant for testing)
            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: artCanvas.requestPaint()
            }

            Connections {
                    target: player
                    function onPositionChanged() { artCanvas.requestPaint(); }
                }
                
                onRotationAngleChanged: requestPaint()
            }
        }

        ColumnLayout {
            spacing: -2
            Layout.maximumWidth: 150
            Text {
                text: player?.trackTitle || "Unknown"
                color: Theme.base; font.family: Theme.fontName; font.pixelSize: 11; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: player?.trackArtist || "Unknown Artist"
                color: Qt.rgba(0,0,0,0.6); font.family: Theme.fontName; font.pixelSize: 9
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }

        RowLayout {
            spacing: 8
            visible: mouseArea.containsMouse
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Text {
                text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Qt.rgba(0,0,0,0.5)
                MouseArea { anchors.fill: parent; onClicked: player?.previous() }
            }
            Text {
                text: isPlaying ? "󰏤" : "󰐊"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: Theme.base
                MouseArea { anchors.fill: parent; onClicked: player?.togglePlaying() }
            }
            Text {
                text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: Qt.rgba(0,0,0,0.5)
                MouseArea { anchors.fill: parent; onClicked: player?.next() }
            }
        }
    }
}
