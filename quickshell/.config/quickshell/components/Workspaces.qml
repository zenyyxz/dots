import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

    property int activeWorkspace: 1

    Socket {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
        connected: true

        parser: SplitParser {
            onRead: msg => {
                if (msg.startsWith("workspace>>") || msg.startsWith("workspacev2>>")) {
                    const parts = msg.split(">>")[1].split(",");
                    const wsId = parseInt(parts[0]);
                    if (!isNaN(wsId)) {
                        root.activeWorkspace = wsId;
                    }
                }
            }
        }
    }

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
