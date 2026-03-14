import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-popup"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 60
        right: 10
    }

    implicitWidth: 350
    implicitHeight: 100
    color: "transparent"

    property string summary: ""
    property string body: ""
    property bool active: false

    visible: active || container.opacity > 0

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: root.active = false
    }

    function show(n) {
        summary = n.summary || "Notification";
        body = n.body || "";
        active = true;
        hideTimer.restart();
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 16
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.active ? 1.0 : 0.0
        
        // Slide & Fade Animation
        x: root.active ? 0 : 20
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // Icon
            Rectangle {
                width: 45; height: 45; radius: 10
                color: Theme.surface0
                Text {
                    anchors.centerIn: parent
                    text: "󰵚"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    color: Theme.mauve
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.summary
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 15; font.bold: true
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
                Text {
                    text: root.body
                    color: Theme.subtext0
                    font.family: Theme.fontName
                    font.pixelSize: 13
                    elide: Text.ElideRight; Layout.fillWidth: true; maximumLineCount: 2
                }
            }

            // Dismiss Button
            MouseArea {
                Layout.preferredWidth: 20; Layout.preferredHeight: 20
                onClicked: root.active = false
                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "JetBrainsMono Nerd Font"
                    color: Theme.surface2
                }
            }
        }
    }
}
