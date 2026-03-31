import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "chatwidget"
    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    onIsOpenChanged: {
        if (isOpen) {
            inputField.forceActiveFocus();
        }
    }

    // Background dimming
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.isOpen ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    ListModel {
        id: chatModel
    }

    property string currentInput: ""
    property bool isThinking: false

    Process {
        id: llmProcess
        command: ["bash", Quickshell.shellPath("mock_llm.sh"), root.currentInput]
        running: false
        
        stdout: SplitParser {
            onRead: msg => {
                const txt = msg.trim();
                if (txt !== "") {
                    // Check if last message is AI. If so, append to it, else create new one.
                    if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).role === "ai") {
                        let currentText = chatModel.get(chatModel.count - 1).text;
                        chatModel.setProperty(chatModel.count - 1, "text", currentText + "\n" + txt);
                    } else {
                        chatModel.append({ role: "ai", text: txt });
                    }
                }
            }
        }
        
        onExited: {
            root.isThinking = false;
        }
    }

    Rectangle {
        id: container
        width: 450
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: 60
            bottomMargin: 15
        }
        
        x: root.isOpen ? 15 : -width - 20
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

        color: Theme.base
        radius: 16
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    width: 40; height: 40
                    radius: 10
                    color: Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: "󰚩"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Theme.mauve
                    }
                }

                Text {
                    text: "Jarvis Local"
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 20
                    font.bold: true
                }
                
                Item { Layout.fillWidth: true }
                
                // Clear chat button
                Rectangle {
                    width: 30; height: 30
                    radius: 8
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "󰃢"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Theme.red
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: chatModel.clear()
                    }
                }
            }
            
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface0 }

            // Chat ListView
            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: chatModel
                spacing: 12
                clip: true

                onCountChanged: {
                    chatList.positionViewAtEnd();
                }

                delegate: Item {
                    width: chatList.width
                    implicitHeight: messageBubble.height + 10
                    
                    RowLayout {
                        width: parent.width
                        layoutDirection: model.role === "user" ? Qt.RightToLeft : Qt.LeftToRight
                        
                        Rectangle {
                            id: messageBubble
                            color: model.role === "user" ? Theme.mauve : Theme.surface0
                            radius: 12
                            Layout.maximumWidth: chatList.width * 0.8
                            Layout.minimumWidth: msgText.paintedWidth + 24
                            implicitHeight: msgText.paintedHeight + 20
                            
                            Text {
                                id: msgText
                                anchors.fill: parent
                                anchors.margins: 10
                                text: model.text
                                color: model.role === "user" ? Theme.crust : Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 14
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
            
            // "Thinking" indicator
            Text {
                text: "Thinking..."
                color: Theme.subtext0
                font.family: Theme.fontName
                font.pixelSize: 12
                visible: root.isThinking
                Layout.alignment: Qt.AlignLeft
            }

            // Input Area
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: Theme.surface0
                radius: 14
                border.color: inputField.activeFocus ? Theme.mauve : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    TextField {
                        id: inputField
                        Layout.fillWidth: true
                        placeholderText: "Message AI..."
                        placeholderTextColor: Theme.surface2
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 15
                        background: null
                        
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                root.isOpen = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (text.trim() !== "" && !root.isThinking) {
                                    chatModel.append({ role: "user", text: text.trim() });
                                    root.currentInput = text.trim();
                                    text = "";
                                    root.isThinking = true;
                                    llmProcess.running = true;
                                }
                                event.accepted = true;
                            }
                        }
                    }
                    
                    Text {
                        text: "󰒍"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: (inputField.text.trim() !== "" && !root.isThinking) ? Theme.mauve : Theme.surface2
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (inputField.text.trim() !== "" && !root.isThinking) {
                                    chatModel.append({ role: "user", text: inputField.text.trim() });
                                    root.currentInput = inputField.text.trim();
                                    inputField.text = "";
                                    root.isThinking = true;
                                    llmProcess.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
