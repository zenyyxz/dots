import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    color: mouseArea.containsMouse ? Theme.surface0 : Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 32

    property string localIp: "Offline"
    property bool torActive: false
    property bool torUpdating: toggleProc.running
    property bool torConfigOk: true

    // Robust Poller: Uses a single atomic command to prevent sync issues
    Process {
        id: targetProc
        command: ["bash", "-c", "IP=$(ip -4 addr show | grep -v '127.0.0.1' | grep inet | head -n 1 | awk '{print $2}' | cut -d/ -f1); TOR=$(systemctl is-active --quiet tor && echo true || echo false); CFG=$(grep -q 'TransPort' /etc/tor/torrc 2>/dev/null && echo true || echo false); printf '%s|%s|%s\n' \"$IP\" \"$TOR\" \"$CFG\""]
        running: true
        
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.trim().split("|");
                if (parts.length >= 3) {
                    root.localIp = parts[0] || "Offline";
                    root.torActive = (parts[1] === "true");
                    root.torConfigOk = (parts[2] === "true");
                }
            }
        }
    }

    // Toggle command process
    Process {
        id: toggleProc
        onExited: {
            // Force an immediate refresh
            targetProc.running = false;
            targetProc.running = true;
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            if (!targetProc.running && !toggleProc.running) {
                targetProc.running = true;
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (!root.torConfigOk) {
                Quickshell.execDetached(["notify-send", "Tor Setup Required", "Run vpn/tor/install_tor_config.sh to configure torrc."]);
                return;
            }
            if (toggleProc.running) return;

            // Correct path relative to shell.qml:
            // shell.qml is at quickshell/.config/quickshell/shell.qml
            // vpn/ is at vpn/
            // Path: ../../../vpn/tor/toggle_tor.sh
            const scriptPath = Quickshell.shellPath("../../../vpn/tor/toggle_tor.sh");
            toggleProc.command = ["pkexec", "bash", scriptPath, root.torActive ? "stop" : "start"];
            toggleProc.running = true;
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 12

        Item {
            width: 24; height: 24
            Layout.alignment: Qt.AlignVCenter

            // Triple Staggered Pulsing Aura
            Repeater {
                model: 3
                Rectangle {
                    anchors.centerIn: parent
                    width: 20; height: 20; radius: 10
                    color: root.torConfigOk ? Theme.mauve : Theme.yellow
                    opacity: 0
                    visible: root.torActive || root.torUpdating || !root.torConfigOk
                    scale: 1.0
                    
                    SequentialAnimation on opacity {
                        running: root.torActive || root.torUpdating || !root.torConfigOk
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 0; to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.3; to: 0; duration: 1200; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation on scale {
                        running: root.torActive || root.torUpdating || !root.torConfigOk
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 0.8; to: 2.2; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 2.2; to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Warning Icon
            Text {
                anchors.centerIn: parent
                visible: !root.torConfigOk
                text: "󰀦"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: Theme.yellow
            }

            Image {
                id: onionImg
                anchors.centerIn: parent
                width: 20; height: 20
                source: Quickshell.shellPath("assets/tor-onion.svg")
                sourceSize: Qt.size(40, 40)
                smooth: true
                visible: root.torConfigOk
                fillMode: Image.PreserveAspectFit
                opacity: (root.torActive || root.torUpdating) ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }

        Text {
            text: {
                if (!root.torConfigOk) return "Setup Tor";
                if (root.torUpdating) return root.torActive ? "Stopping Tor..." : "Connecting Tor...";
                if (root.torActive) return "Tor Active";
                return root.localIp;
            }
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
}
