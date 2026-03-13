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
			top: 10
			left: 10
			right: 10
		}

		implicitHeight: 48
		color: "transparent"

		Item {
			anchors.fill: parent

			Workspaces {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
			}

			Clock {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.verticalCenter: parent.verticalCenter
			}

			SysInfo {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}
}