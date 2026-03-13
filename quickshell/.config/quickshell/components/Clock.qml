import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 32

    property string timeStr: "--:--"
    property string dateStr: "---"

    function updateTime() {
        const d = new Date();
        root.timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
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

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        Text {
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
            text: root.timeStr
        }

        Rectangle {
            width: 1
            height: 16
            color: Theme.surface1
        }

        Text {
            color: Theme.subtext0
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            text: root.dateStr
        }
    }
}
