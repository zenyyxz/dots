import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<string> entries: []

    function refresh() {
        if (!readProc.running) {
            readProc.running = true;
        }
    }

    function copy(entry) {
        Quickshell.execDetached(["bash", "-c", `echo '${entry}' | cliphist decode | wl-copy`]);
    }

    function deleteEntry(entry) {
        Quickshell.execDetached(["bash", "-c", `echo '${entry}' | cliphist delete`]);
        // Small delay to ensure cliphist has updated its database
        refreshTimer.restart();
    }

    function wipe() {
        Quickshell.execDetached(["cliphist", "wipe"]);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 100
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: readProc
        command: ["cliphist", "list"]
        
        property list<string> buffer: []

        stdout: SplitParser {
            onRead: (line) => {
                readProc.buffer.push(line)
            }
        }

        onStarted: {
            buffer = []
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.entries = buffer
            }
        }
    }

    // Initial load
    Component.onCompleted: refresh()

    // Watch for clipboard changes. 
    // Note: cliphist usually has its own watcher daemon, 
    // but we refresh when Quickshell detects a change.
    Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            refreshTimer.restart()
        }
    }
}
