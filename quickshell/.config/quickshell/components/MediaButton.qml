import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root
    property string icon: ""
    property color color: Theme.text
    property int size: 24
    property bool primary: false
    signal clicked()

    implicitWidth: size + 16
    implicitHeight: size + 16

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: primary ? (width / 2) : 8
        color: primary ? Theme.mauve : Theme.surface0
        opacity: mouseArea.containsMouse ? (primary ? 0.8 : 0.4) : (primary ? 1.0 : 0.0)
        
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.size
        color: primary ? Theme.base : root.color
        
        scale: mouseArea.containsMouse ? 1.1 : 1.0
        Behavior on scale { 
            NumberAnimation { 
                duration: 200
                easing.type: Easing.OutBack 
            } 
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
