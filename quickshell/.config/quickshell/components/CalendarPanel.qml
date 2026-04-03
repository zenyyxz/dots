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
        horizontalCenter: true
    }
    
    margins {
        top: 50
    }

    implicitWidth: 350
    implicitHeight: 400
    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    property date selectedDate: new Date()
    property date viewDate: new Date()

    function nextMonth() {
        var d = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1);
        viewDate = d;
    }

    function prevMonth() {
        var d = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1);
        viewDate = d;
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 20
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        // Slide animation
        y: root.isOpen ? 0 : -20
        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header: Month/Year and Navigation
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: Qt.formatDate(viewDate, "MMMM yyyy")
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 18; font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                RowLayout {
                    spacing: 10
                    
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: prevMouse.containsMouse ? Theme.surface1 : Theme.surface0
                        Text { anchors.centerIn: parent; text: "󰁍"; color: Theme.mauve; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.prevMonth() }
                    }
                    
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: nextMouse.containsMouse ? Theme.surface1 : Theme.surface0
                        Text { anchors.centerIn: parent; text: "󰁔"; color: Theme.mauve; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.nextMonth() }
                    }
                }
            }

            // Weekdays
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
                        font.pixelSize: 12; font.bold: true
                    }
                }
            }

            // Calendar Grid
            GridLayout {
                id: grid
                columns: 7
                Layout.fillWidth: true
                Layout.fillHeight: true
                rowSpacing: 5; columnSpacing: 5

                property int daysInMonth: new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate()
                property int firstDayOffset: new Date(viewDate.getFullYear(), viewDate.getMonth(), 1).getDay()

                Repeater {
                    model: 42 // 6 weeks
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        radius: 8
                        
                        property int day: index - grid.firstDayOffset + 1
                        property bool isCurrentMonth: day > 0 && day <= grid.daysInMonth
                        property bool isToday: {
                            var today = new Date();
                            return isCurrentMonth && 
                                   day === today.getDate() && 
                                   viewDate.getMonth() === today.getMonth() && 
                                   viewDate.getFullYear() === today.getFullYear();
                        }
                        
                        color: isToday ? Theme.mauve : (dayMouse.containsMouse && isCurrentMonth ? Theme.surface1 : "transparent")
                        opacity: isCurrentMonth ? 1.0 : 0.2
                        
                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (day > 0 && day <= grid.daysInMonth) return day;
                                if (day <= 0) {
                                    var prevMonthLastDay = new Date(viewDate.getFullYear(), viewDate.getMonth(), 0).getDate();
                                    return prevMonthLastDay + day;
                                }
                                return day - grid.daysInMonth;
                            }
                            color: isToday ? Theme.base : Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 12
                            font.bold: isToday
                        }
                        
                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: isCurrentMonth
                            onClicked: if (isCurrentMonth) root.selectedDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), day)
                        }
                    }
                }
            }
        }
    }
}
