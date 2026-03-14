import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "clipboard"
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.keyboardFocus: visible ? WlrLayershell.OnDemand : WlrLayershell.None
    color: "transparent"

    property string query: ""
    property int selectedIndex: 0

    onVisibleChanged: {
        if (visible) {
            Cliphist.refresh();
            searchField.forceActiveFocus();
            root.query = "";
            root.selectedIndex = 0;
            searchField.text = "";
        }
    }

    // Subtle background dimming
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.3 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Centered Container
    Rectangle {
        id: container
        width: 500
        height: 600
        anchors.centerIn: parent
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        opacity: root.visible ? 1.0 : 0.0
        scale: root.visible ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                Rectangle {
                    width: 40; height: 40
                    radius: 10
                    color: Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Theme.mauve
                    }
                }

                Text {
                    text: "Clipboard"
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 22
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    id: wipeButton
                    flat: true
                    onClicked: Cliphist.wipe()
                    
                    contentItem: RowLayout {
                        spacing: 8
                        Text {
                            text: "󰆴"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: wipeButton.hovered ? Theme.red : Theme.subtext0
                        }
                        Text {
                            text: "Clear All"
                            color: wipeButton.hovered ? Theme.red : Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 14
                        }
                    }
                    
                    background: Rectangle {
                        radius: 8
                        color: wipeButton.hovered ? Theme.surface1 : "transparent"
                    }
                }
            }

            // --- Search Bar ---
            Rectangle {
                Layout.fillWidth: true
                height: 54
                color: Theme.surface0
                radius: 14
                border.color: searchField.activeFocus ? Theme.mauve : "transparent"
                border.width: 1
                
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15; anchors.rightMargin: 15
                    spacing: 12

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Theme.mauve
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search your history..."
                        placeholderTextColor: Theme.surface2
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 16
                        background: null
                        
                        onTextChanged: { 
                            root.query = text; 
                            root.selectedIndex = 0;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                root.visible = false;
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(listView.count - 1, root.selectedIndex + 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return) {
                                const entries = listView.model;
                                if (entries && entries.length > 0) {
                                    Cliphist.copy(entries[root.selectedIndex]);
                                    root.visible = false;
                                }
                            }
                        }
                    }
                }
            }

            // --- History List ---
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                currentIndex: root.selectedIndex
                
                model: {
                    const q = root.query.trim().toLowerCase();
                    if (q === "") return Cliphist.entries;
                    return Cliphist.entries.filter(e => e.toLowerCase().includes(q));
                }

                delegate: Item {
                    width: listView.width
                    height: 64
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: root.selectedIndex === index ? Theme.surface1 : Theme.surface0
                        border.color: root.selectedIndex === index ? Theme.mauve : "transparent"
                        border.width: 1
                        
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 12
                            spacing: 15
                            
                            Rectangle {
                                width: 32; height: 32
                                radius: 8
                                color: Theme.base
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅍"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: root.selectedIndex === index ? Theme.mauve : Theme.subtext0
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.replace(/^\d+\s+/, "")
                                    color: root.selectedIndex === index ? Theme.text : Theme.subtext1
                                    font.family: Theme.fontName
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                Text {
                                    text: "Entry #" + modelData.split(/\s+/)[0]
                                    color: Theme.surface2
                                    font.family: Theme.fontName
                                    font.pixelSize: 11
                                }
                            }

                            ToolButton {
                                id: delBtn
                                flat: true
                                onClicked: Cliphist.deleteEntry(modelData)
                                contentItem: Text {
                                    text: "󰆴"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: delBtn.hovered ? Theme.red : Theme.surface2
                                }
                                background: null
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: {
                            Cliphist.copy(modelData);
                            root.visible = false;
                        }
                    }
                }
                
                onCurrentIndexChanged: {
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }
            }
        }
    }
}
