import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    property string timeStr: "--:--"
    property string dateStr: "---"

    function updateTime() {
        const d = new Date();
        root.timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
        
        // Stylish date: SAT, MAR 14
        const options = { weekday: 'short', month: 'short', day: 'numeric' };
        root.dateStr = d.toLocaleDateString(undefined, options).toUpperCase();
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: updateTime()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Behavior on color { ColorAnimation { duration: 250 } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        // Icon Section
        Text {
            text: "󱑂"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: Theme.mauve
            opacity: mouseArea.containsMouse ? 1.0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Stacked Time & Date
        ColumnLayout {
            spacing: -4 // Tight stacking for aesthetic
            
            Text {
                Layout.alignment: Qt.AlignLeft
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 12
                font.bold: true
                text: root.timeStr
            }

            Text {
                Layout.alignment: Qt.AlignLeft
                color: Theme.subtext0
                font.family: Theme.fontName
                font.pixelSize: 8
                font.weight: Font.Black
                text: root.dateStr
                letterSpacing: 0.5
            }
        }
    }
}
