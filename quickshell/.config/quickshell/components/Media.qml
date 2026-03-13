import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    // FIXED WIDTH as requested
    width: 220
    height: 32

    property string trackName: "No Media"
    property string artistName: ""
    property string artUrl: ""
    property string status: "Stopped"
    readonly property bool isPlaying: status === "Playing"
    readonly property bool isExpanded: mouseArea.containsMouse || mouseArea.pressed

    // Fetch Metadata
    Process {
        id: playerProc
        command: ["bash", "-c", "playerctl metadata --format '{{title}}|{{artist}}|{{mpris:artUrl}}|{{status}}' 2>/dev/null || echo 'No Media|||Stopped'"]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.split("|");
                if (parts.length >= 4) {
                    root.trackName = parts[0] || "No Media";
                    root.artistName = parts[1] || "Unknown Artist";
                    root.artUrl = parts[2] || "";
                    root.status = parts[3].trim();
                }
            }
        }
    }

    // Controls
    function playPause() { Quickshell.run(["playerctl", "play-pause"]); }
    function next() { Quickshell.run(["playerctl", "next"]); }
    function prev() { Quickshell.run(["playerctl", "previous"]); }

    Timer {
        interval: 1000; repeat: true; running: true
        onTriggered: playerProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Album Art (Visible in Expanded or No Media)
        Rectangle {
            width: 24; height: 24; radius: 4
            color: Theme.surface1
            clip: true
            visible: root.isExpanded || !root.isPlaying

            Image {
                anchors.fill: parent
                source: root.artUrl !== "" ? root.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
            }
            
            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "JetBrainsMono Nerd Font"
                visible: root.artUrl === ""
                color: Theme.subtext0
            }
        }

        // Wave Visualizer
        Row {
            spacing: 2
            visible: root.isPlaying && !root.isExpanded
            Repeater {
                model: 4
                delegate: Rectangle {
                    width: 2
                    height: root.isPlaying ? (Math.random() * 10 + 4) : 4
                    radius: 1
                    color: Theme.mauve
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on height { NumberAnimation { duration: 150 } }
                }
            }
        }

        // Info
        ColumnLayout {
            spacing: -2
            Layout.fillWidth: true
            
            Text {
                text: root.trackName
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: Theme.fontSize - 1
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.artistName
                color: Theme.subtext0
                font.family: Theme.fontName
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: root.isExpanded && root.artistName !== ""
            }
        }

        // Controls (Visible on hover)
        RowLayout {
            spacing: 6
            visible: root.isExpanded && root.isPlaying
            
            Text { 
                text: "󰒮"; font.family: "JetBrainsMono Nerd Font"; color: Theme.text; font.pixelSize: 12
                MouseArea { anchors.fill: parent; onClicked: root.prev() }
            }
            Text { 
                text: root.isPlaying ? "󰏤" : "󰐊"; font.family: "JetBrainsMono Nerd Font"; color: Theme.mauve; font.pixelSize: 14
                MouseArea { anchors.fill: parent; onClicked: root.playPause() }
            }
            Text { 
                text: "󰒭"; font.family: "JetBrainsMono Nerd Font"; color: Theme.text; font.pixelSize: 12
                MouseArea { anchors.fill: parent; onClicked: root.next() }
            }
        }
    }
}
