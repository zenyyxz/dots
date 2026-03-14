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

    // Manual Notification Model for persistent history
    ListModel { id: notifModel }

    function addNotification(n) {
        // Insert at the top (newest first)
        // Store strings explicitly because complex objects can lose properties in ListModel
        notifModel.insert(0, { 
            "notifObject": n,
            "summaryText": n.summary || "Notification",
            "bodyText": n.body || ""
        });
    }

    function clearAll() {
        for (let i = 0; i < notifModel.count; i++) {
            const n = notifModel.get(i).notifObject;
            if (n) n.dismiss();
        }
        notifModel.clear();
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
                model: notifModel
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 80; radius: 12
                    color: Theme.surface0
                    border.color: Theme.surface1
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Icon Placeholder
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
                                text: model.summaryText
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 14; font.bold: true
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                text: model.bodyText
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
                                onClicked: {
                                    const n = notifModel.get(index).notifObject;
                                    if (n) n.dismiss();
                                    notifModel.remove(index);
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "No Notifications"
                    color: Theme.surface2
                    visible: notifModel.count === 0
                    font.family: Theme.fontName
                }
            }
        }
    }
}
