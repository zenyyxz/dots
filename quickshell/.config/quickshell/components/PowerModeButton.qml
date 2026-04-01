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
    height: 64
    radius: 16
    
    color: active ? Theme.mauve : Theme.surface0
    Behavior on color { ColorAnimation { duration: 250 } }
    
    border.color: active ? "transparent" : Theme.surface1
    border.width: 1

    scale: mouseArea.pressed ? 0.94 : (mouseArea.containsMouse ? 1.04 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: root.active ? Theme.base : Theme.mauve
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.family: Theme.fontName
            font.pixelSize: 9
            font.bold: true
            color: root.active ? Theme.base : Theme.subtext0
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    MouseArea { 
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked() 
    }
}
