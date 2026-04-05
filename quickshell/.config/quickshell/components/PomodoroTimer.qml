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
    
    property int selectedSubjectId: -1
    property var subjects: []
    StudyService { id: service }

    Component.onCompleted: {
        service.getSubjects((data) => {
            subjects = data;
            if (data.length > 0) selectedSubjectId = data[0].id;
        });
    }

    signal finished(int totalSeconds, int subjectId)
    
    radius: Theme.radius
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: 1
    
    implicitWidth: 300
    implicitHeight: 380

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
                    root.finished(25 * 60, root.selectedSubjectId);
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "Pomodoro"
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Subject Selector
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            
            RowLayout {
                spacing: 8
                Repeater {
                    model: root.subjects
                    delegate: Rectangle {
                        height: 25
                        implicitWidth: subLabel.implicitWidth + 20
                        radius: 12
                        color: root.selectedSubjectId === modelData.id ? Theme.mauve : Theme.surface1
                        border.color: root.selectedSubjectId === modelData.id ? Theme.mauve : "transparent"
                        
                        Text {
                            id: subLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            color: root.selectedSubjectId === modelData.id ? Theme.crust : Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 10
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectedSubjectId = modelData.id
                        }
                    }
                }
            }
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
            Layout.preferredHeight: 120
            
            Rectangle {
                anchors.centerIn: parent
                width: 120; height: 120; radius: 60
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
                font.pixelSize: 36
                font.bold: true
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Button {
                id: startBtn
                padding: 10
                background: Rectangle {
                    radius: 8
                    color: startBtn.hovered ? Theme.surface1 : "transparent"
                    border.color: Theme.mauve
                    border.width: 1
                }
                contentItem: Text {
                    text: root.running ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: Theme.mauve
                }
                onClicked: root.running = !root.running
            }

            Button {
                id: resetBtn
                padding: 10
                background: Rectangle {
                    radius: 8
                    color: resetBtn.hovered ? Theme.surface1 : "transparent"
                    border.color: Theme.subtext0
                    border.width: 1
                }
                contentItem: Text {
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: Theme.subtext0
                }
                onClicked: root.setMode(root.mode)
            }
        }
    }
}
