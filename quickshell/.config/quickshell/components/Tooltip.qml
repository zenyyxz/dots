import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: tooltip
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "tooltip"

    anchors {
        top: true
        left: true
    }

    margins {
        left: TooltipController.pos.x - (implicitWidth / 2)
        top: TooltipController.pos.y + 40
    }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 32
    color: "transparent"
    
    visible: TooltipController.active && TooltipController.text !== ""

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 8
        border.color: Theme.borderColor
        border.width: 1
        
        opacity: TooltipController.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: TooltipController.text
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize - 1
            font.bold: true
        }
    }
}
