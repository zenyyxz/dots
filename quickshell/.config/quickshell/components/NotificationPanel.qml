import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-panel"
    WlrLayershell.keyboardFocus: WlrLayershell.None

    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 50
        right: 10
    }

    implicitWidth: 350
    implicitHeight: 500
    color: "transparent"

    property bool isOpen: false
    visible: isOpen || container.opacity > 0

    // Notification List Model
    property var notifications: []

    function addNotification(n) {
        notifications.push(n);
        notificationsChanged();
    }

    function removeNotification(index) {
        const n = notifications[index];
        if (n) n.dismiss();
        notifications.splice(index, 1);
        notificationsChanged();
    }

    function clearAll() {
        while (notifications.length > 0) {
            removeNotification(0);
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: Theme.base
        radius: 20
        border.color: Theme.borderColor
        border.width: 1
        clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        // Slide animation
        x: root.isOpen ? 0 : 50
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            // Header
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 18; font.bold: true
                }
                Item { Layout.fillWidth: true }
                
                // Clear All Button
                Rectangle {
                    width: 80; height: 28; radius: 8
                    color: Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Theme.subtext0
                        font.family: Theme.fontName; font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.clearAll()
                    }
                }
            }

            // Scrollable List
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                clip: true
                model: root.notifications
                delegate: Rectangle {
                    width: parent.width
                    height: 80; radius: 12
                    color: Theme.surface0
                    border.color: Theme.surface1
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Icon Placeholder (could be app icon)
                        Rectangle {
                            width: 40; height: 40; radius: 8
                            color: Theme.surface1
                            Text {
                                anchors.centerIn: parent
                                text: "󰵚"
                                font.family: "JetBrainsMono Nerd Font"
                                color: Theme.mauve
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.summary || "Notification"
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 14; font.bold: true
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.body || ""
                                color: Theme.subtext0
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                elide: Text.ElideRight; Layout.fillWidth: true; maximumLineCount: 2
                            }
                        }

                        // Close Button
                        Text {
                            text: "󰅖"
                            font.family: "JetBrainsMono Nerd Font"
                            color: Theme.surface2
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.removeNotification(index)
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "No Notifications"
                    color: Theme.surface2
                    visible: root.notifications.length === 0
                    font.family: Theme.fontName
                }
            }
        }
    }
}
