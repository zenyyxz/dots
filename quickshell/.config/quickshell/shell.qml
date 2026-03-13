import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "theme"
import "components"

ShellRoot {
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

			// MEDIA CARD: Fixed width and fixed position relative to the left
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

    // On-Screen Display
    OSD {
        id: globalOSD
    }

    // Volume Listener
    Process {
        command: ["bash", "-c", "pactl subscribe | grep --line-buffered \"change\""]
        running: true
        stdout: SplitParser {
            onRead: {
                volumeUpdateProc.running = true
            }
        }
    }

    Process {
        id: volumeUpdateProc
        command: ["bash", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -n 1"]
        stdout: SplitParser {
            onRead: msg => {
                const vol = parseInt(msg.trim()) / 100.0;
                if (!isNaN(vol)) {
                    globalOSD.show("volume", vol, "󰕾");
                }
            }
        }
    }

    // Brightness Listener
    property real lastBrightness: 0
    Process {
        id: brightPercentProc
        command: ["bash", "-c", "brightnessctl m && brightnessctl g"]
        stdout: SplitParser {
            property int max: 0
            onRead: (msg, index) => {
                if (index == 0) {
                    max = parseInt(msg);
                } else if (index == 1) {
                    const cur = parseInt(msg);
                    const percent = cur / max;
                    if (Math.abs(percent - lastBrightness) > 0.005) {
                        globalOSD.show("brightness", percent, "󰃠");
                        lastBrightness = percent;
                    }
                }
            }
        }
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: brightPercentProc.running = true
    }
}
