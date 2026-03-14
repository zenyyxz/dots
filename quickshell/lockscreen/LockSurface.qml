import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Wayland
import "../.config/quickshell/theme"

Rectangle {
    id: root
    required property LockContext context
    
    color: Theme.crust

    // Background Image or Gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.crust }
            GradientStop { position: 1.0; color: Theme.base }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 40

        // Clock
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            
            Label {
                id: clock
                property var date: new Date()
                Layout.alignment: Qt.AlignHCenter

                renderType: Text.NativeRendering
                font.family: Theme.fontName
                font.pointSize: 80
                font.bold: true
                color: Theme.mauve

                Timer {
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: clock.date = new Date()
                }

                text: {
                    const hours = this.date.getHours().toString().padStart(2, '0');
                    const minutes = this.date.getMinutes().toString().padStart(2, '0');
                    return `${hours}:${minutes}`;
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })
                font.family: Theme.fontName
                font.pointSize: 18
                color: Theme.subtext0
            }
        }

        // Input Field
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15

            Rectangle {
                implicitWidth: 320
                implicitHeight: 50
                color: Theme.surface0
                radius: 12
                border.color: root.context.showFailure ? Theme.red : Theme.surface1
                border.width: 1

                TextField {
                    id: passwordBox
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    
                    background: null
                    focus: true
                    enabled: !root.context.unlockInProgress
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pointSize: 14
                    
                    placeholderText: "Enter Password..."
                    placeholderTextColor: Theme.surface2

                    onTextChanged: root.context.currentText = this.text;
                    onAccepted: root.context.tryUnlock();

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText;
                        }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.context.showFailure
                text: "Authentication Failed"
                color: Theme.red
                font.family: Theme.fontName
                font.pointSize: 12
            }
        }
    }

    // Emergency Exit (for dev/debugging)
    Button {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        text: "Emergency Unlock"
        flat: true
        contentItem: Text {
            text: parent.text
            color: Theme.surface2
            font.family: Theme.fontName
            horizontalAlignment: Text.AlignHCenter
        }
        onClicked: context.unlocked();
        opacity: 0.5
    }
}