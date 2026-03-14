import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screen-snip"
    
    anchors {
        top: true; bottom: true; left: true; right: true
    }

    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    color: "transparent"

    property point startPos: Qt.point(0, 0)
    property point endPos: Qt.point(0, 0)
    property bool isSelecting: false
    property int mode: 0 // 0: Screenshot, 1: Record (Not implemented yet but following end4 style)
    property int action: 0 // 0: Edit, 1: Copy, 2: Save

    function reset() {
        startPos = Qt.point(0, 0)
        endPos = Qt.point(0, 0)
        isSelecting = false
    }

    onVisibleChanged: {
        if (visible) {
            reset()
            screencopy.capture()
        }
    }

    // Static background capture
    ScreencopyView {
        id: screencopy
        anchors.fill: parent
        live: false
        captureSource: root.screen
    }

    // Darkening Overlay with Hole
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5
        visible: !isSelecting && selectionRect.width === 0
    }

    // Selection logic
    MouseArea {
        id: selectionArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        hoverEnabled: true

        onPressed: (mouse) => {
            root.startPos = Qt.point(mouse.x, mouse.y)
            root.endPos = Qt.point(mouse.x, mouse.y)
            root.isSelecting = true
        }

        onPositionChanged: (mouse) => {
            if (root.isSelecting) {
                root.endPos = Qt.point(mouse.x, mouse.y)
            }
        }

        onReleased: {
            root.isSelecting = false
        }
    }

    // Selection Rectangle and Cutout
    Item {
        anchors.fill: parent
        visible: root.startPos.x !== root.endPos.x

        readonly property real selX: Math.min(root.startPos.x, root.endPos.x)
        readonly property real selY: Math.min(root.startPos.y, root.endPos.y)
        readonly property real selW: Math.abs(root.startPos.x - root.endPos.x)
        readonly property real selH: Math.abs(root.startPos.y - root.endPos.y)

        // The darkening pieces around the selection
        Rectangle { x: 0; y: 0; width: parent.width; height: parent.selY; color: "#000000"; opacity: 0.5 }
        Rectangle { x: 0; y: parent.selY + parent.selH; width: parent.width; height: parent.height - (parent.selY + parent.selH); color: "#000000"; opacity: 0.5 }
        Rectangle { x: 0; y: parent.selY; width: parent.selX; height: parent.selH; color: "#000000"; opacity: 0.5 }
        Rectangle { x: parent.selX + parent.selW; y: parent.selY; width: parent.width - (parent.selX + parent.selW); height: parent.selH; color: "#000000"; opacity: 0.5 }

        // Border
        Rectangle {
            id: selectionRect
            x: parent.selX; y: parent.selY; width: parent.selW; height: parent.selH
            color: "transparent"
            border.color: Theme.mauve
            border.width: 2
            
            // Magnifier corner indicators (end4 style)
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.left: parent.left; anchors.top: parent.top; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: -2 }

            // Pixel Dimensions (end4 style)
            Rectangle {
                anchors.bottom: parent.top
                anchors.left: parent.left
                anchors.bottomMargin: 8
                width: dimensionsText.implicitWidth + 16
                height: dimensionsText.implicitHeight + 8
                color: Theme.base
                radius: 8
                border.color: Theme.surface0
                border.width: 1
                visible: parent.width > 50

                Text {
                    id: dimensionsText
                    anchors.centerIn: parent
                    text: Math.round(parent.parent.width) + " x " + Math.round(parent.parent.height)
                    color: Theme.mauve
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }

    // Modern Bottom Toolbar (Exact end4 style placement)
    Rectangle {
        id: toolbar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        width: 350
        height: 60
        color: Theme.base
        radius: 30
        border.color: Theme.surface0
        border.width: 1
        
        opacity: root.visible ? 1.0 : 0.0
        scale: root.visible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20; anchors.rightMargin: 20
            spacing: 15

            // Mode Selector
            RowLayout {
                spacing: 5
                ToolButton {
                    flat: true
                    contentItem: Text { text: "󰄄"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: root.mode === 0 ? Theme.mauve : Theme.surface2 }
                    onClicked: root.mode = 0
                }
                ToolButton {
                    flat: true
                    contentItem: Text { text: "󰕧"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: root.mode === 1 ? Theme.mauve : Theme.surface2 }
                    onClicked: root.mode = 1
                }
            }

            Rectangle { width: 1; height: 30; color: Theme.surface0; Layout.alignment: Qt.AlignVCenter }

            // Action Selector
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                
                ToolButton {
                    id: editToggle
                    flat: true
                    onClicked: root.action = 0
                    contentItem: Text { text: "󰏫"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: root.action === 0 ? Theme.mauve : Theme.text }
                    ToolTip.visible: hovered; ToolTip.text: "Capture & Edit"
                }
                ToolButton {
                    id: copyToggle
                    flat: true
                    onClicked: root.action = 1
                    contentItem: Text { text: "󰅍"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: root.action === 1 ? Theme.mauve : Theme.text }
                    ToolTip.visible: hovered; ToolTip.text: "Copy to Clipboard"
                }
                ToolButton {
                    id: saveToggle
                    flat: true
                    onClicked: root.action = 2
                    contentItem: Text { text: "󰆓"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: root.action === 2 ? Theme.mauve : Theme.text }
                    ToolTip.visible: hovered; ToolTip.text: "Save to File"
                }
            }

            Rectangle { width: 1; height: 30; color: Theme.surface0; Layout.alignment: Qt.AlignVCenter }

            // Close
            ToolButton {
                flat: true
                onClicked: root.visible = false
                contentItem: Text { text: "󰅖"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: Theme.red }
            }
        }
    }

    // Execution trigger on release if selection is valid
    onIsSelectingChanged: {
        if (!isSelecting && selectionRect.width > 5 && selectionRect.height > 5) {
            const region = `${selectionRect.x},${selectionRect.y} ${selectionRect.width}x${selectionRect.height}`
            
            if (root.mode === 0) { // Screenshot
                let cmd = ""
                if (root.action === 0) cmd = `grim -g "${region}" - | swappy -f -`
                else if (root.action === 1) cmd = `grim -g "${region}" - | wl-copy`
                else if (root.action === 2) cmd = `grim -g "${region}" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png`
                
                Quickshell.execDetached(["bash", "-c", cmd])
            }
            
            root.visible = false
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
    }
}
