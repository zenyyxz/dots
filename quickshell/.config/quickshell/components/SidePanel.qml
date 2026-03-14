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
        top: 60
        bottom: 15
        right: 15
    }

    implicitWidth: 380
    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    // Notification Model
    ListModel { id: notifModel }

    function addNotification(n) {
        notifModel.insert(0, { 
            "notifObject": n,
            "summaryText": n.summary || "Notification",
            "bodyText": n.body || ""
        });
    }

    // --- State Properties ---
    property bool wifiEnabled: true
    property bool bluetoothEnabled: true
    property bool flightMode: false
    property bool idleInhibited: false
    
    property real volume: 0.0
    property bool muted: false
    property bool isMovingVolume: false
    
    property real brightness: 1.0
    property bool isMovingBrightness: false

    // --- Process Handlers ---
    Process {
        id: stateUpdater
        command: ["bash", "-c", "printf '%s|%s|%s|%s|%s\\n' \"$(nmcli radio wifi)\" \"$(bluetoothctl show | grep 'Powered:' | awk '{print $2}')\" \"$(rfkill list all | grep -qi 'all: blocked' && echo 'blocked' || echo 'unblocked')\" \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\" \"$(brightnessctl -m | cut -d, -f4 | tr -d '%')\""]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.trim().split("|");
                if (parts.length >= 5) {
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
                }
            }
        }
    }

    Timer { interval: 2000; repeat: true; running: root.isOpen; onTriggered: stateUpdater.running = true }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        x: root.isOpen ? 0 : 50
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 25

            // --- Quick Toggles Grid ---
            GridLayout {
                columns: 2
                columnSpacing: 15
                rowSpacing: 15
                Layout.fillWidth: true

                // WiFi Toggle
                ControlCenterButton {
                    icon: "󰤨"
                    label: "WiFi"
                    active: root.wifiEnabled
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiEnabled ? "off" : "on"]);
                        root.wifiEnabled = !root.wifiEnabled;
                    }
                }

                // Bluetooth Toggle
                ControlCenterButton {
                    icon: "󰂯"
                    label: "Bluetooth"
                    active: root.bluetoothEnabled
                    onClicked: {
                        Quickshell.execDetached(["bluetoothctl", "power", root.bluetoothEnabled ? "off" : "on"]);
                        root.bluetoothEnabled = !root.bluetoothEnabled;
                    }
                }

                // Flight Mode
                ControlCenterButton {
                    icon: "󰀝"
                    label: "Flight Mode"
                    active: root.flightMode
                    onClicked: {
                        Quickshell.execDetached(["rfkill", root.flightMode ? "unblock" : "block", "all"]);
                        root.flightMode = !root.flightMode;
                    }
                }

                // Idle Inhibitor
                ControlCenterButton {
                    icon: root.idleInhibited ? "󰈈" : "󰈉"
                    label: root.idleInhibited ? "Inhibiting" : "Idle OK"
                    active: root.idleInhibited
                    onClicked: {
                        root.idleInhibited = !root.idleInhibited;
                        if (root.idleInhibited) {
                             Quickshell.execDetached(["systemd-inhibit", "--what=idle", "--who=quickshell", "--why=manual-inhibit", "sleep", "infinity"]);
                        } else {
                             Quickshell.execDetached(["pkill", "-f", "manual-inhibit"]);
                        }
                    }
                }
            }

            // --- Sliders ---
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true

                // Volume Slider
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

                // Brightness Slider
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

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1; opacity: 0.5 }

            // --- Notifications History ---
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Notifications"
                        color: Theme.text
                        font.family: Theme.fontName; font.pixelSize: 16; font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Clear All"
                        color: Theme.mauve; font.family: Theme.fontName; font.pixelSize: 12
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                for (let i = 0; i < notifModel.count; i++) {
                                    const n = notifModel.get(i).notifObject;
                                    if (n) n.dismiss();
                                }
                                notifModel.clear();
                            }
                        }
                    }
                }

                ListView {
                    id: notifList
                    Layout.fillHeight: true; Layout.fillWidth: true
                    model: notifModel
                    spacing: 10
                    clip: true
                    delegate: Rectangle {
                        width: ListView.view.width; height: 70; radius: 12
                        color: Theme.surface0; border.color: Theme.surface1; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            Rectangle { width: 32; height: 32; radius: 6; color: Theme.surface1; Text { anchors.centerIn: parent; text: "󰵚"; color: Theme.mauve; font.pixelSize: 14 } }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 0
                                Text { text: model.summaryText; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text { text: model.bodyText; color: Theme.subtext0; font.family: Theme.fontName; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true; maximumLineCount: 1 }
                            }
                            Text {
                                text: "󰅖"
                                font.family: "JetBrainsMono Nerd Font"; color: Theme.surface2
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        const n = notifModel.get(index).notifObject;
                                        if (n) n.dismiss();
                                        notifModel.remove(index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Power Menu
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 30
                PowerButton { icon: "󰤄"; accentColor: Theme.red; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
                PowerButton { icon: "󰑓"; accentColor: Theme.yellow; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
                PowerButton { icon: "󰍃"; accentColor: Theme.blue; onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"]) }
            }
        }
    }
}
