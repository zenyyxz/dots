import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: service

    readonly property string bridgePath: Quickshell.env("HOME") + "/dotfiles/quickshell/.config/quickshell/study-bridge/build/study-bridge"

    function getSubjectData(subjectName, callback) {
        const qml = `
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                command: ["${bridgePath}", "get", "${subjectName}"]
                running: true
                stdout: SplitParser {
                    property string output: ""
                    onRead: msg => output += msg
                }
                onExited: status => {
                    if (status === 0) {
                        try {
                            const data = JSON.parse(stdout.output);
                            if (finishedCallback) finishedCallback(data);
                        } catch (e) {
                            console.error("Parse error:", e);
                        }
                    }
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.finishedCallback = callback;
    }

    function updateProgress(topicId, colIdx, value) {
        const qml = `
            import Quickshell.Io
            Process {
                command: ["${bridgePath}", "update", "${topicId}", "${colIdx}", "${value}"]
                running: true
                onExited: status => this.destroy()
            }
        `;
        Qt.createQmlObject(qml, service, "dynamicProcess");
    }

    function addTopic(subjectName, topicName, callback) {
        const qml = `
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                command: ["${bridgePath}", "add", "${subjectName}", "${topicName}"]
                running: true
                onExited: status => {
                    if (status === 0 && finishedCallback) finishedCallback();
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.finishedCallback = callback;
    }

    function renameTopic(topicId, newName) {
        const qml = `
            import Quickshell.Io
            Process {
                command: ["${bridgePath}", "rename", "${topicId}", "${newName}"]
                running: true
                onExited: status => this.destroy()
            }
        `;
        Qt.createQmlObject(qml, service, "dynamicProcess");
    }
}
