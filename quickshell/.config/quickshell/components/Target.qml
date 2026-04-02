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
    property bool torUpdating: false
    property bool torConfigOk: true

    Process {
        id: targetProc
        // Detect IP + Tor Status + Verify Tor Config (checks for TransPort in torrc)
        command: ["bash", "-c", "ip -4 addr show | grep -v '127.0.0.1' | grep inet | head -n 1 | awk '{print $2}' | cut -d/ -f1 && (systemctl is-active --quiet tor && echo true || echo false) && (grep -q 'TransPort' /etc/tor/torrc 2>/dev/null && echo true || echo false)"]
        running: true
        
        stdout: SplitParser {
            onRead: (msg, index) => {
                if (index == 0) root.localIp = msg.trim() || "Offline";
                else if (index == 1) {
                    root.torActive = (msg.trim() === "true");
                    root.torUpdating = false;
                }
                else if (index == 2) root.torConfigOk = (msg.trim() === "true");
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: !root.torUpdating
        onTriggered: targetProc.running = true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (!root.torConfigOk) {
                // If config is missing, offer a helpful hint (or run setup script)
                Quickshell.execDetached(["notify-send", "Tor Setup Required", "Run vpn/tor/install_tor_config.sh to configure torrc."]);
                return;
            }
            root.torUpdating = true;
            const scriptPath = Quickshell.shellPath("../../../vpn/tor/toggle_tor.sh");
            const action = root.torActive ? "stop" : "start";
            Quickshell.execDetached(["pkexec", "bash", scriptPath, action]);
            root.torActive = !root.torActive;
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
                    visible: root.torActive || !root.torConfigOk
                    scale: 1.0
                    
                    SequentialAnimation on opacity {
                        running: root.torActive || !root.torConfigOk
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 0; to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.3; to: 0; duration: 1200; easing.type: Easing.InOutSine }
                    }

                    SequentialAnimation on scale {
                        running: root.torActive || !root.torConfigOk
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 0.8; to: 2.2; duration: 1200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 2.2; to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Warning Icon (If config is missing)
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
            }
        }

        Text {
            text: !root.torConfigOk ? "Setup Tor" : (root.torActive ? "Tor Active" : root.localIp)
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }
}
