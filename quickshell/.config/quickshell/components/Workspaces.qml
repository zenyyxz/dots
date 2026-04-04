import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    clip: true // Confine animation to this widget
    
    // Explicitly bind width to content plus padding
    width: row.width + 24
    height: 32

    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 1

    // --- Pac-Man Animation State ---
    property real pacmanX: -50
    property real ghostX: -100
    property bool ghostScared: false
    property bool pacmanLeft: false

    // Centralized Eating Logic: Check if Pacman overlaps any colored dot
    readonly property bool isEating: {
        if (pacmanX < 0 || pacmanX > root.width) return false;
        for (let i = 0; i < repeater.count; i++) {
            let dotItem = repeater.itemAt(i);
            if (dotItem) {
                let dotCenter = dotItem.x + row.x + dotItem.width/2;
                if (Math.abs(pacmanX + 10 - dotCenter) < 16) {
                    return dotItem.isActive || dotItem.isOccupied;
                }
            }
        }
        return false;
    }

    SequentialAnimation {
        id: chaseAnimation
        
        // 1. Ghost chases Pacman (Left -> Right)
        ParallelAnimation {
            NumberAnimation { target: root; property: "pacmanX"; from: -20; to: root.width + 20; duration: 4000; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "ghostX"; from: -60; to: root.width - 10; duration: 4000; easing.type: Easing.InOutSine }
        }

        ScriptAction { script: { root.ghostScared = true; root.pacmanLeft = true; } }
        PauseAnimation { duration: 500 }

        // 2. Pacman chases Ghost (Right -> Left)
        ParallelAnimation {
            NumberAnimation { target: root; property: "pacmanX"; from: root.width + 20; to: -60; duration: 3000; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "ghostX"; from: root.width - 10; to: -100; duration: 3000; easing.type: Easing.InOutSine }
        }

        ScriptAction { script: { root.ghostScared = false; root.pacmanLeft = false; root.pacmanX = -100; root.ghostX = -100; } }
    }

    Timer {
        interval: 180000 // Every 3 minutes
        running: true; repeat: true
        onTriggered: chaseAnimation.start()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => { if (mouse.button === Qt.RightButton) chaseAnimation.restart(); }
    }

    // --- INNER CLIPPED CONTAINER ---
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: root.radius - 1
        color: "transparent"
        clip: true
        layer.enabled: true // Force proper clipping context

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                id: repeater
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
                    opacity: isEaten ? 0.2 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    
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

        // --- Pac-Man & Ghost Entities ---
        Text {
            id: ghost
            x: root.ghostX; y: parent.height/2 - height/2
            text: "󰊠"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
            color: root.ghostScared ? Theme.blue : Theme.red
            z: 10
            Behavior on color { ColorAnimation { duration: 200 } }
            // Horizontal flip only - Fix: Use xScale instead of x
            transform: Scale { origin.x: 9; origin.y: 9; xScale: root.pacmanLeft ? -1 : 1 }
            // Manual edge fade-out (Software Clip)
            opacity: (x < 0 || x > parent.width - 20) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        Image {
            id: pacman
            x: root.pacmanX; y: parent.height/2 - height/2
            width: 20; height: 20
            source: root.isEating ? Quickshell.shellPath("assets/pacman-eating.svg") : Quickshell.shellPath("assets/pacman.svg")
            visible: false
            z: 11
        }

        ColorOverlay {
            anchors.fill: pacman
            source: pacman
            color: Theme.yellow
            z: 11
            // Horizontal flip only - Fix: Use xScale instead of x
            transform: Scale { origin.x: 10; origin.y: 10; xScale: root.pacmanLeft ? -1 : 1 }
            // Manual edge fade-out (Software Clip) - Using root.width for safety
            opacity: (pacman.x < 0 || pacman.x > root.width - 20) ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
    }
}
