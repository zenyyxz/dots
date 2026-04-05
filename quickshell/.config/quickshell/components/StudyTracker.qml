import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: trackerRoot
    
    property bool authenticated: false
    property string subjectName: "Subject"
    property var columnTitles: ["Theory", "Revise", "PP", "MP"]
    property var topics: ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5", "Topic 6", "Topic 7", "Topic 8", "Topic 9", "Topic 10"]
    
    implicitWidth: 420
    implicitHeight: mainLayout.implicitHeight + 36 // 18 margins * 2
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: Theme.borderWidth

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                height: 32
                color: "transparent"
                radius: 4
                border.color: subjectInput.activeFocus ? "white" : "transparent"
                border.width: 1

                TextInput {
                    id: subjectInput
                    anchors.fill: parent
                    anchors.margins: 4
                    text: trackerRoot.subjectName
                    color: Theme.mauve
                    font.family: Theme.fontName
                    font.pixelSize: 22 
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    enabled: trackerRoot.authenticated
                    selectByMouse: true
                    onTextEdited: trackerRoot.subjectName = text
                }
            }

            Button {
                id: authButton
                padding: 6
                background: Rectangle {
                    color: "transparent"
                    radius: 4
                    border.color: Theme.surface1
                    border.width: 1
                    visible: authButton.hovered
                }
                contentItem: Image {
                    source: trackerRoot.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    
                    // Use a ShaderEffect to color the SVG to match the theme
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

        // Table Header
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            
            Text { text: "#"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.preferredWidth: 25 }
            Text { text: "Lesson"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.preferredWidth: 180 }
            
            Repeater {
                model: trackerRoot.columnTitles.length
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    color: "transparent"
                    radius: 4
                    border.color: titleInput.activeFocus ? "white" : "transparent"
                    border.width: 1

                    TextInput {
                        id: titleInput
                        anchors.fill: parent
                        anchors.margins: 2
                        text: trackerRoot.columnTitles[index]
                        color: Theme.lavender
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        enabled: trackerRoot.authenticated
                        selectByMouse: true
                        onTextEdited: {
                            let titles = trackerRoot.columnTitles;
                            titles[index] = text;
                            trackerRoot.columnTitles = titles;
                        }
                    }
                }
            }
        }

        // Horizontal Line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface1
        }

        // Rows
        Repeater {
            model: trackerRoot.topics.length
            delegate: RowLayout {
                spacing: 10
                Layout.fillWidth: true
                
                Text {
                    text: (index + 1).toString()
                    color: Theme.subtext0
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    Layout.preferredWidth: 25
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.preferredWidth: 180
                    height: 24
                    color: "transparent"
                    radius: 4
                    border.color: topicInput.activeFocus ? "white" : "transparent"
                    border.width: 1

                    TextInput {
                        id: topicInput
                        anchors.fill: parent
                        anchors.margins: 2
                        text: trackerRoot.topics[index]
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        enabled: trackerRoot.authenticated
                        selectByMouse: true
                        onTextEdited: {
                            let t = trackerRoot.topics;
                            t[index] = text;
                            trackerRoot.topics = t;
                        }
                    }
                }

                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true; enabled: trackerRoot.authenticated }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true; enabled: trackerRoot.authenticated }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true; enabled: trackerRoot.authenticated }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true; enabled: trackerRoot.authenticated }
            }
        }
    }
}
