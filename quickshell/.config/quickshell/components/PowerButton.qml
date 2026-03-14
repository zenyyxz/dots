import QtQuick
import "../theme"

Rectangle {
    id: root
    property string icon: ""
    property color accentColor: Theme.mauve
    signal clicked()

    width: 60; height: 60; radius: 30
    color: Theme.surface0; border.color: Theme.surface1; border.width: 1

    Text {
        anchors.centerIn: parent
        text: root.icon; color: root.accentColor; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 24
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.accentColor = Qt.lighter(root.accentColor, 1.2)
        onExited: root.accentColor = root.accentColor
        onClicked: root.clicked()
    }
}
