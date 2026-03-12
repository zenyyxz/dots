import QtQuick
import Quickshell.Io
import Quickshell

PanelWindow {
	anchors{
		top: true
		left: true
		right: true
	}

	implicitHeight: 30

	Text {
		id: clock
		anchors.centerIn: parent

		Process {
			// give the process object an id so we can talk abuot it from the timer
			id: dateProc

			command: ["date"]
			running: true

			stdout: StdioCollector {
				onStreamFinished: clock.text = this.text
			}
		}

		Timer {
			// 1000 milliseconds = 1 second
			interval: 1000
			running: true
			repeat: true

			//when the timer is triggered, set the running property of the process to true, which returns if it stopped.
			
			onTriggered: dateProc.running = true
		}
	}

}