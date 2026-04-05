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
    property var topics: ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5", "Topic 6", "Topic 7", "Topic 8", "Topic 9", "Topic 10"]

    // Max height for the widget before scrolling kicks in
    property int maxHeight: 0 // 0 means fill parent

    // Table Geometry Constants
    readonly property int colIndexWidth: 40
    readonly property int colLessonWidth: 240
    readonly property int colCheckWidth: 60
    readonly property int cellHeight: 34
    readonly property color borderColor: Qt.rgba(Theme.surface2.r / 255, Theme.surface1.g / 255, Theme.surface1.b / 255, 0.3)

    implicitWidth: colIndexWidth + colLessonWidth + (colCheckWidth * 4) + 2 
    implicitHeight: maxHeight > 0 ? Math.min(mainLayout.implicitHeight + 24, maxHeight) : 1000 
    
    anchors.fill: (maxHeight === 0 && parent) ? parent : undefined
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15

        // --- Notion-style Header Title ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextInput {
                id: subjectInput
                text: trackerRoot.subjectName
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 24
                font.bold: true
                Layout.fillWidth: true
                enabled: trackerRoot.authenticated
                selectByMouse: true
                onTextEdited: trackerRoot.subjectName = text
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: "white"; visible: parent.activeFocus
                }
            }

            Button {
                id: authButton
                padding: 8
                background: null
                contentItem: Image {
                    source: trackerRoot.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: trackerRoot.authenticated ? Theme.green : Theme.red
                    }
                }
                onClicked: trackerRoot.authenticated = !trackerRoot.authenticated
                ToolTip.visible: hovered
                ToolTip.text: trackerRoot.authenticated ? "Click to Lock Editing" : "Click to Unlock Editing"
            }
        }

        // --- The Table ---
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            
            Column {
                id: tableGrid
                width: scrollView.width
                spacing: -1 // Overlap borders for single-line look

                // --- Header Row ---
                Row {
                    spacing: -1
                    
                    // #
                    Rectangle {
                        width: trackerRoot.colIndexWidth; height: trackerRoot.cellHeight
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        Text { anchors.centerIn: parent; text: "#"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 12 }
                    }
                    
                    // Name
                    Rectangle {
                        width: trackerRoot.colLessonWidth; height: trackerRoot.cellHeight
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                            Text { text: "Aa"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 12 }
                            Text { text: "Name"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 12; font.bold: true }
                        }
                    }
                    
                    // Columns
                    Repeater {
                        model: trackerRoot.columnTitles.length
                        delegate: Rectangle {
                            width: trackerRoot.colCheckWidth; height: trackerRoot.cellHeight
                            color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                            TextInput {
                                id: titleInput
                                anchors.centerIn: parent
                                text: trackerRoot.columnTitles[index]
                                color: Theme.subtext0
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                enabled: trackerRoot.authenticated
                                selectByMouse: true
                                onTextEdited: {
                                    let t = trackerRoot.columnTitles;
                                    t[index] = text;
                                    trackerRoot.columnTitles = t;
                                }
                            }
                        }
                    }
                }

                // --- Data Rows ---
                Repeater {
                    model: trackerRoot.topics.length
                    delegate: Row {
                        spacing: -1
                        
                        // Index
                        Rectangle {
                            width: trackerRoot.colIndexWidth; height: trackerRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            Text { anchors.centerIn: parent; text: (index + 1).toString(); color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11 }
                        }

                        // Lesson Name
                        Rectangle {
                            width: trackerRoot.colLessonWidth; height: trackerRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                                Text { text: "󰈙"; font.family: "JetBrainsMono Nerd Font"; color: Theme.subtext0; font.pixelSize: 14 }
                                
                                TextInput {
                                    id: topicInput
                                    Layout.fillWidth: true
                                    text: trackerRoot.topics[index]
                                    color: Theme.text
                                    font.family: Theme.fontName
                                    font.pixelSize: 13
                                    enabled: trackerRoot.authenticated
                                    selectByMouse: true
                                    clip: true
                                    onTextEdited: {
                                        let t = trackerRoot.topics;
                                        t[index] = text;
                                        trackerRoot.topics = t;
                                    }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent; color: "transparent"; border.color: "white"; border.width: 1; visible: topicInput.activeFocus
                            }
                        }

                        // Checkboxes
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: trackerRoot.colCheckWidth; height: trackerRoot.cellHeight
                                color: "transparent"; border.color: Theme.surface1; border.width: 1
                                StudyCheckBox { 
                                    anchors.centerIn: parent
                                    enabled: trackerRoot.authenticated 
                                }
                            }
                        }
                    }
                }

                // --- Add New Row ---
                Row {
                    visible: trackerRoot.authenticated
                    spacing: -1
                    Rectangle {
                        width: trackerRoot.colIndexWidth + trackerRoot.colLessonWidth + (trackerRoot.colCheckWidth * 4) - 3
                        height: trackerRoot.cellHeight
                        color: "transparent"; border.color: Theme.surface1; border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; spacing: 8
                            Text { text: "＋"; color: Theme.subtext0; font.pixelSize: 14 }
                            Text { text: "New Lesson"; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 13 }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let t = trackerRoot.topics;
                                t.push("New Topic " + (t.length + 1));
                                trackerRoot.topics = t;
                            }
                        }
                    }
                }
            }
        }
    }
}
