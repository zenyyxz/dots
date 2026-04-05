import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: service

    readonly property string bridgePath: Quickshell.env("HOME") + "/dotfiles/quickshell/.config/quickshell/study-bridge/build/study-bridge"

    function getSubjectData(subjectName, callback) {
        const proc = Quickshell.createChildProcess({
            command: [bridgePath, "get", subjectName]
        });

        let output = "";
        proc.stdout.onRead.connect((msg) => output += msg);
        proc.onExited.connect((status) => {
            if (status === 0) {
                try {
                    callback(JSON.parse(output));
                } catch (e) {
                    console.error("Parse error:", e, output);
                }
            }
        });
        proc.running = true;
    }

    function updateProgress(topicId, colIdx, value) {
        const proc = Quickshell.createChildProcess({
            command: [bridgePath, "update", topicId.toString(), colIdx.toString(), value.toString()]
        });
        proc.running = true;
    }

    function addTopic(subjectName, topicName, callback) {
        const proc = Quickshell.createChildProcess({
            command: [bridgePath, "add", subjectName, topicName]
        });
        proc.onExited.connect((status) => {
            if (status === 0 && callback) callback();
        });
        proc.running = true;
    }
}
