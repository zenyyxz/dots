import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    
    property string subjectName: "Subject"
    property var topics: ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5", "Topic 6", "Topic 7", "Topic 8", "Topic 9", "Topic 10"]
    
    implicitWidth: 420
    implicitHeight: 480
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85) // Correct way to add alpha
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: Theme.borderWidth

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Text {
            text: root.subjectName
            color: Theme.mauve
            font.family: Theme.fontName
            font.pixelSize: 22 // Slightly larger
            font.bold: true
            Layout.alignment: Qt.AlignCenter
        }

        // Table Header
        RowLayout {
            spacing: 10
            Layout.fillWidth: true
            
            Text { text: "Lesson"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.preferredWidth: 150 }
            Text { text: "Theory"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            Text { text: "Revise"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            Text { text: "PP"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
            Text { text: "MP"; color: Theme.lavender; font.family: Theme.fontName; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        }

        // Horizontal Line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.surface1
        }

        // Rows
        Repeater {
            model: 10
            delegate: RowLayout {
                spacing: 10
                Layout.fillWidth: true
                
                Text {
                    text: root.topics[index] || "Lesson " + (index + 1)
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    Layout.preferredWidth: 150
                    elide: Text.ElideRight
                }

                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true }
                StudyCheckBox { Layout.alignment: Qt.AlignCenter; Layout.fillWidth: true }
            }
        }
    }
}
