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
    
    // Service Instance
    StudyService { id: service }

    ListModel { id: topicsModel }

    function refresh() {
        service.getSubjectData(subjectName, (data) => {
            topicsModel.clear();
            for (let item of data) {
                topicsModel.append(item);
            }
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
                padding: 8
                background: null
                contentItem: Text { text: "󰑐"; font.family: "JetBrainsMono Nerd Font"; color: Theme.subtext0; font.pixelSize: 20 }
                onClicked: trackerRoot.refresh()
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
                    model: topicsModel
                    delegate: Row {
                        spacing: -1
                        Rectangle {
                            width: trackerRoot.colIndexWidth; height: trackerRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            Text { anchors.centerIn: parent; text: (index + 1).toString(); color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11 }
                        }
                        Rectangle {
                            width: trackerRoot.colLessonWidth; height: trackerRoot.cellHeight
                            color: "transparent"; border.color: Theme.surface1; border.width: 1
                            Text { 
                                anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                text: model.name; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13 
                            }
                        }
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: trackerRoot.colCheckWidth; height: trackerRoot.cellHeight
                                color: "transparent"; border.color: Theme.surface1; border.width: 1
                                StudyCheckBox { 
                                    anchors.centerIn: parent
                                    topicId: model.id
                                    columnIdx: index
                                    service: service
                                    checked: model.checked.get(index)
                                    enabled: trackerRoot.authenticated
                                }
                            }
                        }
                    }
                }

                // Empty State / Init
                Rectangle {
                    visible: topicsModel.count === 0
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
