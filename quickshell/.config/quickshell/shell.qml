import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "theme"
import "components"

ShellRoot {
    id: root

    // Professional way to handle toggles used by end4
    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggles the application launcher"
        onPressed: {
            appLauncher.visible = !appLauncher.visible;
        }
    }

    GlobalShortcut {
        name: "clipboardToggle"
        description: "Toggles the clipboard manager"
        onPressed: {
            clipboardMenu.visible = !clipboardMenu.visible;
        }
    }

    PanelWindow {
        id: panel

        anchors {
            top: true
            left: true
            right: true
        }

        margins {
            top: 8
            left: 10
            right: 10
        }

        implicitHeight: 40
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left Group (Workspaces + Title)
            RowLayout {
                id: leftGroup
                spacing: 8
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                Workspaces { }
                // Title { }
            }

            // Spacer to keep clock centered
            Item {
                Layout.fillWidth: true
            }

            // Center Group (Clock + Media)
            RowLayout {
                id: centerGroup
                spacing: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Media { }
                Clock { }
            }

            // Spacer to keep clock centered
            Item {
                Layout.fillWidth: true
            }

            // Right Group
            RowLayout {
                id: rightGroup
                spacing: 8
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                SysTray { }
                Network { }
                SysInfo { }
                Target { }
            }
        }
    }

    // Global Floating Elements
    Tooltip { }
    MediaPopup { }
    OSD { id: globalOSD }
    SidePanel { id: sidePanel }
    NotificationPopup { id: notifPopup }
    Launcher { id: appLauncher; visible: false }
    Clipboard { id: clipboardMenu; visible: false }

    // Click-away listener (Closes panel when clicking outside)
    PanelWindow {
        id: clickAway
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        visible: sidePanel.isOpen || appLauncher.visible || clipboardMenu.visible
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "click-away"
        color: "transparent"
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                sidePanel.isOpen = false;
                appLauncher.visible = false;
                clipboardMenu.visible = false;
            }
        }
    }

    // Top-Right Hover Trigger
    PanelWindow {
        id: trigger
        anchors {
            top: true
            right: true
        }
        width: 10
        height: 10
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "trigger"
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: sidePanel.isOpen = true
        }
    }

    // Notification Server
    NotificationServer {
        id: notifServer
        onNotification: (n) => {
            sidePanel.addNotification(n);
            // Only show popup if side panel is closed
            if (!sidePanel.isOpen) {
                notifPopup.show(n);
            }
        }
    }

    // Volume Listener (Reverted to Polling for reliability)
    property string lastVolState: ""
    Process {
        id: volWatcher
        command: ["bash", "-c", "while true; do wpctl get-volume @DEFAULT_AUDIO_SINK@; sleep 0.1; done"]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const trimmedMsg = msg.trim();
                if (trimmedMsg !== root.lastVolState && trimmedMsg.startsWith("Volume:")) {
                    const muted = trimmedMsg.indexOf("[MUTED]") !== -1;
                    const vol = parseFloat(trimmedMsg.split(/\s+/)[1]);
                    if (!isNaN(vol)) {
                        let icon = "󰕾";
                        if (vol < 0.33) icon = "󰕿";
                        else if (vol < 0.66) icon = "󰖀";
                        globalOSD.show("volume", vol, icon, muted);
                    }
                    root.lastVolState = trimmedMsg;
                }
            }
        }
    }

    property real lastBrightness: -1.0
    Process {
        id: brightPercentProc
        command: ["bash", "-c", "while true; do printf '%s|%s\\n' \"$(brightnessctl m)\" \"$(brightnessctl g)\"; sleep 0.2; done"]
        running: true
        stdout: SplitParser {
            onRead: msg => {
                const parts = msg.split("|");
                if (parts.length >= 2) {
                    const max = parseInt(parts[0]);
                    const cur = parseInt(parts[1]);
                    const percent = cur / max;
                    if (root.lastBrightness === -1.0) {
                        root.lastBrightness = percent;
                    } else if (Math.abs(percent - root.lastBrightness) > 0.001) {
                        let icon = "󰃠";
                        if (percent < 0.33) icon = "󰃞";
                        else if (percent < 0.66) icon = "󰃟";
                        globalOSD.show("brightness", percent, icon);
                        root.lastBrightness = percent;
                    }
                }
            }
        }
    }
}
