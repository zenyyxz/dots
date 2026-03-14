import QtQuick
import QtQuick.Layouts
import "../theme"

// Parent Pill
Rectangle {
    id: root
    
    color: Theme.mantle
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: mainLayout.implicitWidth + 20
    implicitHeight: 32

    property string timeStr: "--:--"
    property string dateStr: "---"

    function updateTime() {
        const d = new Date();
        root.timeStr = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
        
        const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        
        // Exact Format: Saturday, 14 March
        root.dateStr = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: updateTime()
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 8

        // --- Time Child Pill ---
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: timeLayout.implicitWidth + 16
            color: Theme.surface0
            radius: 12
            
            RowLayout {
                id: timeLayout
                anchors.centerIn: parent
                spacing: 6
                
                Text {
                    text: "󱑂"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Theme.mauve
                }
                
                Text {
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    font.bold: true
                    text: root.timeStr
                }
            }
        }

        // --- Date Child Pill ---
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: dateLayout.implicitWidth + 16
            color: Theme.surface0
            radius: 12
            
            RowLayout {
                id: dateLayout
                anchors.centerIn: parent
                spacing: 6
                
                Text {
                    text: "󰃭"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Theme.mauve
                }
                
                Text {
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    font.bold: true
                    text: root.dateStr
                }
            }
        }
    }
}
