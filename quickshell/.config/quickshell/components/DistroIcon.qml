import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    width: 32
    height: 32

    Text {
        anchors.centerIn: parent
        text: "󰣇"
        font.family: Theme.fontName
        font.pixelSize: 18
        color: Theme.blue
    }
}
