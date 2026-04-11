import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    property var history: []
    property real maxHours: 8.0
    property bool liveReload: false
    property bool authenticated: false
    property string motivation: "Study like there's no tomorrow."
    signal toggleLiveReload()
    signal timeSet(string date, int seconds)
    
    StudyService { id: service }

    Component.onCompleted: {
        service.getConfig("motivation_quote", (val) => {
            if (val) root.motivation = val;
        });
    }

    radius: Theme.radius
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: 1
    
    width: 400
    height: 300

    function getAverage() {
        if (!history || history.length === 0) return 0;
        let total = 0;
        for (let i = 0; i < history.length; i++) {
            total += history[i].seconds;
        }
        return (total / history.length) / 3600;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Text {
                text: "History"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 22
                font.bold: true
                Layout.fillWidth: true
            }

            // --- Live Reload Toggle Button ---
            Button {
                id: liveToggle
                width: 60; height: 24
                enabled: root.authenticated
                
                background: Rectangle {
                    radius: 12
                    color: root.liveReload ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15) : Theme.surface1
                    border.color: root.liveReload ? Theme.green : Theme.surface2
                    border.width: 1
                    opacity: root.authenticated ? 1.0 : 0.5
                }

                contentItem: Row {
                    spacing: 4
                    anchors.centerIn: parent
                    opacity: root.authenticated ? 1.0 : 0.5
                    
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: root.liveReload ? Theme.green : Theme.subtext0
                        anchors.verticalCenter: parent.verticalCenter
                        
                        SequentialAnimation on opacity {
                            running: root.liveReload
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }
                    Text {
                        text: "LIVE"
                        color: root.liveReload ? Theme.green : Theme.subtext0
                        font.family: Theme.smallFontName
                        font.pixelSize: 9
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                onClicked: root.toggleLiveReload()
            }

            // --- Auth Button ---
            Button {
                id: authButton
                padding: 4
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                
                background: Rectangle {
                    radius: 6
                    color: authButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: authButton.pressed ? Theme.mauve : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                contentItem: Image {
                    source: root.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: root.authenticated ? Theme.green : Theme.red
                    }
                    opacity: authButton.hovered ? 1.0 : 0.8
                }
                
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                
                onClicked: root.authenticated = !root.authenticated
            }
        }

        // --- Summary Stats Pill ---
        Rectangle {
            id: statsPill
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1
            
            readonly property real todayHours: (root.history && root.history.length > 0) ? root.history[root.history.length - 1].seconds / 3600 : 0
            readonly property real yesterdayHours: (root.history && root.history.length > 1) ? root.history[root.history.length - 2].seconds / 3600 : 0

            Row {
                anchors.centerIn: parent
                spacing: 50

                Repeater {
                    model: [
                        { val: statsPill.yesterdayHours.toFixed(1) + "h", color: Theme.subtext0, label: "Yest" },
                        { val: statsPill.todayHours.toFixed(1) + "h", color: Theme.teal, label: "Today" },
                        { val: root.getAverage().toFixed(1) + "h", color: Theme.mauve, label: "Avg" }
                    ]
                    delegate: Row {
                        spacing: 25
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: -2
                            Text { 
                                text: modelData.label
                                color: Theme.subtext0
                                font.family: Theme.smallFontName
                                font.pixelSize: 9
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text { 
                                text: modelData.val
                                color: modelData.color
                                font.family: Theme.fontName
                                font.pixelSize: 20
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        
                        // Vertical Separator
                        Rectangle {
                            visible: index < 2
                            width: 1; height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.surface1
                            opacity: 0.3
                        }
                    }
                }
            }
        }

        // --- Motivation Box ---
        Rectangle {
            id: motivationBox
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            radius: 10
            color: root.authenticated ? Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.05) : Theme.surface0
            border.color: root.authenticated ? Theme.teal : Theme.surface1
            border.width: 1
            Behavior on color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: root.authenticated ? "󰏫" : "󰄬"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: Theme.teal
                }

                TextInput {
                    id: motivationInput
                    Layout.fillWidth: true
                    text: root.motivation
                    color: Theme.text
                    font.family: Theme.smallFontName
                    font.pixelSize: 10
                    font.italic: !root.authenticated
                    enabled: root.authenticated
                    selectByMouse: true
                    
                    onEditingFinished: {
                        if (text !== root.motivation) {
                            root.motivation = text;
                            service.setConfig("motivation_quote", text);
                        }
                    }
                }
            }
        }

        // --- Chart ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                anchors.fill: parent
                spacing: 10

                Repeater {
                    model: root.history
                    delegate: ColumnLayout {
                        id: barCol
                        width: (parent.width - (parent.spacing * 6)) / 7
                        height: parent.height
                        spacing: 6
                        
                        readonly property string date: modelData.date
                        readonly property string day: modelData.day
                        readonly property real hours: modelData.seconds / 3600
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                spacing: 3
                                
                                Repeater {
                                    model: 16
                                    delegate: Rectangle {
                                        id: pill
                                        width: parent.width
                                        height: 12
                                        radius: 5
                                        
                                        readonly property int pillIndex: 15 - index
                                        readonly property bool active: pillIndex < Math.floor(barCol.hours)
                                        property bool showNumber: false
                                        
                                        color: {
                                            if (root.authenticated && pillHover.containsMouse) {
                                                return active ? Theme.red : Theme.green;
                                            }
                                            if (!active) return Theme.surface1;
                                            if (pillIndex < 4) return Theme.sky;
                                            if (pillIndex < 8) return Theme.teal;
                                            if (pillIndex < 12) return Theme.lavender;
                                            return Theme.mauve;
                                        }
                                        
                                        opacity: (active || (root.authenticated && pillHover.containsMouse)) ? 1.0 : 0.3
                                        Behavior on opacity { NumberAnimation { duration: 400 } }

                                        Timer {
                                            id: hideTimer
                                            interval: 2000 // 2 seconds delay
                                            onTriggered: pill.showNumber = false
                                        }

                                        MouseArea {
                                            id: pillHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: root.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onEntered: {
                                                if (!root.authenticated) {
                                                    hideTimer.stop();
                                                    pill.showNumber = true;
                                                }
                                            }
                                            onExited: {
                                                if (!root.authenticated) {
                                                    hideTimer.start();
                                                }
                                            }
                                            onClicked: {
                                                if (root.authenticated) {
                                                    // Set total time to this pill's level (1-indexed)
                                                    let targetSeconds = (pillIndex + 1) * 3600;
                                                    
                                                    // Special case: if clicking exactly the current highest active pill, 
                                                    // AND the bar is not exactly a full hour (e.g. 2.5 hours), 
                                                    // should it round up to 3 or set to exactly 3?
                                                    // Requirement says: "fill up all pills up to 5th pill".
                                                    // And "remove 4th and 5th pills" if clicking 3rd.
                                                    
                                                    root.timeSet(barCol.date, targetSeconds);
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (root.authenticated) return active ? "－" : "＋";
                                                return (pillIndex + 1).toString();
                                            }
                                            color: Theme.crust
                                            font.family: Theme.smallFontName
                                            font.pixelSize: root.authenticated ? 12 : 9
                                            font.weight: Font.DemiBold
                                            
                                            opacity: {
                                                if (root.authenticated) return pillHover.containsMouse ? 1.0 : 0.0;
                                                return pill.active && pill.showNumber ? 1.0 : 0.0;
                                            }
                                            scale: opacity
                                            
                                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: barCol.hours.toFixed(1) + "h"
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 9
                                font.bold: true
                                visible: barCol.hours > 0
                            }
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: barCol.day
                            color: Theme.subtext0
                            font.family: Theme.smallFontName
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
