import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

            TextInput {
                text: trackerRoot.subjectName
                color: Theme.mauve
                font.family: Theme.fontName
                font.pixelSize: 22 
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                enabled: trackerRoot.authenticated
                selectByMouse: true
                onTextEdited: trackerRoot.subjectName = text
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
                contentItem: Text {
                    text: trackerRoot.authenticated ? "󰌾" : "󰌿"
                    color: trackerRoot.authenticated ? Theme.green : Theme.red
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
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
            
            Text { text: "Lesson"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.preferredWidth: 150 }
            
            Repeater {
                model: trackerRoot.columnTitles.length
                delegate: TextInput {
                    text: trackerRoot.columnTitles[index]
                    color: Theme.lavender
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    Layout.fillWidth: true
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
                
                TextInput {
                    text: trackerRoot.topics[index]
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    Layout.preferredWidth: 150
                    enabled: trackerRoot.authenticated
                    selectByMouse: true
                    onTextEdited: {
                        let t = trackerRoot.topics;
                        t[index] = text;
                        trackerRoot.topics = t;
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
