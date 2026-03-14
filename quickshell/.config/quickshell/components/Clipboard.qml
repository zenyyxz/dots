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

    // Subtle background dimming with smooth fade
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Centered Container
    Rectangle {
        id: container
        width: 520
        height: 650
        anchors.centerIn: parent
        color: Theme.base
        radius: 28
        border.color: Theme.surface0
        border.width: 1
        clip: true

        opacity: root.visible ? 1.0 : 0.0
        scale: root.visible ? 1.0 : 0.98
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Rectangle {
                    width: 44; height: 44
                    radius: 12
                    color: Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        color: Theme.mauve
                    }
                }

                ColumnLayout {
                    spacing: -2
                    Text {
                        text: "Clipboard"
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: Cliphist.entries.length + " items in history"
                        color: Theme.surface2
                        font.family: Theme.fontName
                        font.pixelSize: 12
                    }
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
                            color: wipeButton.hovered ? Theme.red : Theme.surface2
                        }
                        Text {
                            text: "Clear"
                            color: wipeButton.hovered ? Theme.red : Theme.surface2
                            font.family: Theme.fontName
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                    
                    background: Rectangle {
                        radius: 10
                        color: wipeButton.hovered ? Theme.surface1 : "transparent"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            // --- Search Bar ---
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.mantle
                radius: 16
                border.color: searchField.activeFocus ? Theme.mauve : Theme.surface0
                border.width: 1
                
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18; anchors.rightMargin: 18
                    spacing: 14

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: Theme.mauve
                        opacity: searchField.activeFocus ? 1.0 : 0.6
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Search your history..."
                        placeholderTextColor: Theme.surface1
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
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    spacing: 10
                    clip: true
                    currentIndex: root.selectedIndex
                    
                    model: {
                        const q = root.query.trim().toLowerCase();
                        if (q === "") return Cliphist.entries;
                        return Cliphist.entries.filter(e => e.toLowerCase().includes(q));
                    }

                    delegate: Item {
                        width: listView.width
                        height: Cliphist.isImage(modelData) ? 220 : 72
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 16
                            color: root.selectedIndex === index ? Theme.surface1 : Theme.surface0
                            border.color: root.selectedIndex === index ? Theme.mauve : "transparent"
                            border.width: 1
                            
                            Behavior on color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 15
                                    
                                    Rectangle {
                                        width: 32; height: 32
                                        radius: 10
                                        color: root.selectedIndex === index ? Theme.base : Theme.mantle
                                        Text {
                                            anchors.centerIn: parent
                                            text: Cliphist.isImage(modelData) ? "󰋩" : "󰅍"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 16
                                            color: root.selectedIndex === index ? Theme.mauve : Theme.surface2
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.rightMargin: 40 // Make space for delete button
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: Cliphist.isImage(modelData) ? "Image Entry" : modelData.replace(/^\d+\s+/, "")
                                            color: root.selectedIndex === index ? Theme.text : Theme.subtext1
                                            font.family: Theme.fontName
                                            font.pixelSize: 14
                                            font.bold: root.selectedIndex === index
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

                                    // Spacer to keep the delete button aligned right
                                    Item { Layout.fillWidth: true }
                                }

                                Loader {
                                    active: Cliphist.isImage(modelData)
                                    visible: active
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 140
                                    sourceComponent: CliphistImage {
                                        entry: modelData
                                        maxWidth: container.width - 80 
                                        maxHeight: 140
                                    }
                                }
                            }
                        }

                        // Main item interaction
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: {
                                Cliphist.copy(modelData);
                                root.visible = false;
                            }
                        }

                        // Separate Delete Button with high priority
                        ToolButton {
                            id: delBtn
                            z: 10 
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 12
                            anchors.topMargin: 12
                            width: 36; height: 36
                            flat: true
                            hoverEnabled: true
                            onClicked: Cliphist.deleteEntry(modelData)
                            
                            contentItem: Item {
                                anchors.fill: parent
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: delBtn.hovered ? Theme.red : Theme.text
                                    opacity: delBtn.hovered ? 1.0 : 0.3
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }
                            
                            background: Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: delBtn.hovered ? Theme.surface2 : "transparent"
                                opacity: delBtn.hovered ? 0.4 : 0.0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                    }
                    
                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    add: Transition {
                        NumberAnimation { properties: "opacity,scale"; from: 0; to: 1; duration: 200 }
                    }
                    remove: Transition {
                        NumberAnimation { properties: "opacity,scale"; to: 0; duration: 200 }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
                    }
                }

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: listView.count === 0
                    spacing: 12
                    opacity: 0.5
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰅏"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 64
                        color: Theme.surface2
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.query === "" ? "History is empty" : "No results found"
                        color: Theme.text
                        font.family: Theme.fontName
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}
