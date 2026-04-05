import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    
    property var history: []
    property real maxHours: 8.0
    
    radius: Theme.radius
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: 1
    
    implicitWidth: 400
    implicitHeight: 300

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
        anchors.margins: 20
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "History"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 18
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "Avg: " + root.getAverage().toFixed(1) + "h"
                color: Theme.mauve
                font.family: Theme.fontName
                font.pixelSize: 12
            }
        }

        Row {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Repeater {
                model: root.history
                delegate: ColumnLayout {
                    id: barCol
                    width: (parent.width - (parent.spacing * 6)) / 7
                    height: parent.height
                    spacing: 4
                    
                    readonly property real hours: modelData.seconds / 3600
                    
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(4, Math.min(parent.height, (barCol.hours / root.maxHours) * parent.height))
                            radius: 4
                            color: Theme.mauve
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                        }
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.day
                        color: Theme.subtext0
                        font.family: Theme.fontName
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
