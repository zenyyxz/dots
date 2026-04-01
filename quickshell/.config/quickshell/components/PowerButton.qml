import QtQuick
import "../theme"

Rectangle {
    id: root
    property string icon: ""
    property color accentColor: Theme.mauve
    signal clicked()

    width: 60; height: 60; radius: 16
    color: mouseArea.containsMouse ? Theme.surface1 : Theme.surface0
    border.color: mouseArea.containsMouse ? root.accentColor : Theme.surface1
    border.width: 1

    Behavior on color { ColorAnimation { duration: 200 } }
    scale: mouseArea.pressed ? 0.9 : 1.0
    Behavior on scale { NumberAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: root.icon; color: root.accentColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
