import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "theme"
import "components"

ShellRoot {
    id: root

	Socket {
		path: `${Quickshell.env("XDG_RUNTIME_DIR")}/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
		connected: true

		Component.onCompleted: console.log("Connecting to socket: " + path)

		parser: SplitParser {
			property var regex: new RegExp("focusedmon>>(.+),.*");

			onRead: msg => {
				const match = regex.exec(msg);
				if (match != null) {
					panel.screen = Quickshell.screens.filter(screen => screen.name == match[1])[0];
				}
			}
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

		Item {
			anchors.fill: parent

			// Left Group (Workspaces + Title)
			RowLayout {
				id: leftGroup
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				spacing: 8

				Workspaces { }
				Title { }
			}

			// MEDIA CARD
			Media {
				anchors.left: parent.left
				anchors.leftMargin: 380 
				anchors.verticalCenter: parent.verticalCenter
			}

			// Clock (Exact Center)
			Clock {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.verticalCenter: parent.verticalCenter
			}

			// Right Group
			RowLayout {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				spacing: 8

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

    // Listeners
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
