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
                property string subject: ""
                property var finishedCallback: null
                command: ["${bridgePath}", "get", subject]
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
        obj.subject = subjectName;
        obj.finishedCallback = callback;
    }

    function updateProgress(topicId, colIdx, value) {
        const valStr = value ? "true" : "false";
        const qml = `
            import Quickshell.Io
            Process {
                property string tId: ""
                property string cIdx: ""
                property string val: ""
                command: ["${bridgePath}", "update", tId, cIdx, val]
                running: true
                onExited: status => this.destroy()
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.tId = topicId.toString();
        obj.cIdx = colIdx.toString();
        obj.val = valStr;
    }

    function addTopic(subjectName, topicName, callback) {
        const qml = `
            import Quickshell.Io
            Process {
                property string subject: ""
                property string topic: ""
                property var finishedCallback: null
                command: ["${bridgePath}", "add", subject, topic]
                running: true
                onExited: status => {
                    if (status === 0 && finishedCallback) finishedCallback();
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.subject = subjectName;
        obj.topic = topicName;
        obj.finishedCallback = callback;
    }

    function renameTopic(topicId, newName) {
        const qml = `
            import Quickshell.Io
            Process {
                property string tId: ""
                property string name: ""
                command: ["${bridgePath}", "rename", tId, name]
                running: true
                onExited: status => this.destroy()
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.tId = topicId.toString();
        obj.name = newName;
    }
}
