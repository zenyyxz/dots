import QtQuick
import QtQuick.Controls
import "../theme"

CheckBox {
    id: control
    
    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: 4
        color: control.checked ? Theme.mauve : "transparent"
        border.color: control.checked ? Theme.mauve : Theme.surface1
        border.width: Theme.borderWidth

        Rectangle {
            width: 10
            height: 10
            anchors.centerIn: parent
            radius: 2
            color: Theme.crust
            visible: control.checked
        }
    }
}
