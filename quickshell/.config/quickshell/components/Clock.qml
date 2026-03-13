import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    // Consolidate color property into one declaration
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 32

    property string timeStr: "--:--"
    property string dateStr: "---"

    function updateTime() {
        const d = new Date();
        // Time format: 14:05
        root.timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
        
        // Date format: Sat, Mar 14
        const options = { weekday: 'short', month: 'short', day: 'numeric' };
        root.dateStr = d.toLocaleDateString(undefined, options);
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: updateTime()
    }

    // Hover effect
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }

    Behavior on color { ColorAnimation { duration: 200 } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10

        // Time
        Text {
            color: Theme.mauve
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize + 1
            font.bold: true
            text: root.timeStr
        }

        // Dot Separator
        Rectangle {
            width: 4
            height: 4
            radius: 2
            color: Theme.surface1
            Layout.alignment: Qt.AlignCenter
        }

        // Date
        Text {
            color: Theme.subtext0
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            text: root.dateStr
        }
    }
}
