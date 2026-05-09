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
        opacity: root.isOpen ? 0.3 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    ListModel {
        id: chatModel
        // Example: { role: "user" | "ai", text: "...", timestamp: "..." }
    }

    property string currentInput: ""
    property bool isThinking: false

    Process {
        id: llmProcess
        command: ["bash", Quickshell.shellPath("../llm_query.sh"), root.currentInput]
        running: false
        
        stdout: SplitParser {
            onRead: msg => {
                const txt = msg.trim();
                if (txt !== "") {
                    if (chatModel.count > 0 && chatModel.get(chatModel.count - 1).role === "ai") {
                        let currentText = chatModel.get(chatModel.count - 1).text;
                        chatModel.setProperty(chatModel.count - 1, "text", currentText + "\n" + txt);
                    } else {
                        chatModel.append({ 
                            role: "ai", 
                            text: txt,
                            timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                        });
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
        width: 500
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: 12
            bottomMargin: 12
        }
        
        // Slide from left
        x: root.isOpen ? 12 : -width - 40
        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }

        color: Theme.base
        radius: 20
        border.color: Theme.surface0
        border.width: 1
        clip: true

        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        // Subtle gradient background
        Rectangle {
            anchors.fill: parent
            radius: 20
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.03) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                height: 70
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 16

                    Rectangle {
                        width: 44; height: 44
                        radius: 12
                        color: Theme.surface0
                        Text {
                            anchors.centerIn: parent
                            text: "󱚝" // AI Sparkle icon
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            color: Theme.mauve
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "Zenyyxz Intelligence"
                            color: Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 18
                            font.bold: true
                        }
                        Text {
                            text: root.isThinking ? "Thinking..." : "Ready to assist"
                            color: root.isThinking ? Theme.mauve : Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 12
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Action Buttons
                    RowLayout {
                        spacing: 8
                        
                        // Clear Button
                        Button {
                            id: clearBtn
                            implicitWidth: 36; implicitHeight: 36
                            background: Rectangle {
                                radius: 10
                                color: clearBtn.hovered ? Theme.surface0 : "transparent"
                            }
                            contentItem: Text {
                                text: "󰃢"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: clearBtn.hovered ? Theme.red : Theme.subtext1
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: chatModel.clear()
                        }
                        
                        // Close Button
                        Button {
                            id: closeBtn
                            implicitWidth: 36; implicitHeight: 36
                            background: Rectangle {
                                radius: 10
                                color: closeBtn.hovered ? Theme.surface0 : "transparent"
                            }
                            contentItem: Text {
                                text: "󰅖"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: closeBtn.hovered ? Theme.text : Theme.subtext1
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: root.isOpen = false
                        }
                    }
                }
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: Theme.surface0
                    opacity: 0.5
                }
            }

            // Message List
            ListView {
                id: chatList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: chatModel
                spacing: 20
                clip: true
                topMargin: 20
                bottomMargin: 20
                leftMargin: 20
                rightMargin: 20

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.surface1
                    }
                }

                onCountChanged: {
                    chatList.positionViewAtEnd();
                }

                delegate: ColumnLayout {
                    width: chatList.width - 40
                    spacing: 6
                    
                    property bool isUser: model.role === "user"

                    RowLayout {
                        Layout.fillWidth: true
                        layoutDirection: isUser ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: 10

                        // Avatar/Icon
                        Rectangle {
                            width: 28; height: 28
                            radius: 8
                            color: isUser ? Theme.surface1 : Theme.mauve
                            Text {
                                anchors.centerIn: parent
                                text: isUser ? "󰀉" : "󱚝"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: isUser ? Theme.text : Theme.crust
                            }
                        }

                        Text {
                            text: isUser ? "You" : "Assistant"
                            color: Theme.subtext1
                            font.family: Theme.fontName
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: model.timestamp
                            color: Theme.surface2
                            font.family: Theme.fontName
                            font.pixelSize: 10
                        }
                        
                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.alignment: isUser ? Qt.AlignRight : Qt.AlignLeft
                        Layout.maximumWidth: parent.width * 0.9
                        implicitWidth: isUser ? (msgText.paintedWidth + 32) : chatList.width - 40
                        implicitHeight: isUser ? (msgText.paintedHeight + 24) : (aiText.paintedHeight + 24)
                        radius: 16
                        color: isUser ? Theme.surface0 : Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.5)
                        border.color: isUser ? Theme.surface1 : "transparent"
                        
                        TextEdit {
                            id: msgText
                            visible: isUser
                            anchors.fill: parent
                            anchors.margins: 12
                            text: model.text
                            color: Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true
                            selectionColor: Theme.mauve
                            selectedTextColor: Theme.crust
                        }

                        Text {
                            id: aiText
                            visible: !isUser
                            anchors.fill: parent
                            anchors.margins: 12
                            text: model.text
                            color: Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                            textFormat: Text.MarkdownText
                        }
                    }
                }
            }
            
            // Input Area
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 100
                color: "transparent"
                
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width; height: 1
                    color: Theme.surface0
                    opacity: 0.5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Theme.surface0
                        radius: 12
                        border.color: inputField.activeFocus ? Theme.mauve : Theme.surface1
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 8

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                                
                                TextArea {
                                    id: inputField
                                    placeholderText: "Ask anything..."
                                    placeholderTextColor: Theme.surface2
                                    color: Theme.text
                                    font.family: Theme.fontName
                                    font.pixelSize: 14
                                    wrapMode: Text.EditWrap
                                    background: null
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                            if (text.trim() !== "" && !root.isThinking) {
                                                const msg = text.trim();
                                                chatModel.append({ 
                                                    role: "user", 
                                                    text: msg,
                                                    timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                                                });
                                                root.currentInput = msg;
                                                text = "";
                                                root.isThinking = true;
                                                llmProcess.running = true;
                                            }
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                id: sendBtn
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 6
                                implicitWidth: 32; implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: 8
                                    color: (inputField.text.trim() !== "" && !root.isThinking) ? Theme.mauve : "transparent"
                                    opacity: sendBtn.hovered ? 1.0 : 0.8
                                }
                                
                                contentItem: Text {
                                    text: "󰒍"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: (inputField.text.trim() !== "" && !root.isThinking) ? Theme.crust : Theme.surface2
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    if (inputField.text.trim() !== "" && !root.isThinking) {
                                        const msg = inputField.text.trim();
                                        chatModel.append({ 
                                            role: "user", 
                                            text: msg,
                                            timestamp: new Date().toLocaleTimeString(Qt.locale(), "HH:mm")
                                        });
                                        root.currentInput = msg;
                                        inputField.text = "";
                                        root.isThinking = true;
                                        llmProcess.running = true;
                                    }
                                }
                            }
                        }
                    }
                    
                    Text {
                        text: "Shift + Enter for new line"
                        color: Theme.surface2
                        font.family: Theme.fontName
                        font.pixelSize: 9
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }
        }
    }
}

