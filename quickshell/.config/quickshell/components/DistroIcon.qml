import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

Rectangle {
    id: root
    
    // Custom clicked signal
    signal clicked()
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: mouseArea.containsMouse ? Theme.blue : Theme.borderColor
    border.width: Theme.borderWidth
    
    width: 32
    height: 32

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    Text {
        anchors.centerIn: parent
        text: "󰣇"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        color: Theme.blue
        
        scale: mouseArea.containsMouse ? 1.1 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked() // Emit the signal
    }
}
