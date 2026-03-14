import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    height: 60
    radius: 16
    color: active ? Theme.mauve : Theme.surface0
    border.color: active ? "transparent" : Theme.surface1
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            width: 36; height: 36; radius: 10
            color: root.active ? Qt.rgba(0,0,0,0.1) : Theme.surface1
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                color: root.active ? Theme.base : Theme.mauve
            }
        }

        ColumnLayout {
            spacing: 0
            Text { text: root.label; color: root.active ? Theme.base : Theme.text; font.family: Theme.fontName; font.pixelSize: 13; font.bold: true }
            Text { text: root.active ? "On" : "Off"; color: root.active ? Theme.base : Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11; opacity: 0.8 }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.clicked() }
}
