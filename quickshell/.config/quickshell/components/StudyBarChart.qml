import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    property var history: []
    property real maxHours: 8.0
    property bool liveReload: false
    signal toggleLiveReload()
    
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
                
                background: Rectangle {
                    radius: 12
                    color: root.liveReload ? Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.15) : Theme.surface1
                    border.color: root.liveReload ? Theme.green : Theme.surface2
                    border.width: 1
                }

                contentItem: Row {
                    spacing: 4
                    anchors.centerIn: parent
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
                        font.family: Theme.fontName
                        font.pixelSize: 9
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                onClicked: root.toggleLiveReload()
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
                                font.family: Theme.fontName
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
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: "󰄬"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: Theme.teal
                }

                Text {
                    Layout.fillWidth: true
                    text: "Study like there's no tomorrow."
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    font.italic: true
                    wrapMode: Text.WordWrap
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
                                        width: parent.width
                                        height: 12
                                        radius: 5
                                        
                                        readonly property int pillIndex: 15 - index
                                        readonly property bool active: pillIndex < Math.floor(barCol.hours)
                                        
                                        color: {
                                            if (!active) return Theme.surface1;
                                            if (pillIndex < 4) return Theme.sky;
                                            if (pillIndex < 8) return Theme.teal;
                                            if (pillIndex < 12) return Theme.lavender;
                                            return Theme.mauve;
                                        }
                                        
                                        opacity: active ? 1.0 : 0.3
                                        Behavior on opacity { NumberAnimation { duration: 400 } }
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
                            text: modelData.day
                            color: Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }
        }
    }
}
