//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=qt6ct
//@ pragma IconTheme "breeze-dark"
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
    id: shellRoot

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

                DistroIcon { }
                Workspaces { }
                Media { }
                // Title { }
            }

            // Spacer to keep layout balanced
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

        // Absolute Center Clock
        Clock {
            anchors.centerIn: parent
        }
    }

    // Global Floating Elements
    Tooltip { }
    MediaPopup { }
    OSD { id: globalOSD }
    SidePanel { 
        id: sidePanel
        onRequestVpnConfig: {
            vpnConfig.isOpen = true;
        }
    }
    NotificationPopup { id: notifPopup }
    CalendarPanel { id: calendarPanel }
    Launcher { id: appLauncher; visible: false }
    Clipboard { id: clipboardMenu; visible: false }
    ScreenSnip { id: screenSnip; visible: false }
    ChatWidget { id: chatWidget; isOpen: false }
    VpnConfig { id: vpnConfig; isOpen: false }

    // Global Shortcuts
    GlobalShortcut {
        name: "vpnConfigToggle"
        description: "Toggles the VPN configuration window"
        onPressed: {
            vpnConfig.isOpen = !vpnConfig.isOpen;
        }
    }

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

    GlobalShortcut {
        name: "screenshotToggle"
        description: "Toggles the screen snip tool"
        onPressed: {
            screenSnip.visible = !screenSnip.visible;
        }
    }

    GlobalShortcut {
        name: "chatToggle"
        description: "Toggles the AI Chat widget"
        onPressed: {
            chatWidget.isOpen = !chatWidget.isOpen;
        }
    }

    // Click-away listener (Closes panel when clicking outside)
    PanelWindow {
        id: clickAway
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        visible: sidePanel.isOpen || appLauncher.visible || clipboardMenu.visible || screenSnip.visible || chatWidget.isOpen || vpnConfig.isOpen || calendarPanel.isOpen
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
                screenSnip.visible = false;
                chatWidget.isOpen = false;
                vpnConfig.isOpen = false;
                calendarPanel.isOpen = false;
            }
        }
    }

    // Top-Left Hover Trigger
    PanelWindow {
        id: leftTrigger
        anchors {
            top: true
            left: true
        }
        width: 10
        height: 10
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "left-trigger"
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: chatWidget.isOpen = true
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
            // Only show popup if side panel is closed AND DND is disabled
            if (!sidePanel.isOpen && !sidePanel.dndEnabled) {
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
                if (trimmedMsg !== shellRoot.lastVolState && trimmedMsg.startsWith("Volume:")) {
                    const muted = trimmedMsg.indexOf("[MUTED]") !== -1;
                    const vol = parseFloat(trimmedMsg.split(/\s+/)[1]);
                    if (!isNaN(vol)) {
                        let icon = "󰕾";
                        if (vol < 0.33) icon = "󰕿";
                        else if (vol < 0.66) icon = "󰖀";
                        globalOSD.show("volume", vol, icon, muted);
                    }
                    shellRoot.lastVolState = trimmedMsg;
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
                    if (shellRoot.lastBrightness === -1.0) {
                        shellRoot.lastBrightness = percent;
                    } else if (Math.abs(percent - shellRoot.lastBrightness) > 0.001) {
                        let icon = "󰃠";
                        if (percent < 0.33) icon = "󰃞";
                        else if (percent < 0.66) icon = "󰃟";
                        globalOSD.show("brightness", percent, icon);
                        shellRoot.lastBrightness = percent;
                    }
                }
            }
        }
    }
}
