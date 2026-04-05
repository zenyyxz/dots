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

    implicitWidth: Math.min(mainLayout.implicitWidth + 24, 450)
    implicitHeight: maxHeight > 0 ? Math.min(mainLayout.implicitHeight + 24, maxHeight) : 1000 
    
    // Force fill if maxHeight is 0
    anchors.fill: (maxHeight === 0 && parent) ? parent : undefined
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: Theme.borderWidth

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 8

        RowLayout {
            id: headerArea
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
                    font.pixelSize: 20 // Smaller 
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
                    sourceSize: Qt.size(18, 18) // Smaller
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    
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
            spacing: 8
            Layout.fillWidth: true
            
            Text { text: "#"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 12; Layout.preferredWidth: 20 }
            Text { text: "Lesson"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 12; Layout.preferredWidth: 120 }
            
            Repeater {
                model: trackerRoot.columnTitles.length
                delegate: Rectangle {
                    Layout.preferredWidth: 40
                    height: 20
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
                        font.pixelSize: 12
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
            id: separator
            Layout.fillWidth: true
            height: 1
            color: Theme.surface1
        }

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            
            ColumnLayout {
                id: rowsLayout
                width: scrollView.width
                spacing: 4 // Compact

                // Rows
                Repeater {
                    model: trackerRoot.topics.length
                    delegate: RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        
                        Text {
                            text: (index + 1).toString()
                            color: Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 11
                            Layout.preferredWidth: 20
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            Layout.preferredWidth: 120
                            height: 18 // Compact
                            color: "transparent"
                            radius: 4
                            border.color: topicInput.activeFocus ? "white" : "transparent"
                            border.width: 1

                            Text {
                                anchors.fill: parent
                                anchors.margins: 2
                                text: trackerRoot.topics[index]
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                visible: !topicInput.activeFocus
                            }

                            TextInput {
                                id: topicInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: trackerRoot.topics[index]
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                enabled: trackerRoot.authenticated
                                selectByMouse: true
                                visible: topicInput.activeFocus || (trackerRoot.authenticated && mouseArea.containsMouse)
                                onTextEdited: {
                                    let t = trackerRoot.topics;
                                    t[index] = text;
                                    trackerRoot.topics = t;
                                }
                            }
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                enabled: trackerRoot.authenticated && !topicInput.activeFocus
                                hoverEnabled: true
                                onClicked: topicInput.forceActiveFocus()
                            }
                        }

                        StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 40; enabled: trackerRoot.authenticated }
                        StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 40; enabled: trackerRoot.authenticated }
                        StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 40; enabled: trackerRoot.authenticated }
                        StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.preferredWidth: 40; enabled: trackerRoot.authenticated }
                    }
                }
            }
        }
    }
}
