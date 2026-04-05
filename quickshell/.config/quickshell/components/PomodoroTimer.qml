import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: root
    
    property int secondsRemaining: 25 * 60
    property bool running: false
    property string mode: "focus" // focus, short, long
    
    signal finished(int totalSeconds)
    
    radius: Theme.radius
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: 1
    
    implicitWidth: 300
    implicitHeight: 350

    function setMode(newMode) {
        root.running = false;
        root.mode = newMode;
        if (newMode === "focus") root.secondsRemaining = 25 * 60;
        else if (newMode === "short") root.secondsRemaining = 5 * 60;
        else if (newMode === "long") root.secondsRemaining = 15 * 60;
    }

    function formatTime(s) {
        let mins = Math.floor(s / 60);
        let secs = s % 60;
        return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    Timer {
        id: mainTimer
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.secondsRemaining > 0) {
                root.secondsRemaining--;
            } else {
                root.running = false;
                if (root.mode === "focus") {
                    root.finished(25 * 60);
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "Pomodoro"
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            
            Button {
                text: "Focus"
                flat: true
                onClicked: root.setMode("focus")
                contentItem: Text {
                    text: parent.text
                    color: root.mode === "focus" ? Theme.mauve : Theme.subtext0
                    font.family: Theme.fontName
                    font.bold: root.mode === "focus"
                }
            }
            Button {
                text: "Short"
                flat: true
                onClicked: root.setMode("short")
                contentItem: Text {
                    text: parent.text
                    color: root.mode === "short" ? Theme.green : Theme.subtext0
                    font.family: Theme.fontName
                    font.bold: root.mode === "short"
                }
            }
            Button {
                text: "Long"
                flat: true
                onClicked: root.setMode("long")
                contentItem: Text {
                    text: parent.text
                    color: root.mode === "long" ? Theme.blue : Theme.subtext0
                    font.family: Theme.fontName
                    font.bold: root.mode === "long"
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            
            Rectangle {
                anchors.centerIn: parent
                width: 140; height: 140; radius: 70
                color: "transparent"
                border.color: root.mode === "focus" ? Theme.mauve : (root.mode === "short" ? Theme.green : Theme.blue)
                border.width: 4
                opacity: 0.3
            }

            Text {
                anchors.centerIn: parent
                text: root.formatTime(root.secondsRemaining)
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 42
                font.bold: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Button {
                id: startBtn
                padding: 12
                background: Rectangle {
                    radius: 8
                    color: startBtn.hovered ? Theme.surface1 : "transparent"
                    border.color: Theme.mauve
                    border.width: 1
                }
                contentItem: Text {
                    text: root.running ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 24
                    color: Theme.mauve
                }
                onClicked: root.running = !root.running
            }

            Button {
                id: resetBtn
                padding: 12
                background: Rectangle {
                    radius: 8
                    color: resetBtn.hovered ? Theme.surface1 : "transparent"
                    border.color: Theme.subtext0
                    border.width: 1
                }
                contentItem: Text {
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 24
                    color: Theme.subtext0
                }
                onClicked: root.setMode(root.mode)
            }
        }
    }
}
