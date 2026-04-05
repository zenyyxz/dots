import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: todoRoot
    
    property bool authenticated: false
    property bool isShowing: true
    
    // Service Instance
    StudyService { id: trackerService }

    property var todosData: []
    property bool loading: false

    function refresh() {
        loading = true;
        trackerService.getTodos((data) => {
            todosData = data;
            loading = false;
        });
    }

    Component.onCompleted: refresh()

    // Geometry Constants
    readonly property int colIndexWidth: 40
    readonly property int colTaskWidth: 260
    readonly property int colCheckWidth: 60
    readonly property int cellHeight: 38 // Increased for better touch/click targets

    implicitWidth: colIndexWidth + colTaskWidth + colCheckWidth + 2 
    color: Theme.crust
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: 1

    // Window Ghost Mode
    opacity: todoRoot.isShowing ? 1.0 : 0.2
    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

    // Sapphire Tint Overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.sapphire
        opacity: 0.08
        radius: parent.radius
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Daily Tasks"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
                
                // Ghost Fade
                opacity: todoRoot.isShowing ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
            }

            // Sync/Refresh Button
            Button {
                id: refreshButton
                padding: 8
                
                // Ghost Fade
                opacity: todoRoot.isShowing ? 1.0 : 0.0
                enabled: todoRoot.isShowing
                Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

                background: Rectangle {
                    radius: 8
                    color: refreshButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: refreshButton.pressed ? Theme.sapphire : "transparent"
                    border.width: 1
                }
                
                contentItem: Text { 
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    color: refreshButton.hovered ? Theme.text : Theme.subtext0
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    rotation: 0
                    RotationAnimation on rotation {
                        id: rotateAnim
                        from: 0; to: 360; duration: 500; running: false; easing.type: Easing.OutCubic
                    }
                }
                
                onClicked: {
                    rotateAnim.restart();
                    todoRoot.refresh();
                }
            }

            // Local Eye Toggle (Always Visible in Ghost Mode)
            Button {
                id: eyeButton
                padding: 8
                background: Rectangle {
                    radius: 8
                    color: eyeButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                }
                contentItem: Image {
                    source: todoRoot.isShowing ? "../assets/eye-svgrepo-com.svg" : "../assets/eye-slash-svgrepo-com.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: todoRoot.isShowing ? Theme.sapphire : Theme.subtext0 }
                }
                onClicked: todoRoot.isShowing = !todoRoot.isShowing
            }

            // Auth Button (Consistency with Subject Trackers)
            Button {
                id: authButton
                padding: 8
                
                // Ghost Fade
                opacity: todoRoot.isShowing ? 1.0 : 0.0
                enabled: todoRoot.isShowing
                Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

                background: Rectangle {
                    radius: 8
                    color: authButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: authButton.pressed ? Theme.sapphire : "transparent"
                    border.width: 1
                }
                
                contentItem: Image {
                    source: todoRoot.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: todoRoot.authenticated ? Theme.green : Theme.red
                    }
                }
                
                onClicked: todoRoot.authenticated = !todoRoot.authenticated
            }
        }

        // --- Mastery / Progress Bar ---
        ColumnLayout {
            id: masteryLayout
            Layout.fillWidth: true
            spacing: 8
            visible: todosData.length > 0
            
            // Ghost Fade
            opacity: todoRoot.isShowing ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
            
            property int completedCount: {
                let count = 0;
                if (!todosData) return 0;
                for (let i = 0; i < todosData.length; i++) {
                    if (todosData[i] && todosData[i].completed) count++;
                }
                return count;
            }
            
            property real progress: todosData.length > 0 ? (completedCount / todosData.length) : 0
            
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Current Mastery"
                    color: Theme.subtext0
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Math.round(masteryLayout.progress * 100) + "%"
                    color: Theme.sapphire
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    font.bold: true
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.surface0
                
                Rectangle {
                    width: parent.width * masteryLayout.progress
                    height: parent.height
                    radius: 3
                    color: Theme.sapphire
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            // Ghost Fade
            opacity: todoRoot.isShowing ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
            
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
                width: todoRoot.implicitWidth
                spacing: -1

                // Header
                Row {
                    spacing: -1
                    Rectangle {
                        width: todoRoot.colIndexWidth; height: 30
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "#"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11 }
                    }
                    Rectangle {
                        width: todoRoot.colTaskWidth; height: 30
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "Task Description"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11; font.bold: true }
                    }
                    Rectangle {
                        width: todoRoot.colCheckWidth; height: 30
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "Done"; color: Theme.sapphire; font.family: Theme.fontName; font.pixelSize: 11; font.bold: true }
                    }
                }

                // Data Rows
                Repeater {
                    model: todoRoot.todosData
                    delegate: Row {
                        id: rowDelegate
                        spacing: -1
                        
                        readonly property var itemData: modelData
                        readonly property int todoId: itemData.id
                        readonly property string taskName: itemData.task
                        readonly property bool completed: itemData.completed

                        Rectangle {
                            width: todoRoot.colIndexWidth; height: todoRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            Text { 
                                anchors.centerIn: parent
                                text: (indexMouseArea.containsMouse && todoRoot.authenticated) ? "󰆴" : (index + 1).toString()
                                color: (indexMouseArea.containsMouse && todoRoot.authenticated) ? Theme.red : Theme.subtext0 
                                font.family: (indexMouseArea.containsMouse && todoRoot.authenticated) ? "JetBrainsMono Nerd Font" : Theme.fontName
                                font.pixelSize: (indexMouseArea.containsMouse && todoRoot.authenticated) ? 14 : 11 
                            }
                            MouseArea {
                                id: indexMouseArea
                                anchors.fill: parent; hoverEnabled: true; cursorShape: todoRoot.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (todoRoot.authenticated) {
                                        trackerService.deleteTodo(rowDelegate.todoId, () => todoRoot.refresh());
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: todoRoot.colTaskWidth; height: todoRoot.cellHeight
                            color: taskInput.activeFocus ? Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.1) : "transparent"
                            border.color: taskInput.activeFocus ? Theme.sapphire : Theme.surface1; border.width: taskInput.activeFocus ? 2 : 1
                            TextInput { 
                                id: taskInput
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: Text.AlignVCenter
                                text: rowDelegate.taskName; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13 
                                selectByMouse: true; clip: true; enabled: todoRoot.authenticated
                                onEditingFinished: if (text !== rowDelegate.taskName) trackerService.renameTodo(rowDelegate.todoId, text)
                            }
                        }
                        Rectangle {
                            width: todoRoot.colCheckWidth; height: todoRoot.cellHeight
                            color: check.hovered ? Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.1) : "transparent"
                            border.color: check.hovered ? Theme.sapphire : Theme.surface1; border.width: check.hovered ? 2 : 1
                            TodoCheckBox { 
                                id: check; anchors.fill: parent
                                todoId: rowDelegate.todoId; service: trackerService
                                checkedColor: Theme.sapphire
                                initialChecked: rowDelegate.completed; onToggled: todoRoot.refresh()
                            }
                        }
                    }
                }

                // Add New Todo Row
                Row {
                    spacing: -1
                    Rectangle {
                        width: todoRoot.colIndexWidth + todoRoot.colTaskWidth + todoRoot.colCheckWidth - 3
                        height: todoRoot.cellHeight
                        color: addMouseArea.containsMouse ? Theme.surface0 : "transparent"
                        border.color: Theme.surface1; border.width: 1
                        opacity: todoRoot.authenticated ? 1.0 : 0.5
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                            Text { 
                                text: todoRoot.authenticated ? "＋" : "󰌾"
                                color: Theme.subtext0
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14 
                            }
                            Text { 
                                text: todoRoot.authenticated ? "Add New Task" : "Unlock to Add Task"
                                color: Theme.subtext0
                                font.family: Theme.fontName
                                font.pixelSize: 13 
                            }
                        }
                        
                        MouseArea {
                            id: addMouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: todoRoot.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (todoRoot.authenticated) {
                                    trackerService.addTodo("New Task", () => todoRoot.refresh());
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
