import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: 1
    
    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 32

    property real cpuVal: 0.0
    property real memVal: 0.0
    property real batVal: 0.0
    property bool isCharging: false

    Process {
        id: sysInfoProc
        command: ["bash", "-c", "printf '%s|%s|%s|%s\\n' \"$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | tr ',' '.')\" \"$(free -m | awk 'NR==2{printf \"%.2f\", $3/$2 }')\" \"$(upower -i /org/freedesktop/UPower/devices/DisplayDevice | grep percentage | awk '{print $2}' | tr -d '%')\" \"$(upower -i /org/freedesktop/UPower/devices/DisplayDevice | grep state | awk '{print $2}')\""]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.split("|");
                if (parts.length >= 4) {
                    root.cpuVal = parseFloat(parts[0]) / 100.0;
                    root.memVal = parseFloat(parts[1]);
                    root.batVal = parseFloat(parts[2] || "0") / 100.0;
                    const state = parts[3].trim().toLowerCase();
                    root.isCharging = (state === "charging" || state === "pending-charge" || state === "fully-charged");
                }
            }
        }
    }

    Timer { interval: 5000; repeat: true; running: true; onTriggered: sysInfoProc.running = true }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipController.show("System Stats: CPU " + Math.round(root.cpuVal*100) + "%, RAM " + Math.round(root.memVal*100) + "%, BAT " + Math.round(root.batVal*100) + "%", root)
        onExited: TooltipController.hide()
    }

    Behavior on color { ColorAnimation { duration: 200 } }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        // CPU
        RowLayout {
            spacing: 8
            ProgressCircle { value: root.cpuVal; color: Theme.blue }
            Text { text: Math.round(root.cpuVal * 100) + "%"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: Theme.fontSize }
        }

        Rectangle { width: 1; height: 14; color: Theme.surface1 }

        // RAM
        RowLayout {
            spacing: 8
            ProgressCircle { value: root.memVal; color: Theme.green }
            Text { text: Math.round(root.memVal * 100) + "%"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: Theme.fontSize }
        }

        Rectangle { width: 1; height: 14; color: Theme.surface1 }

        // Battery
        RowLayout {
            spacing: 8
            ProgressCircle { 
                value: root.batVal; 
                color: root.isCharging ? Theme.yellow : Theme.teal
                
                // Charging Indicator (Inner Dot)
                Rectangle {
                    anchors.centerIn: parent
                    width: 4; height: 4; radius: 2
                    color: Theme.yellow
                    visible: root.isCharging
                    
                    SequentialAnimation on opacity {
                        running: root.isCharging
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 800; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                    }
                }
            }
            Text { text: Math.round(root.batVal * 100) + "%"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: Theme.fontSize }
        }
    }
}
