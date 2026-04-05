import QtQuick
import QtQuick.Controls
import "../theme"

CheckBox {
    id: control
    
    indicator: Rectangle {
        implicitWidth: 14 // Smaller
        implicitHeight: 14 // Smaller
        radius: 3
        color: control.checked ? Theme.mauve : "transparent"
        border.color: control.checked ? Theme.mauve : Theme.surface1
        border.width: Theme.borderWidth

        Rectangle {
            width: 8
            height: 8
            anchors.centerIn: parent
            radius: 2
            color: Theme.crust
            visible: control.checked
        }
    }
}
