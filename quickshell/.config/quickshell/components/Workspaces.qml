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
                id: dot
                readonly property int index_one: index + 1
                readonly property bool isActive: root.activeWorkspace == index_one
                
                // Reactive property to check if workspace is occupied
                readonly property bool isOccupied: {
                    const workspaces = Hyprland.workspaces.values;
                    for (let i = 0; i < workspaces.length; i++) {
                        if (workspaces[i].id === index_one) return true;
                    }
                    return false;
                }
                
                width: isActive ? 24 : 8
                height: 8
                radius: 4
                
                // Color logic: Active (Mauve), Hover (Sapphire), Occupied (Blue), Empty (Surface1)
                color: {
                    if (isActive) return Theme.mauve;
                    if (mouseArea.containsMouse) return Theme.sapphire;
                    if (isOccupied) return Theme.blue;
                    return Theme.surface1;
                }
                
                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }
                
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4 // Larger clickable area for small dots
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", index_one.toString()])
                }
            }
        }
    }
}
