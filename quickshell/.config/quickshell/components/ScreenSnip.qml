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
    property bool hasSelection: false
    property int mode: 0 // 0: Screenshot, 1: Record
    property int action: 0 // 0: Edit, 1: Copy, 2: Save

    function reset() {
        startPos = Qt.point(0, 0)
        endPos = Qt.point(0, 0)
        isSelecting = false
        hasSelection = false
    }

    function capture() {
        if (selectionRect.width < 5 || selectionRect.height < 5) return;
        
        const rx = Math.round(selectionRect.x);
        const ry = Math.round(selectionRect.y);
        const rw = Math.round(selectionRect.width);
        const rh = Math.round(selectionRect.height);
        const region = `${rx},${ry} ${rw}x${rh}`
        
        root.visible = false;
        
        if (root.mode === 0) { // Screenshot
            let cmd = ""
            if (root.action === 0) cmd = `sleep 0.2 && grim -g "${region}" - | tee >(wl-copy) | swappy -f -`
            else if (root.action === 1) cmd = `sleep 0.2 && grim -g "${region}" - | wl-copy`
            else if (root.action === 2) cmd = `mkdir -p ~/Pictures/Screenshots && sleep 0.2 && grim -g "${region}" - | tee >(wl-copy) > ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png`
            
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
    }

    onVisibleChanged: {
        if (visible) {
            reset()
        }
    }

    Loader {
        anchors.fill: parent
        active: root.visible
        sourceComponent: ScreencopyView {
            anchors.fill: parent
            live: false
            captureSource: root.screen
        }
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0.5
        visible: !hasSelection && !isSelecting
    }

    MouseArea {
        id: selectionArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        hoverEnabled: true
        
        focus: root.visible
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) root.visible = false
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.capture()
        }

        onPressed: (mouse) => {
            root.startPos = Qt.point(mouse.x, mouse.y)
            root.endPos = Qt.point(mouse.x, mouse.y)
            root.isSelecting = true
            root.hasSelection = false
        }

        onPositionChanged: (mouse) => {
            if (root.isSelecting) {
                root.endPos = Qt.point(mouse.x, mouse.y)
            }
        }

        onReleased: {
            root.isSelecting = false
            if (Math.abs(root.startPos.x - root.endPos.x) > 5 && Math.abs(root.startPos.y - root.endPos.y) > 5) {
                root.hasSelection = true
            } else {
                root.reset()
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.isSelecting || root.hasSelection

        readonly property real selX: Math.min(root.startPos.x, root.endPos.x)
        readonly property real selY: Math.min(root.startPos.y, root.endPos.y)
        readonly property real selW: Math.abs(root.startPos.x - root.endPos.x)
        readonly property real selH: Math.abs(root.startPos.y - root.endPos.y)

        Rectangle { x: 0; y: 0; width: parent.width; height: parent.selY; color: "#000000"; opacity: 0.5 }
        Rectangle { x: 0; y: parent.selY + parent.selH; width: parent.width; height: parent.height - (parent.selY + parent.selH); color: "#000000"; opacity: 0.5 }
        Rectangle { x: 0; y: parent.selY; width: parent.selX; height: parent.selH; color: "#000000"; opacity: 0.5 }
        Rectangle { x: parent.selX + parent.selW; y: parent.selY; width: parent.width - (parent.selX + parent.selW); height: parent.selH; color: "#000000"; opacity: 0.5 }

        Rectangle {
            id: selectionRect
            x: parent.selX; y: parent.selY; width: parent.selW; height: parent.selH
            color: "transparent"
            border.color: Theme.mauve
            border.width: 2
            
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.left: parent.left; anchors.top: parent.top; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: -2 }
            Rectangle { width: 10; height: 10; color: Theme.mauve; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: -2 }

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
                visible: parent.width > 20

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

    Rectangle {
        id: toolbar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        width: contentLayout.implicitWidth + 64 // Extra padding for the toolbar
        height: 72
        color: Theme.base
        radius: 36
        border.color: Theme.surface0
        border.width: 1
        z: 100
        
        opacity: root.visible ? 1.0 : 0.0
        scale: root.visible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 32 // More space between pills

            // --- Mode Pill ---
            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: modeRow.implicitWidth + 32 // Extra padding inside pill
                color: Theme.surface0
                radius: 24
                border.color: Theme.surface1
                border.width: 1

                RowLayout {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 16 // More space between mode icons
                    
                    ToolButton {
                        id: scMode
                        flat: true; width: 40; height: 40
                        onClicked: root.mode = 0
                        scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        background: Rectangle {
                            radius: 20
                            color: root.mode === 0 ? Theme.mauve : (scMode.hovered ? Theme.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                anchors.centerIn: parent
                                text: "󰄄"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: root.mode === 0 ? Theme.base : Theme.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                    ToolButton {
                        id: recMode
                        flat: true; width: 40; height: 40
                        onClicked: root.mode = 1
                        scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        background: Rectangle {
                            radius: 20
                            color: root.mode === 1 ? Theme.mauve : (recMode.hovered ? Theme.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                anchors.centerIn: parent
                                text: "󰕧"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: root.mode === 1 ? Theme.base : Theme.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                }
            }

            // --- Action Pill ---
            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: actionRow.implicitWidth + 32 // Extra padding inside pill
                color: Theme.surface0
                radius: 24
                border.color: Theme.surface1
                border.width: 1

                RowLayout {
                    id: actionRow
                    anchors.centerIn: parent
                    spacing: 16 // More space between action icons
                    
                    ToolButton {
                        id: editBtn
                        flat: true; width: 40; height: 40
                        onClicked: { root.action = 0; if (root.hasSelection) root.capture() }
                        scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        background: Rectangle {
                            radius: 20
                            color: (root.action === 0 && root.hasSelection) ? Theme.mauve : (editBtn.hovered ? Theme.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                anchors.centerIn: parent
                                text: "󰏫"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: (root.action === 0 && root.hasSelection) ? Theme.base : Theme.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                    ToolButton {
                        id: copyBtn
                        flat: true; width: 40; height: 40
                        onClicked: { root.action = 1; if (root.hasSelection) root.capture() }
                        scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        background: Rectangle {
                            radius: 20
                            color: (root.action === 1 && root.hasSelection) ? Theme.mauve : (copyBtn.hovered ? Theme.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                anchors.centerIn: parent
                                text: "󰅍"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: (root.action === 1 && root.hasSelection) ? Theme.base : Theme.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                    ToolButton {
                        id: saveBtn
                        flat: true; width: 40; height: 40
                        onClicked: { root.action = 2; if (root.hasSelection) root.capture() }
                        scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        background: Rectangle {
                            radius: 20
                            color: (root.action === 2 && root.hasSelection) ? Theme.mauve : (saveBtn.hovered ? Theme.surface1 : "transparent")
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            Text {
                                anchors.centerIn: parent
                                text: "󰆓"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: (root.action === 2 && root.hasSelection) ? Theme.base : Theme.text
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                    }
                }
            }

            // --- Close Button ---
            ToolButton {
                id: closeBtn
                flat: true; width: 48; height: 48
                onClicked: root.visible = false
                scale: hovered ? 1.1 : (pressed ? 0.9 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                background: Rectangle {
                    radius: 24
                    color: closeBtn.hovered ? Theme.red : Theme.surface0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                contentItem: Item {
                    anchors.fill: parent
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: closeBtn.hovered ? Theme.base : Theme.red
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }
    }
}
