import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "side-panel"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        top: true
        bottom: true
        right: true
    }
    
    margins {
        top: 56
        bottom: 8
        right: 8
    }

    implicitWidth: 434
    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    onIsOpenChanged: {
        if (isOpen) {
            uptimeProc.running = true;
            powerProfileProc.running = true;
            stateUpdater.running = true;
        }
    }

    ListModel { id: notifModel }

    function addNotification(n) {
        notifModel.insert(0, { 
            "notifObject": n,
            "summaryText": n.summary || "Notification",
            "bodyText": n.body || ""
        });
    }

    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool flightMode: false
    property bool idleInhibited: false
    property bool vpnEnabled: false
    property bool vpnUpdating: vpnToggleProc.running
    property bool dndEnabled: false
    
    signal requestVpnConfig()

    property string currentPowerProfile: "balanced"
    property string uptime: "00:00"
    
    Process {
        id: vpnStatusProc
        command: ["bash", "-c", "([ -f /tmp/sing-box-vpn.pid ] && kill -0 $(cat /tmp/sing-box-vpn.pid) 2>/dev/null && ip addr show tun0 &>/dev/null) && echo 'on' || echo 'off'"]
        running: true
        stdout: SplitParser {
            onRead: msg => { root.vpnEnabled = (msg.trim() === "on") }
        }
    }

    Process {
        id: vpnToggleProc
        onExited: vpnStatusProc.running = true // Immediate poll
    }

    function toggleVpn() {
        if (vpnToggleProc.running) return;
        const scriptPath = Quickshell.shellPath("../../vpn/sing-box/toggle_vpn.sh");
        vpnToggleProc.command = ["pkexec", "bash", scriptPath, root.vpnEnabled ? "stop" : "start"];
        vpnToggleProc.running = true;
    }

    function openVpnConfig() {
        root.requestVpnConfig();
        root.isOpen = false;
    }

    Process {
        id: uptimeProc
        command: ["bash", "-c", "uptime -p | sed 's/up //; s/ hours,/h/; s/ hour,/h/; s/ minutes/m/; s/ minute/m/'"]
        running: true
        stdout: SplitParser {
            onRead: msg => { root.uptime = msg.trim() }
        }
    }
    Timer { interval: 60000; repeat: true; running: root.isOpen; onTriggered: uptimeProc.running = true }

    Process {
        id: powerProfileProc
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: SplitParser {
            onRead: msg => { root.currentPowerProfile = msg.trim() }
        }
    }

    Process {
        id: checkIdle
        command: ["pgrep", "hypridle"]
        running: true
        onExited: (exitCode) => {
            root.idleInhibited = (exitCode !== 0);
        }
    }

    property real volume: 0.0
    property bool muted: false
    property bool isMovingVolume: false
    
    property real brightness: 1.0
    property bool isMovingBrightness: false

    Process {
        id: stateUpdater
        command: ["bash", "-c", "printf '%s|%s|%s|%s|%s|%s\\n' \"$(nmcli radio wifi)\" \"$(bluetoothctl show | grep -q 'Powered: yes' && echo 'yes' || echo 'no')\" \"$(rfkill list | grep -q 'Soft blocked: no' && echo 'unblocked' || echo 'blocked')\" \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\" \"$(brightnessctl -m | cut -d, -f4 | tr -d '%')\" \"$(powerprofilesctl get)\""]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.trim().split("|");
                if (parts.length >= 6) {
                    root.wifiEnabled = (parts[0] === "enabled");
                    root.bluetoothEnabled = (parts[1] === "yes");
                    root.flightMode = (parts[2] === "blocked");
                    
                    if (!root.isMovingVolume) {
                        const volPart = parts[3];
                        root.muted = volPart.includes("[MUTED]");
                        const volMatch = volPart.match(/[0-9.]+/);
                        if (volMatch) {
                            const v = parseFloat(volMatch[0]);
                            if (!isNaN(v)) root.volume = v;
                        }
                    }
                    
                    if (!root.isMovingBrightness) {
                        const b = parseFloat(parts[4]);
                        if (!isNaN(b)) root.brightness = b / 100.0;
                    }
                    
                    root.currentPowerProfile = parts[5].trim();
                }
            }
        }
    }

    Timer { interval: 2000; repeat: true; running: root.isOpen; onTriggered: { stateUpdater.running = true; vpnStatusProc.running = true; } }

    Rectangle {
        id: container
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
        
        x: root.isOpen ? 0 : root.width
        Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                height: 40

                Rectangle {
                    Layout.preferredWidth: uptimeLayout.implicitWidth + 30
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Theme.surface0
                    border.color: Theme.surface1
                    border.width: 1

                    RowLayout {
                        id: uptimeLayout
                        anchors.centerIn: parent
                        spacing: 10
                        Text { text: "󰣇"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; color: Theme.blue }
                        Text {
                            text: root.uptime
                            font.family: Theme.fontName; font.pixelSize: 13; color: Theme.text; font.bold: true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 10
                    PowerButton { 
                        width: 40; height: 40
                        icon: "󰒲"
                        accentColor: Theme.mauve
                        onClicked: Quickshell.execDetached(["systemctl", "suspend"]) 
                    }
                    PowerButton { 
                        width: 40; height: 40
                        icon: "󰐥"
                        accentColor: Theme.red
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) 
                    }
                }
            }

            // --- Quick Toggles Pill ---
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 24
                color: Theme.surface0
                border.color: Theme.surface1
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    ControlCenterIconButton {
                        icon: "󰤨"
                        active: root.wifiEnabled
                        onClicked: {
                            Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
                            root.wifiEnabled = !root.wifiEnabled;
                        }
                    }

                    ControlCenterIconButton {
                        icon: "󰂯"
                        active: root.bluetoothEnabled
                        onClicked: {
                            Quickshell.execDetached(["bluetoothctl", "power", root.bluetoothEnabled ? "off" : "on"]);
                            root.bluetoothEnabled = !root.bluetoothEnabled;
                        }
                    }

                    ControlCenterIconButton {
                        icon: "󰀝"
                        active: root.flightMode
                        onClicked: {
                            Quickshell.execDetached(["rfkill", root.flightMode ? "unblock" : "block", "all"]);
                            root.flightMode = !root.flightMode;
                        }
                    }

                    ControlCenterIconButton {
                        id: vpnBtn
                        icon: "󰖂"
                        active: root.vpnEnabled
                        onClicked: root.toggleVpn()
                        
                        // Triple Staggered Teal Pulsing Aura
                        Repeater {
                            model: 3
                            Rectangle {
                                anchors.centerIn: parent
                                width: 20; height: 20; radius: 10
                                color: Theme.teal
                                opacity: 0
                                visible: root.vpnEnabled || root.vpnUpdating
                                scale: 1.0
                                
                                SequentialAnimation on opacity {
                                    running: root.vpnEnabled || root.vpnUpdating
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 400 }
                                    NumberAnimation { from: 0; to: 0.3; duration: 1200; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.3; to: 0; duration: 1200; easing.type: Easing.InOutSine }
                                }

                                SequentialAnimation on scale {
                                    running: root.vpnEnabled || root.vpnUpdating
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: index * 400 }
                                    NumberAnimation { from: 0.8; to: 2.2; duration: 1200; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 2.2; to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) root.openVpnConfig();
                            }
                        }
                    }

                    ControlCenterIconButton {
                        icon: Quickshell.shellPath("assets/idle-coffee.svg")
                        active: root.idleInhibited
                        onClicked: {
                            if (root.idleInhibited) {
                                 Quickshell.execDetached(["hypridle"]);
                                 root.idleInhibited = false;
                            } else {
                                 Quickshell.execDetached(["pkill", "hypridle"]);
                                 root.idleInhibited = true;
                            }
                        }
                    }
                }
            }

            // --- Power Modes Pill ---
            Rectangle {
                Layout.fillWidth: true
                height: 90
                radius: 24
                color: Theme.surface0
                border.color: Theme.surface1
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    PowerModeButton {
                        icon: "󰓅"
                        label: "Performance"
                        active: root.currentPowerProfile === "performance"
                        onClicked: {
                            Quickshell.execDetached(["powerprofilesctl", "set", "performance"]);
                            root.currentPowerProfile = "performance";
                        }
                    }

                    PowerModeButton {
                        icon: "󰾆"
                        label: "Balanced"
                        active: root.currentPowerProfile === "balanced"
                        onClicked: {
                            Quickshell.execDetached(["powerprofilesctl", "set", "balanced"]);
                            root.currentPowerProfile = "balanced";
                        }
                    }

                    PowerModeButton {
                        icon: "󰌪"
                        label: "Power Saver"
                        active: root.currentPowerProfile === "power-saver"
                        onClicked: {
                            Quickshell.execDetached(["powerprofilesctl", "set", "power-saver"]);
                            root.currentPowerProfile = "power-saver";
                        }
                    }
                }
            }

            // --- Sliders Pill ---
            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 24
                color: Theme.surface0
                border.color: Theme.surface1
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    ControlCenterSlider {
                        icon: root.muted ? "󰝟" : "󰕾"
                        value: root.volume
                        color: Theme.mauve
                        onPressed: root.isMovingVolume = true
                        onReleased: root.isMovingVolume = false
                        onMoved: (val) => {
                            root.volume = val;
                            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)]);
                        }
                    }

                    ControlCenterSlider {
                        icon: "󰃠"
                        value: root.brightness
                        color: Theme.yellow
                        onPressed: root.isMovingBrightness = true
                        onReleased: root.isMovingBrightness = false
                        onMoved: (val) => {
                            root.brightness = val;
                            Quickshell.execDetached(["brightnessctl", "set", Math.round(val * 100) + "%"]);
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1; opacity: 0.3 }

            // --- Notifications ---
            ColumnLayout {
                Layout.fillHeight: true; Layout.fillWidth: true; spacing: 15

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Notifications"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 16; font.bold: true }
                    Item { Layout.fillWidth: true }

                    // Do Not Disturb
                    Rectangle {
                        id: dndBtn; width: 32; height: 32; radius: 16
                        color: root.dndEnabled ? Theme.mauve : (dndMouse.containsMouse ? Theme.surface1 : Theme.surface0)
                        border.color: dndMouse.containsMouse ? Theme.mauve : Theme.surface1; border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        scale: dndMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Text { 
                            anchors.centerIn: parent
                            text: root.dndEnabled ? "󰂛" : "󰂚"
                            color: root.dndEnabled ? Theme.base : Theme.mauve
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 
                        }
                        MouseArea { id: dndMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.dndEnabled = !root.dndEnabled }
                    }

                    // Clear All
                    Rectangle {
                        id: clearNotifsBtn; width: 32; height: 32; radius: 16
                        color: clearNotifMouse.containsMouse ? Theme.red : Theme.surface0
                        border.color: clearNotifMouse.containsMouse ? "transparent" : Theme.surface1; border.width: 1
                        Behavior on color { ColorAnimation { duration: 200 } }
                        scale: clearNotifMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "󰆴"; color: clearNotifMouse.containsMouse ? Theme.base : Theme.mauve; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; Behavior on color { ColorAnimation { duration: 200 } } }
                        MouseArea { id: clearNotifMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { for (let i = 0; i < notifModel.count; i++) { const n = notifModel.get(i).notifObject; if (n) n.dismiss(); } notifModel.clear(); } }
                    }
                }

                ListView {
                    id: notifList; Layout.fillHeight: true; Layout.fillWidth: true; model: notifModel; spacing: 10; clip: true
                    Text { anchors.centerIn: parent; text: "󰣇"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 120; color: Theme.text; opacity: 0.05; visible: notifModel.count === 0 }
                    delegate: Rectangle {
                        width: ListView.view.width; height: 70; radius: 12; color: Theme.surface0; border.color: Theme.surface1; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            Rectangle { width: 32; height: 32; radius: 6; color: Theme.surface1; Text { anchors.centerIn: parent; text: "󰵚"; color: Theme.mauve; font.pixelSize: 14 } }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                Text { text: model.summaryText; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text { text: model.bodyText; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true; maximumLineCount: 1 }
                            }
                            Text { text: "󰅖"; font.family: "JetBrainsMono Nerd Font"; color: Theme.surface2; MouseArea { anchors.fill: parent; onClicked: { const n = notifModel.get(index).notifObject; if (n) n.dismiss(); notifModel.remove(index); } } }
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 30
                PowerButton { width: 50; height: 50; icon: "󰑓"; accentColor: Theme.yellow; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                PowerButton { width: 50; height: 50; icon: "󰍃"; accentColor: Theme.blue; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
            }
        }
    }
}
