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
    
    // Fixed container width to prevent shifting
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32
    
    visible: windowTitle !== ""
    readonly property string windowTitle: Hyprland.focusedWindow?.title || "Desktop"

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
