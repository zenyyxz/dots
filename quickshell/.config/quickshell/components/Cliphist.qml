pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property list<string> entries: []

    function isImage(entry) {
        return !!(entry.match(/\[\[.*binary data.*\d+x\d+.*\]\]/));
    }

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

    property Timer refreshTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: root.refresh()
    }

    property Process readProc: Process {
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
                root.entries = readProc.buffer
            }
        }
    }

    // Initial load
    Component.onCompleted: {
        refresh();
        // Start the watcher if it's not already running
        Quickshell.execDetached(["bash", "-c", "pgrep -x wl-paste > /dev/null || wl-paste --watch cliphist store"]);
    }

    // Watch for clipboard changes. 
    property Connections clipboardWatcher: Connections {
        target: Quickshell
        function onClipboardTextChanged() {
            refreshTimer.restart()
        }
    }
}
