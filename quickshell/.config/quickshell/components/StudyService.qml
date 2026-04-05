import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: service

    readonly property string bridgePath: Quickshell.env("HOME") + "/dotfiles/quickshell/.config/quickshell/study-bridge/build/study-bridge"

    function getSubjectData(subjectName, callback) {
        logToFile(`[StudyService] Fetching Data for: ${subjectName}`);
        const qml = `
            import Quickshell
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                running: false
                command: ["${bridgePath}", "get", "${subjectName}"]
                
                function logToFile(msg) {
                    const timestamp = new Date().toISOString();
                    const fullMsg = \`[\${timestamp}] \${msg}\`;
                    Quickshell.execDetached(["bash", "-c", \`echo '\${fullMsg}' >> /tmp/quickshell_study.log\`]);
                }

                stdout: SplitParser {
                    property string output: ""
                    onRead: msg => output += msg
                }
                stderr: SplitParser {
                    onRead: msg => logToFile("[Bridge STDERR (get)]: " + msg.trim())
                }
                onExited: status => {
                    if (status === 0) {
                        try {
                            const data = JSON.parse(stdout.output);
                            if (finishedCallback) finishedCallback(data);
                        } catch (e) {
                            logToFile("Parse error: " + e);
                        }
                    } else {
                        logToFile("[StudyService] getSubjectData failed with status: " + status);
                    }
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.finishedCallback = callback;
        obj.running = true;
    }

    function logToFile(msg) {
        const timestamp = new Date().toISOString();
        const fullMsg = `[${timestamp}] ${msg}`;
        Quickshell.execDetached(["bash", "-c", `echo '${fullMsg}' >> /tmp/quickshell_study.log`]);
    }

    function updateProgress(topicId, colIdx, value, callback) {
        const valStr = value ? "true" : "false";
        logToFile(`[StudyService] Updating Topic:${topicId} Col:${colIdx} Val:${valStr}`);
        
        const qml = `
            import Quickshell
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                property string tId: ""
                property string cIdx: ""
                property string vStr: ""
                running: false
                command: ["${bridgePath}", "update", tId, cIdx, vStr]
                
                function logToFile(msg) {
                    const timestamp = new Date().toISOString();
                    const fullMsg = \`[\${timestamp}] \${msg}\`;
                    Quickshell.execDetached(["bash", "-c", \`echo '\${fullMsg}' >> /tmp/quickshell_study.log\`]);
                }

                stdout: SplitParser {
                    onRead: msg => logToFile("[Bridge STDOUT]: " + msg.trim())
                }
                stderr: SplitParser {
                    onRead: msg => logToFile("[Bridge STDERR]: " + msg.trim())
                }
                
                onExited: status => {
                    logToFile("[StudyService] Process exited with status: " + status);
                    if (status === 0 && finishedCallback) finishedCallback();
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.tId = topicId.toString();
        obj.cIdx = colIdx.toString();
        obj.vStr = valStr;
        obj.finishedCallback = callback;
        obj.running = true;
    }

    function addTopic(subjectName, topicName, callback) {
        const qml = `
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                running: false
                command: ["${bridgePath}", "add", "${subjectName}", "${topicName}"]
                stderr: SplitParser {
                    onRead: msg => console.error("Bridge Error (addTopic):", msg.trim())
                }
                onExited: status => {
                    if (status === 0 && finishedCallback) finishedCallback();
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.finishedCallback = callback;
        obj.running = true;
    }

    function renameTopic(topicId, newName) {
        const qml = `
            import Quickshell.Io
            Process {
                running: false
                command: ["${bridgePath}", "rename", "${topicId}", "${newName}"]
                stderr: SplitParser {
                    onRead: msg => console.error("Bridge Error (renameTopic):", msg.trim())
                }
                onExited: status => this.destroy()
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.running = true;
    }

    function deleteTopic(topicId, callback) {
        const qml = `
            import Quickshell.Io
            Process {
                property var finishedCallback: null
                running: false
                command: ["${bridgePath}", "delete", "${topicId}"]
                stderr: SplitParser {
                    onRead: msg => console.error("Bridge Error (deleteTopic):", msg.trim())
                }
                onExited: status => {
                    if (status === 0 && finishedCallback) finishedCallback();
                    this.destroy();
                }
            }
        `;
        const obj = Qt.createQmlObject(qml, service, "dynamicProcess");
        obj.finishedCallback = callback;
        obj.running = true;
    }
}
