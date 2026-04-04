import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "calendar-panel"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        top: true
        left: true
        right: true
    }
    
    margins {
        top: 50
    }

    implicitWidth: 680
    implicitHeight: 450
    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    onIsOpenChanged: {
        if (isOpen) {
            calViewDate = new Date();
            calCurrentTime = new Date();
        }
    }

    property date calSelectedDate: new Date()
    property date calViewDate: new Date()
    property date calCurrentTime: new Date()
    
    // Progress ring angle with smooth reset behavior
    property real progressAngle: 0
    Behavior on progressAngle {
        NumberAnimation {
            duration: (root.calCurrentTime.getSeconds() === 0) ? 200 : 0
            easing.type: Easing.OutQuint
        }
    }

    function nextMonth() {
        root.calViewDate = new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth() + 1, 1);
    }

    function prevMonth() {
        root.calViewDate = new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth() - 1, 1);
    }

    // Timer for the smooth luxury sweep (60 FPS)
    Timer {
        interval: 16
        repeat: true
        running: root.isOpen
        onTriggered: {
            root.calCurrentTime = new Date();
            var ms = root.calCurrentTime.getMilliseconds();
            var secs = root.calCurrentTime.getSeconds() + ms/1000;
            root.progressAngle = (secs * 6 - 90);
        }
    }

    Rectangle {
        id: container
        width: 650
        height: 400
        anchors.horizontalCenter: parent.horizontalCenter
        
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        y: root.isOpen ? 0 : -20
        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 25

            // --- Calendar Pill ---
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 320
                color: Theme.surface0
                radius: 20
                border.color: Theme.surface1
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Qt.formatDate(root.calViewDate, "MMMM yyyy")
                            color: Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 16; font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 72; height: 32; radius: 16
                            color: Theme.mantle
                            border.color: Theme.surface1; border.width: 1
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: prevMouse.containsMouse ? Theme.surface1 : "transparent"
                                    scale: prevMouse.pressed ? 0.9 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "󰁍"; color: Theme.sapphire; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.prevMonth() }
                                }
                                Rectangle {
                                    width: 26; height: 26; radius: 13
                                    color: nextMouse.containsMouse ? Theme.surface1 : "transparent"
                                    scale: nextMouse.pressed ? 0.9 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "󰁔"; color: Theme.sapphire; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.nextMonth() }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: Theme.mauve
                                font.family: Theme.fontName
                                font.pixelSize: 11; font.bold: true
                            }
                        }
                    }

                    GridLayout {
                        id: grid
                        columns: 7
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        rowSpacing: 2; columnSpacing: 2
                        property int daysInMonth: new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth() + 1, 0).getDate()
                        property int firstDayOffset: new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth(), 1).getDay()
                        Repeater {
                            model: 42
                            delegate: Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 6
                                property int dayNum: index - grid.firstDayOffset + 1
                                property bool isCurrentMonth: dayNum > 0 && dayNum <= grid.daysInMonth
                                property bool isToday: {
                                    var today = new Date();
                                    return isCurrentMonth && dayNum === today.getDate() && root.calViewDate.getMonth() === today.getMonth() && root.calViewDate.getFullYear() === today.getFullYear();
                                }
                                color: isToday ? Theme.sapphire : (dayMouse.containsMouse && isCurrentMonth ? Theme.surface1 : "transparent")
                                opacity: isCurrentMonth ? 1.0 : 0.2
                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (dayNum > 0 && dayNum <= grid.daysInMonth) return dayNum;
                                        if (dayNum <= 0) return new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth(), 0).getDate() + dayNum;
                                        return dayNum - grid.daysInMonth;
                                    }
                                    color: isToday ? Theme.base : Theme.text
                                    font.family: Theme.fontName; font.pixelSize: 11; font.bold: isToday
                                }
                                MouseArea { id: dayMouse; anchors.fill: parent; hoverEnabled: isCurrentMonth; onClicked: if (isCurrentMonth) root.calSelectedDate = new Date(root.calViewDate.getFullYear(), root.calViewDate.getMonth(), dayNum) }
                            }
                        }
                    }
                }
            }

            // --- Analog Clock Section (PREMIUM) ---
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 20

                Item {
                    Layout.alignment: Qt.AlignCenter
                    width: 240; height: 240

                    Canvas {
                        id: clockCanvas
                        anchors.fill: parent
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            
                            var centerX = width / 2;
                            var centerY = height / 2;
                            var radius = width / 2 - 15;

                            var now = root.calCurrentTime;
                            var ms = now.getMilliseconds();
                            var seconds = now.getSeconds() + ms/1000;
                            var minutes = now.getMinutes() + seconds/60;
                            var hours = (now.getHours() % 12) + minutes/60;

                            // 1. Progress Outer Ring (Seconds) - Using animated progressAngle
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius + 8, -Math.PI/2, root.progressAngle * Math.PI / 180);
                            ctx.strokeStyle = Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.2);
                            ctx.lineWidth = 2;
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                            ctx.strokeStyle = Theme.surface1;
                            ctx.lineWidth = 3;
                            ctx.stroke();

                            var currentHourInt = Math.floor(hours) || 12;
                            for (var i = 1; i <= 12; i++) {
                                var angle = (i * 30 - 90) * Math.PI / 180;
                                var isHigh = (i === currentHourInt);
                                ctx.strokeStyle = isHigh ? Theme.sapphire : Theme.surface2;
                                ctx.lineWidth = isHigh ? 3 : 2;
                                var mLen = isHigh ? 12 : 8;
                                ctx.beginPath();
                                ctx.moveTo(centerX + (radius - mLen) * Math.cos(angle), centerY + (radius - mLen) * Math.sin(angle));
                                ctx.lineTo(centerX + radius * Math.cos(angle), centerY + radius * Math.sin(angle));
                                ctx.stroke();
                            }

                            // 3. Minimalist Numbers (12, 3, 6, 9)
                            ctx.font = "bold 14px '" + Theme.fontName + "'";
                            ctx.textAlign = "center";
                            ctx.textBaseline = "middle";
                            var nums = [12, 3, 6, 9];
                            nums.forEach(n => {
                                var nAngle = (n * 30 - 90) * Math.PI / 180;
                                ctx.fillStyle = Theme.mauve;
                                ctx.fillText(n.toString(), centerX + (radius - 28) * Math.cos(nAngle), centerY + (radius - 28) * Math.sin(nAngle));
                            });

                            // 4. Hands with Shadow
                            ctx.shadowBlur = 10;
                            ctx.shadowColor = Qt.rgba(0,0,0,0.5);
                            ctx.lineCap = "round";

                            // Hour Hand
                            var hourAngle = (hours * 30 - 90) * Math.PI / 180;
                            ctx.strokeStyle = Theme.text;
                            ctx.lineWidth = 6;
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(centerX + (radius * 0.45) * Math.cos(hourAngle), centerY + (radius * 0.45) * Math.sin(hourAngle));
                            ctx.stroke();

                            // Minute Hand
                            var minAngle = (minutes * 6 - 90) * Math.PI / 180;
                            ctx.strokeStyle = Theme.text;
                            ctx.lineWidth = 4;
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(centerX + (radius * 0.75) * Math.cos(minAngle), centerY + (radius * 0.75) * Math.sin(minAngle));
                            ctx.stroke();

                            // 5. Second Hand (No Shadow, Smooth Sweep)
                            ctx.shadowBlur = 0;
                            var secAngle = (seconds * 6 - 90) * Math.PI / 180;
                            ctx.strokeStyle = Theme.sapphire;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(centerX + (radius * 0.88) * Math.cos(secAngle), centerY + (radius * 0.88) * Math.sin(secAngle));
                            ctx.stroke();

                            // Center Cap
                            ctx.fillStyle = Theme.mauve;
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, 5, 0, 2 * Math.PI);
                            ctx.fill();
                        }

                        Connections {
                            target: root
                            function onCalCurrentTimeChanged() { clockCanvas.requestPaint(); }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignCenter
                    spacing: 5
                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: Qt.formatTime(root.calCurrentTime, "hh:mm:ss AP")
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 24; font.bold: true
                    }
                    Text {
                        Layout.alignment: Qt.AlignCenter
                        text: Qt.formatDate(root.calCurrentTime, "dddd, d MMMM yyyy")
                        color: Theme.subtext0
                        font.family: Theme.fontName
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
