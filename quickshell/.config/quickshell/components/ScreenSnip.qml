import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screen-snip"
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    color: "transparent"

    property point startPos: Qt.point(0, 0)
    property point endPos: Qt.point(0, 0)
    property bool isSelecting: false

    function reset() {
        startPos = Qt.point(0, 0);
        endPos = Qt.point(0, 0);
        isSelecting = false;
    }

    onVisibleChanged: {
        if (visible) {
            reset();
        }
    }

    // Overlay Background
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.4
    }

    // Selection Area
    MouseArea {
        id: selectionArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor

        onPressed: (mouse) => {
            root.startPos = Qt.point(mouse.x, mouse.y);
            root.endPos = Qt.point(mouse.x, mouse.y);
            root.isSelecting = true;
        }

        onPositionChanged: (mouse) => {
            if (root.isSelecting) {
                root.endPos = Qt.point(mouse.x, mouse.y);
            }
        }

        onReleased: {
            root.isSelecting = false;
        }
    }

    // Visual Selection Rectangle
    Rectangle {
        id: selectionRect
        visible: root.startPos.x !== root.endPos.x || root.startPos.y !== root.endPos.y
        x: Math.min(root.startPos.x, root.endPos.x)
        y: Math.min(root.startPos.y, root.endPos.y)
        width: Math.abs(root.startPos.x - root.endPos.x)
        height: Math.abs(root.startPos.y - root.endPos.y)
        
        color: "transparent"
        border.color: Theme.mauve
        border.width: 2
        
        // Hole in the overlay
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2000 // Large enough to cover screen
            color: "#000000"
            opacity: 0.2
            z: -1
            
            // This is a trick to create a cutout, but in standard QML we'll just use another overlay
            visible: false
        }
    }

    // Floating Action Buttons
    RowLayout {
        visible: selectionRect.visible && !root.isSelecting
        x: selectionRect.x + (selectionRect.width / 2) - (width / 2)
        y: selectionRect.y + selectionRect.height + 15 > root.height - height - 20 
           ? selectionRect.y - height - 15 
           : selectionRect.y + selectionRect.height + 15
        
        spacing: 10

        Rectangle {
            id: actionsContainer
            Layout.preferredHeight: 50
            Layout.preferredWidth: actionsLayout.implicitWidth + 30
            color: Theme.base
            radius: 12
            border.color: Theme.surface0
            border.width: 1

            RowLayout {
                id: actionsLayout
                anchors.centerIn: parent
                spacing: 15

                // Capture & Edit (Swappy)
                ToolButton {
                    id: editBtn
                    onClicked: {
                        const region = `${selectionRect.x},${selectionRect.y} ${selectionRect.width}x${selectionRect.height}`;
                        Quickshell.execDetached(["bash", "-c", `grim -g "${region}" - | swappy -f -`]);
                        root.visible = false;
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Text { text: "󰄄"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: Theme.mauve }
                        Text { text: "Edit"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 14; font.bold: true }
                    }
                    background: Rectangle { radius: 8; color: editBtn.hovered ? Theme.surface1 : "transparent" }
                }

                // Copy to Clipboard
                ToolButton {
                    id: copyBtn
                    onClicked: {
                        const region = `${selectionRect.x},${selectionRect.y} ${selectionRect.width}x${selectionRect.height}`;
                        Quickshell.execDetached(["bash", "-c", `grim -g "${region}" - | wl-copy`]);
                        root.visible = false;
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Text { text: "󰅍"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: Theme.blue }
                        Text { text: "Copy"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 14; font.bold: true }
                    }
                    background: Rectangle { radius: 8; color: copyBtn.hovered ? Theme.surface1 : "transparent" }
                }

                // Close
                ToolButton {
                    id: closeBtn
                    onClicked: root.visible = false
                    contentItem: Text {
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: closeBtn.hovered ? Theme.red : Theme.surface2
                    }
                    background: null
                }
            }
        }
    }

    // Help Text
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40
        visible: !selectionRect.visible
        text: "Drag to select a region • ESC to cancel"
        color: "white"
        font.family: Theme.fontName
        font.pixelSize: 16
        opacity: 0.8
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false;
        }
    }
}
