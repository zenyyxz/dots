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
    WlrLayershell.namespace: "launcher"
    
    // Fill screen to allow centering and dimming
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
            searchField.forceActiveFocus();
            root.query = "";
            root.selectedIndex = 0;
            searchField.text = "";
        }
    }

    ScriptModel {
        id: filteredModel
        values: {
            const allApps = [...DesktopEntries.applications.values];
            const q = root.query.trim().toLowerCase();
            let results = allApps;
            if (q !== "") {
                results = allApps.filter(app => 
                    (app.name && app.name.toLowerCase().includes(q)) || 
                    (app.description && app.description.toLowerCase().includes(q))
                );
            }
            return results.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        }
    }

    // Subtle background dimming
    Rectangle {
        id: backgroundDim
        anchors.fill: parent
        color: "#000000"
        opacity: root.visible ? 0.3 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Centered Launcher Container
    Rectangle {
        id: container
        width: 450
        height: 550
        anchors.centerIn: parent
        color: Theme.base
        radius: 20
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        opacity: root.visible ? 1.0 : 0.0
        scale: root.visible ? 1.0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 15

            // --- Search Bar ---
            Rectangle {
                Layout.fillWidth: true
                height: 50
                color: Theme.surface0
                radius: 12
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
                        placeholderText: "Search apps..."
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
                                root.selectedIndex = Math.min(filteredModel.values.length - 1, root.selectedIndex + 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return) {
                                const selectedApp = filteredModel.values[root.selectedIndex];
                                if (selectedApp) {
                                    selectedApp.execute();
                                    root.visible = false;
                                }
                            }
                        }
                    }
                }
            }

            // --- App List ---
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: filteredModel.values
                spacing: 4
                clip: true
                currentIndex: root.selectedIndex
                
                onCurrentIndexChanged: {
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: Item {
                    width: appList.width
                    height: 50
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 8
                        color: root.selectedIndex === index ? Theme.surface0 : "transparent"
                        
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            spacing: 12
                            
                            Image {
                                width: 32; height: 32
                                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                source: Quickshell.iconPath(modelData.icon) || ""
                                sourceSize: Qt.size(48, 48)
                                
                                // Fallback icon if image fails to load
                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.status !== Image.Ready
                                    text: "󰀻"
                                    color: Theme.mauve
                                    font.pixelSize: 24
                                }
                            }
                            
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name || "App"
                                color: root.selectedIndex === index ? Theme.mauve : Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: {
                            modelData.execute();
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }
}
