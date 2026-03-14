import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    // Explicitly bind width to content plus padding
    width: row.width + 24
    height: 32

    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: 10
            delegate: Rectangle {
                readonly property int index_one: index + 1
                readonly property bool isActive: root.activeWorkspace == index_one
                
                width: isActive ? 24 : 8
                height: 8
                radius: 4
                
                color: isActive ? Theme.mauve : Theme.surface1
                
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }
                
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animDuration
                    }
                }
            }
        }
    }
}
