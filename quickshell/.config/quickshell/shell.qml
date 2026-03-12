import QtQuick
import Quickshell
import Quickshell.Hyprland // The secret sauce

ShellRoot {
	Variants {
		// This creates a window on every connected monitor
		model: Quickshell.screens

		PanelWindow {
			anchors.top: true
			anchors.left: true
			anchors.right: true
			height: 40
			color: "#1a1b26" // Tokyo Night Background

			Text {
				anchors.centerIn: parent
				text: "Welcome to my new arch build"
				color: "white"
			}
		}
	}
}
