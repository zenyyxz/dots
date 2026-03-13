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
    
    // Fixed container width to prevent shifting
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32
    
    visible: windowTitle !== ""
    property string windowTitle: "Desktop"

    Socket {
        path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
        connected: true

        parser: SplitParser {
            onRead: msg => {
                if (msg.startsWith("activewindowv2>>")) {
                    const parts = msg.split(">>")[1].split(",");
                    if (parts.length >= 2) {
                        root.windowTitle = parts[1].trim();
                    }
                } else if (msg.startsWith("activewindow>>")) {
                    const parts = msg.split(">>")[1].split(",");
                    if (parts.length >= 2) {
                        root.windowTitle = parts[1].trim();
                    }
                }
            }
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󱂬"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: Theme.blue
        }

        Text {
            id: titleText
            text: root.windowTitle
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
            
            // ELIDE: This replaces overflow with ...
            elide: Text.ElideRight
            
            // Set a strict maximum width for the text itself
            Layout.maximumWidth: 150 
        }
    }
}
