import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
	Socket {
		// Create and connect a socket to the hyprland event socket
		path: `/tmp/hypr/${Quickshell.env["HYPRLAND_INSTANCE_SIGNATURE"]}/.socket2.sock`
		connected: true

		parser: SplitParser {
			// Regex that will return the newly focused monitor when it changes.
			property var regex: new RegExp("focusedmon>>(.+),.*");

			// Sent for every line read from the socket
			onRead: msg => {
				const match = regex.exec(msg);

				if (match != null) {
					// Filter out the right screen from the list and update the panel
					// match[1] will always be the monitor name captured by the regex
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

		height: 40

		color: "#1e1e2e" // Catppuccin Mocha Base

		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: 10
			anchors.rightMargin: 10

			// Left section (Workspaces - placeholder for now)
			Text {
				text: "Workspaces"
				color: "#cdd6f4"
				Layout.alignment: Qt.AlignLeft
			}

			// Spacer to push the clock to the center
			Item { Layout.fillWidth: true }

			// Center section (Clock)
			Text {
				id: clock
				property var date: new Date()
				color: "#cdd6f4"
				font.pixelSize: 16
				font.bold: true

				Timer {
					interval: 1000
					repeat: true
					running: true
					onTriggered: clock.date = new Date()
				}

				text: {
					const hours = clock.date.getHours().toString().padStart(2, '0');
					const minutes = clock.date.getMinutes().toString().padStart(2, '0');
					const seconds = clock.date.getSeconds().toString().padStart(2, '0');
					return `${hours}:${minutes}:${seconds}`;
				}
				Layout.alignment: Qt.AlignCenter
			}

			// Spacer to push the right section
			Item { Layout.fillWidth: true }

			// Right section (System info - placeholder)
			Text {
				text: "System Info"
				color: "#cdd6f4"
				Layout.alignment: Qt.AlignRight
			}
		}
	}
}