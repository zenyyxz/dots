import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

Rectangle {
    id: root
    
    // 1. Reactive Player Selection
    readonly property MprisPlayer player: Mpris.activePlayer || (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)
    readonly property bool isPlaying: player && (player.playbackState === Mpris.Playing || player.playbackState === 1)
    readonly property bool hasMedia: player !== null
    
    // Stability Grace Period
    property bool showPlayingUI: hasMedia || hideTimer.running
    Timer { id: hideTimer; interval: 1000; running: false; repeat: false }
    onHasMediaChanged: if (!hasMedia) hideTimer.start(); else hideTimer.stop();

    function getArt(art) {
        if (!art || art === "") return "";
        if (art.startsWith("file://") || art.startsWith("http") || art.startsWith("image://")) return art;
        if (art.startsWith("/")) return "file://" + art;
        return art;
    }

    readonly property bool isHovered: mouseArea.containsMouse || prevMouse.containsMouse || playMouse.containsMouse || nextMouse.containsMouse
    property bool activeHover: false
    Timer {
        id: hoverDebounce
        interval: 50
        running: true
        repeat: true
        onTriggered: activeHover = isHovered
    }

    implicitWidth: showPlayingUI ? (activeHover ? 280 : 220) : 0
    implicitHeight: 32
    radius: Theme.radius
    color: showPlayingUI ? Theme.sapphire : Theme.base
    border.color: isPlaying ? Qt.darker(Theme.sapphire, 1.2) : Theme.borderColor
    border.width: showPlayingUI ? 1 : 0
    visible: showPlayingUI || width > 0

    Behavior on implicitWidth { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 500; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: showPlayingUI
        
        property int clickCount: 0
        Timer {
            id: clickTimer
            interval: 250
            onTriggered: {
                if (mouseArea.clickCount === 1) player?.togglePlaying();
                else if (mouseArea.clickCount === 2) player?.next();
                else if (mouseArea.clickCount >= 3) player?.previous();
                mouseArea.clickCount = 0;
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                clickCount++;
                clickTimer.restart();
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 24
        spacing: 12
        visible: showPlayingUI

        // --- VINYL STACK ---
        Item {
            width: 26; height: 26
            opacity: hasMedia ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            Image {
                id: albumArtSource
                source: (player && (player.trackArt || player.metadata["mpris:artUrl"] || player.metadata["artUrl"])) ? root.getArt(player.trackArt || player.metadata["mpris:artUrl"] || player.metadata["artUrl"]) : ""
                visible: false; asynchronous: false
                onStatusChanged: if (status === Image.Ready) vinylCanvas.requestPaint()
            }

            Item {
                id: vinylRotationWrapper
                anchors.fill: parent
                
                RotationAnimation {
                    target: vinylRotationWrapper
                    property: "rotation"
                    from: 0; to: 360; duration: 12000;
                    loops: Animation.Infinite
                    direction: RotationAnimation.Clockwise
                    running: root.hasMedia
                    paused: !root.isPlaying
                }

                Canvas {
                    id: vinylCanvas
                    anchors.fill: parent
                    
                    // Force repaint on rotation for some drivers
                    onRotationChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.save();
                        
                        // Draw main circle / Art
                        ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, 0, 2 * Math.PI); ctx.clip();
                        ctx.fillStyle = Theme.mantle; ctx.fill();
                        if (albumArtSource.status === Image.Ready) {
                            ctx.drawImage(albumArtSource, 0, 0, width, height);
                        }
                        
                        // Draw center hole
                        ctx.beginPath(); ctx.arc(width/2, height/2, 2, 0, 2 * Math.PI);
                        ctx.fillStyle = Theme.base; ctx.fill();
                        
                        ctx.restore();
                    }
                }
            }

            Canvas {
                id: ringCanvas
                anchors.fill: parent
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    if (albumArtSource.status !== Image.Ready) {
                        ctx.fillStyle = Theme.base; ctx.font = "12px 'JetBrainsMono Nerd Font'";
                        ctx.textAlign = "center"; ctx.textBaseline = "middle";
                        ctx.fillText(isPlaying ? "󰏤" : "󰝚", width/2, height/2);
                    }

                    var progress = (player && player.length > 0) ? (player.position / player.length) : 0;
                    ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, 0, 2 * Math.PI);
                    ctx.strokeStyle = Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.1); 
                    ctx.lineWidth = 2; ctx.stroke();
                    ctx.beginPath(); ctx.arc(width/2, height/2, width/2 - 1, -Math.PI/2, progress * 2 * Math.PI - Math.PI/2);
                    ctx.strokeStyle = Theme.yellow; 
                    ctx.lineWidth = 2; ctx.stroke();
                }
                
                // Aggressive Refresh Timer: Runs whenever media is present
                Timer { 
                    interval: 250; 
                    running: root.hasMedia; 
                    repeat: true; 
                    onTriggered: ringCanvas.requestPaint() 
                }
            }
        }

        ColumnLayout {
            spacing: -2
            Layout.fillWidth: true
            visible: showPlayingUI
            opacity: hasMedia ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            
            Text {
                text: player?.trackTitle || "No Media"
                color: Theme.base; font.family: Theme.fontName; font.pixelSize: 11; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 400 } }
            }
            Text {
                text: player?.trackArtist || "Waiting..."
                color: Qt.rgba(0,0,0,0.6); font.family: Theme.fontName; font.pixelSize: 9
                elide: Text.ElideRight; Layout.fillWidth: true
                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }

        RowLayout {
            id: controls
            spacing: activeHover ? 8 : 0
            Layout.preferredWidth: activeHover ? 70 : 0
            clip: true
            opacity: activeHover ? 1.0 : 0.0
            visible: showPlayingUI
            Layout.alignment: Qt.AlignVCenter
            
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
            Behavior on spacing { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            
            Item {
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.rgba(255, 255, 255, 0.1)
                    visible: prevMouse.containsMouse
                    opacity: prevMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                    color: prevMouse.containsMouse ? Theme.base : Qt.rgba(0,0,0,0.5)
                    renderType: Text.NativeRendering
                    scale: prevMouse.containsMouse ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: player?.previous() }
            }

            Item {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.rgba(255, 255, 255, 0.15)
                    visible: playMouse.containsMouse
                    opacity: playMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: isPlaying ? "󰏤" : "󰐊"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16
                    color: Theme.base; renderType: Text.NativeRendering
                    scale: playMouse.containsMouse ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                }
                MouseArea { id: playMouse; anchors.fill: parent; hoverEnabled: true; onClicked: player?.togglePlaying() }
            }

            Item {
                Layout.preferredWidth: 22; Layout.preferredHeight: 22
                
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.rgba(255, 255, 255, 0.1)
                    visible: nextMouse.containsMouse
                    opacity: nextMouse.containsMouse ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
                    color: nextMouse.containsMouse ? Theme.base : Qt.rgba(0,0,0,0.5)
                    renderType: Text.NativeRendering
                    scale: nextMouse.containsMouse ? 1.1 : 1.0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: player?.next() }
            }
        }
    }
}
