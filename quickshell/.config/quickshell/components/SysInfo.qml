import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    implicitWidth: layout.implicitWidth + 32
    implicitHeight: 32

    property string cpuUsage: "--%"
    property string memUsage: "--%"
    property string batUsage: "--%"
    property bool isCharging: false

    // Update system info using shell commands
    Process {
        id: sysInfoProc
        command: ["bash", "-c", "printf '%s|%s|%s|%s\\n' \"$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | tr ',' '.')\" \"$(free -m | awk 'NR==2{printf \"%.0f%%\", $3*100/$2 }')\" \"$(upower -i /org/freedesktop/UPower/devices/DisplayDevice | grep percentage | awk '{print $2}' | tr -d '%')\" \"$(upower -i /org/freedesktop/UPower/devices/DisplayDevice | grep state | awk '{print $2}')\""]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.split("|");
                if (parts.length >= 4) {
                    root.cpuUsage = Math.round(parseFloat(parts[0])) + "%";
                    root.memUsage = parts[1];
                    root.batUsage = (parts[2] || "0") + "%";
                    const state = parts[3].trim().toLowerCase();
                    root.isCharging = (state === "charging" || state === "pending-charge" || state === "fully-charged");
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: sysInfoProc.running = true
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        // CPU
        RowLayout {
            spacing: 6
            Text { text: ""; font.pixelSize: 14; color: Theme.blue; font.family: "JetBrainsMono Nerd Font" }
            Text {
                text: root.cpuUsage
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: Theme.fontSize
            }
        }

        Rectangle { width: 1; height: 16; color: Theme.surface1 }

        // RAM
        RowLayout {
            spacing: 6
            Text { text: ""; font.pixelSize: 14; color: Theme.green; font.family: "JetBrainsMono Nerd Font" }
            Text {
                text: root.memUsage
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: Theme.fontSize
            }
        }

        Rectangle { width: 1; height: 16; color: Theme.surface1 }

        // Battery
        RowLayout {
            spacing: 6
            Text { 
                text: root.isCharging ? "󱐋" : ""; 
                font.pixelSize: 14; 
                color: root.isCharging ? Theme.yellow : Theme.teal; 
                font.family: "JetBrainsMono Nerd Font" 
            }
            Text {
                text: root.batUsage
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
