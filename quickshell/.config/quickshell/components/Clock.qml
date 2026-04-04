import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

// Parent Pill
Rectangle {
    id: root
    
    // 1. Dynamic Background and Hover (Glassmorphic feel)
    color: mouseArea.containsMouse ? Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.9) : Theme.mantle
    radius: Theme.radius
    
    // 2. Active Glow when dashboard is open (Safe implementation)
    border.color: (calendar && calendar.isOpen) ? Theme.sapphire : (mouseArea.containsMouse ? Theme.surface2 : Theme.borderColor)
    border.width: 1
    
    implicitWidth: mainLayout.implicitWidth + 24
    implicitHeight: 32

    // Background Glow
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: root.radius + 4
        color: Theme.mauve
        opacity: (calendar && calendar.isOpen) ? 0.2 : 0
        visible: opacity > 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    
    property string timeStr: "--:--"
    property string dateStr: "---"
    property real minuteProgress: 0
    property var calendar: null

    function updateTime() {
        const d = new Date();
        
        // 12-Hour Format logic
        let hours = d.getHours();
        const minutes = d.getMinutes().toString().padStart(2, '0');
        hours = hours % 12;
        hours = hours ? hours : 12; 
        root.timeStr = hours + ":" + minutes;
        
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        
        root.dateStr = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
        root.minuteProgress = (d.getSeconds() + d.getMilliseconds() / 1000) / 60;
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 100 
        repeat: true
        running: true
        onTriggered: updateTime()
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: if (root.calendar) root.calendar.isOpen = !root.calendar.isOpen
    }

    // 3. Minute Progress Underline
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: 1
        width: (parent.width - 20) * root.minuteProgress
        color: Theme.sapphire
        opacity: 0.6
    }

    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 10

        // --- Time Child Pill ---
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: timeLayout.implicitWidth + 16
            color: Theme.surface0
            radius: 12
            
            RowLayout {
                id: timeLayout
                anchors.centerIn: parent
                spacing: 8
                
                // 4. Tiny Animated Clock Icon
                Item {
                    width: 14; height: 14
                    Canvas {
                        id: tinyClock
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var now = new Date();
                            var h = now.getHours() % 12;
                            var m = now.getMinutes();
                            
                            ctx.strokeStyle = Theme.mauve;
                            ctx.lineWidth = 1.2;
                            ctx.beginPath();
                            ctx.arc(7, 7, 6, 0, 2*Math.PI);
                            ctx.stroke();
                            
                            ctx.lineCap = "round";
                            ctx.strokeStyle = Theme.sapphire;
                            // Minute hand
                            ctx.beginPath();
                            ctx.moveTo(7, 7);
                            ctx.lineTo(7 + 4 * Math.cos((m * 6 - 90) * Math.PI / 180), 7 + 4 * Math.sin((m * 6 - 90) * Math.PI / 180));
                            ctx.stroke();
                            // Hour hand
                            ctx.beginPath();
                            ctx.moveTo(7, 7);
                            ctx.lineTo(7 + 2.5 * Math.cos((h * 30 + m * 0.5 - 90) * Math.PI / 180), 7 + 2.5 * Math.sin((h * 30 + m * 0.5 - 90) * Math.PI / 180));
                            ctx.stroke();
                        }
                        Connections {
                            target: root
                            function onMinuteProgressChanged() { tinyClock.requestPaint(); }
                        }
                    }
                }
                
                Text {
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 12
                    font.bold: true 
                    text: root.timeStr
                }
            }
        }

        // --- Date Child Pill ---
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: dateLayout.implicitWidth + 16
            color: "transparent" 
            radius: 12
            
            RowLayout {
                id: dateLayout
                anchors.centerIn: parent
                spacing: 6
                
                Text {
                    text: "󰃭"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Theme.subtext0 
                }
                
                Text {
                    color: Theme.subtext0 
                    font.family: Theme.fontName
                    font.pixelSize: 10
                    text: root.dateStr
                }
            }
        }
    }
}
