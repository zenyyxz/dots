import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: trackerRoot
    
    property bool authenticated: false
    property string subjectName: "Subject"
    property var columnTitles: ["T", "R", "PP", "MP"]
    readonly property var columnColors: [Theme.mauve, Theme.lavender, Theme.sapphire, Theme.teal]
    
    // Service Instance
    StudyService { id: service }

    property var topicsData: []
    property bool loading: false

    function refresh() {
        loading = true;
        service.getSubjectData(subjectName, (data) => {
            topicsData = data;
            loading = false;
        });
    }

    Component.onCompleted: refresh()

    // Geometry Constants
    readonly property int colIndexWidth: 40
    readonly property int colLessonWidth: 240
    readonly property int colCheckWidth: 60
    readonly property int cellHeight: 34

    implicitWidth: colIndexWidth + colLessonWidth + (colCheckWidth * 4) + 2 
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: trackerRoot.subjectName
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
            }

            // Sync/Refresh Button
            Button {
                id: refreshButton
                padding: 8
                background: Rectangle {
                    radius: 6
                    color: refreshButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: refreshButton.pressed ? Theme.mauve : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
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
                        from: 0; to: 360
                        duration: 500
                        running: false
                        easing.type: Easing.OutCubic
                    }
                }
                
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                
                onClicked: {
                    rotateAnim.restart();
                    trackerRoot.refresh();
                }
            }

            Button {
                id: authButton
                padding: 8
                background: Rectangle {
                    radius: 6
                    color: authButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: authButton.pressed ? Theme.mauve : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                contentItem: Image {
                    source: trackerRoot.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: trackerRoot.authenticated ? Theme.green : Theme.red
                    }
                    opacity: authButton.hovered ? 1.0 : 0.8
                }
                
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                
                onClicked: trackerRoot.authenticated = !trackerRoot.authenticated
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            Column {
                id: tableGrid
                width: parent.width
                spacing: -1

                // Header
                Row {
                    spacing: -1
                    Rectangle {
                        width: trackerRoot.colIndexWidth; height: trackerRoot.cellHeight
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "#"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 12 }
                    }
                    Rectangle {
                        width: trackerRoot.colLessonWidth; height: trackerRoot.cellHeight
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "Topic Name"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 12; font.bold: true }
                    }
                    Repeater {
                        model: trackerRoot.columnTitles.length
                        delegate: Rectangle {
                            width: trackerRoot.colCheckWidth; height: trackerRoot.cellHeight
                            color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                            Text { anchors.centerIn: parent; text: trackerRoot.columnTitles[index]; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11; font.bold: true }
                        }
                    }
                }

                // Data Rows
                Repeater {
                    model: trackerRoot.topicsData
                    delegate: Row {
                        id: rowDelegate
                        spacing: -1
                        
                        readonly property var itemData: modelData
                        readonly property int topicId: itemData.id
                        readonly property string topicName: itemData.name
                        readonly property var checkedArray: itemData.checked

                        Rectangle {
                            width: trackerRoot.colIndexWidth; height: trackerRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            
                            Text { 
                                anchors.centerIn: parent
                                text: (indexMouseArea.containsMouse && trackerRoot.authenticated) ? "󰆴" : (index + 1).toString()
                                color: (indexMouseArea.containsMouse && trackerRoot.authenticated) ? Theme.red : Theme.subtext0 
                                font.family: (indexMouseArea.containsMouse && trackerRoot.authenticated) ? "JetBrainsMono Nerd Font" : Theme.fontName
                                font.pixelSize: (indexMouseArea.containsMouse && trackerRoot.authenticated) ? 14 : 11 
                            }

                            MouseArea {
                                id: indexMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: trackerRoot.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (trackerRoot.authenticated) {
                                        service.deleteTopic(rowDelegate.topicId, () => {
                                            trackerRoot.refresh();
                                        });
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: trackerRoot.colLessonWidth; height: trackerRoot.cellHeight
                            color: topicInput.activeFocus ? Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.1) : "transparent"
                            border.color: topicInput.activeFocus ? Theme.mauve : Theme.surface1
                            border.width: topicInput.activeFocus ? 2 : 1
                            z: topicInput.activeFocus ? 1 : 0
                            
                            TextInput { 
                                id: topicInput
                                anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 10
                                text: rowDelegate.topicName
                                color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13 
                                enabled: trackerRoot.authenticated
                                selectByMouse: true
                                clip: true
                                
                                onEditingFinished: {
                                    if (text !== rowDelegate.topicName) {
                                        service.renameTopic(rowDelegate.topicId, text);
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: trackerRoot.colCheckWidth; height: trackerRoot.cellHeight
                                color: check.activeFocus ? Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.1) : "transparent"
                                border.color: check.activeFocus ? Theme.mauve : Theme.surface1
                                border.width: check.activeFocus ? 2 : 1
                                z: check.activeFocus ? 1 : 0

                                StudyCheckBox { 
                                    id: check
                                    anchors.centerIn: parent
                                    topicId: rowDelegate.topicId
                                    columnIdx: index
                                    service: service
                                    checkedColor: trackerRoot.columnColors[index]
                                    checked: rowDelegate.checkedArray ? rowDelegate.checkedArray[index] : false
                                    enabled: trackerRoot.authenticated
                                }
                            }
                        }
                    }
                }

                // --- Add New Row ---
                Row {
                    spacing: -1
                    Rectangle {
                        width: trackerRoot.colIndexWidth + trackerRoot.colLessonWidth + (trackerRoot.colCheckWidth * 4) - 3
                        height: trackerRoot.cellHeight
                        color: addMouseArea.containsMouse ? Theme.surface0 : "transparent"
                        border.color: Theme.surface1; border.width: 1
                        opacity: trackerRoot.authenticated ? 1.0 : 0.5
                        
                        Behavior on color { ColorAnimation { duration: 200 } }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                            Text { 
                                text: trackerRoot.authenticated ? "＋" : "󰌾"
                                color: Theme.subtext0
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14 
                            }
                            Text { 
                                text: trackerRoot.authenticated ? "New Lesson" : "Unlock to Add Lesson"
                                color: Theme.subtext0
                                font.family: Theme.fontName
                                font.pixelSize: 13 
                            }
                        }
                        
                        MouseArea {
                            id: addMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: trackerRoot.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (trackerRoot.authenticated) {
                                    let newName = "Topic " + (trackerRoot.topicsData.length + 1);
                                    service.addTopic(trackerRoot.subjectName, newName, () => {
                                        trackerRoot.refresh();
                                    });
                                }
                            }
                        }
                    }
                }

                // Empty State / Init
                Rectangle {
                    visible: !trackerRoot.loading && trackerRoot.topicsData.length === 0
                    width: trackerRoot.colIndexWidth + trackerRoot.colLessonWidth + (trackerRoot.colCheckWidth * 4) - 3
                    height: 100
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "No topics found.\nClick to initialize Combined Maths topics."
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.subtext0
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Quick init for the 53 topics
                            for (let i = 1; i <= 53; i++) {
                                service.addTopic(trackerRoot.subjectName, "Topic " + i, () => {
                                    if (i === 53) trackerRoot.refresh();
                                });
                            }
                        }
                    }
                }
            }
        }
    }
}
