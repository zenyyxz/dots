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
    WlrLayershell.namespace: "vpn-config"
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
    
    property bool addingProfile: false
    property string activeProfile: ""
    property string statusMessage: ""
    property bool isError: false

    ListModel { id: profilesModel }

    // --- Backend Processes ---
    
    Process {
        id: listProfilesProc
        command: ["bash", "/home/zenyyxz/dotfiles/vpn/sing-box/manage_profiles.sh", "list"]
        stdout: SplitParser {
            onRead: (line) => {
                const name = line.trim();
                if (name !== "") profilesModel.append({ "name": name });
            }
        }
        onStarted: {
            profilesModel.clear();
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                activeProfileProc.running = false;
                activeProfileProc.running = true;
            }
        }
    }

    Process {
        id: activeProfileProc
        command: ["bash", "/home/zenyyxz/dotfiles/vpn/sing-box/manage_profiles.sh", "active"]
        stdout: SplitParser {
            onRead: (line) => {
                root.activeProfile = line.trim();
            }
        }
        onStarted: {
            root.activeProfile = "";
        }
    }

    Process {
        id: addProfileProc
        onExited: (code) => {
            if (code === 0) {
                root.statusMessage = "Success: Profile added!";
                profileInput.text = "";
                listProfilesProc.running = false; 
                listProfilesProc.running = true; 
            } else {
                root.statusMessage = "Error: Failed to add profile.";
                root.isError = true;
            }
        }
    }

    Process {
        id: applyProfileProc
        onExited: (code) => {
            if (code === 0) {
                activeProfileProc.running = false;
                activeProfileProc.running = true;
            } else {
                root.statusMessage = "Error: Failed to apply profile.";
                root.isError = true;
            }
        }
    }

    Process {
        id: deleteProfileProc
        onExited: (code) => {
            if (code === 0) {
                listProfilesProc.running = false;
                listProfilesProc.running = true;
            }
        }
    }

    // --- Functions ---

    function addProfile(content) {
        if (content.trim() === "") return;
        root.statusMessage = "Adding profile...";
        root.isError = false;
        addProfileProc.running = false;
        addProfileProc.command = ["bash", "/home/zenyyxz/dotfiles/vpn/sing-box/manage_profiles.sh", "add", content.trim()];
        addProfileProc.running = true;
    }

    function applyProfile(name) {
        root.statusMessage = "Applying " + name + "...";
        root.isError = false;
        applyProfileProc.running = false;
        applyProfileProc.command = ["bash", "/home/zenyyxz/dotfiles/vpn/sing-box/manage_profiles.sh", "apply", name];
        applyProfileProc.running = true;
        root.activeProfile = name;
        root.statusMessage = "Success: Applied " + name;
    }

    function deleteProfile(name) {
        root.statusMessage = "Deleting " + name + "...";
        deleteProfileProc.running = false;
        deleteProfileProc.command = ["bash", "/home/zenyyxz/dotfiles/vpn/sing-box/manage_profiles.sh", "delete", name];
        deleteProfileProc.running = true;
    }

    onIsOpenChanged: {
        if (isOpen) {
            listProfilesProc.running = false;
            listProfilesProc.running = true;
            root.addingProfile = false; // Always start on List View
            root.statusMessage = "";
        }
    }

    // --- UI ---
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.isOpen ? 0.4 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        MouseArea { anchors.fill: parent; onClicked: root.isOpen = false }
    }

    Rectangle {
        id: container
        width: 380
        height: root.addingProfile ? 450 : 400
        anchors.centerIn: parent
        color: Theme.base
        radius: 24
        border.color: Theme.borderColor; border.width: 1; clip: true
        
        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        MouseArea { anchors.fill: parent; onClicked: (mouse) => { mouse.accepted = true; } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25; spacing: 15

            // Header
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Rectangle {
                    width: 36; height: 36; radius: 10; color: Theme.surface0
                    Text { anchors.centerIn: parent; text: "󰖂"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: Theme.mauve }
                }
                Text { text: "VPN Manager"; color: Theme.text; font.family: Theme.fontName; font.pixelSize: 16; font.bold: true }
                Item { Layout.fillWidth: true }
                
                // Toggle Add View Button
                Rectangle {
                    width: 32; height: 32; radius: 8; color: root.addingProfile ? Theme.mauve : Theme.surface0
                    Text { 
                        anchors.centerIn: parent; 
                        text: root.addingProfile ? "󰅖" : "󰐕"; 
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; 
                        color: root.addingProfile ? Theme.base : Theme.text 
                    }
                    MouseArea { 
                        anchors.fill: parent; 
                        onClicked: {
                            root.addingProfile = !root.addingProfile;
                            root.statusMessage = "";
                        }
                    }
                }
            }

            // --- Views Stack ---
            StackLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: root.addingProfile ? 1 : 0

                // List View
                ColumnLayout {
                    spacing: 12
                    ListView {
                        id: profilesList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        model: profilesModel; spacing: 8; clip: true
                        
                        delegate: Rectangle {
                            width: profilesList.width; height: 50; radius: 12
                            color: (root.activeProfile === model.name) ? Theme.surface1 : Theme.surface0
                            border.color: (root.activeProfile === model.name) ? Theme.mauve : "transparent"; border.width: 1

                            // Apply profile MouseArea
                            MouseArea { 
                                anchors.fill: parent
                                onClicked: root.applyProfile(model.name) 
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 10
                                Text {
                                    text: model.name; color: (root.activeProfile === model.name) ? Theme.mauve : Theme.text
                                    font.family: Theme.fontName; font.pixelSize: 13; font.bold: (root.activeProfile === model.name)
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                
                                // Delete Icon
                                Rectangle {
                                    id: deleteBtn
                                    width: 28; height: 28; radius: 8
                                    color: deleteMouseArea.containsMouse ? Theme.surface1 : "transparent"
                                    
                                    Text {
                                        anchors.centerIn: parent; text: "󰅖"; 
                                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; 
                                        color: deleteMouseArea.containsMouse ? Theme.red : Theme.surface2
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    MouseArea { 
                                        id: deleteMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: (mouse) => {
                                            root.deleteProfile(model.name);
                                            mouse.accepted = true; // Prevent event propagation
                                        }
                                    }
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                    
                    Text {
                        text: profilesModel.count === 0 ? "No profiles saved." : "Tap a profile to connect"
                        color: Theme.subtext1; font.family: Theme.fontName; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Add View
                ColumnLayout {
                    spacing: 15
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Theme.mantle; radius: 14; border.color: Theme.surface1; border.width: 1
                        ScrollView {
                            anchors.fill: parent; anchors.margins: 12; clip: true
                            TextArea {
                                id: profileInput; placeholderText: "Paste VLESS link or JSON content here..."; placeholderTextColor: Theme.surface2
                                color: Theme.text; font.family: "JetBrains Mono"; font.pixelSize: 12; wrapMode: Text.Wrap; background: null
                                selectByMouse: true
                            }
                        }
                    }
                    Button {
                        Layout.fillWidth: true; Layout.preferredHeight: 44
                        contentItem: Text { text: "Add Profile"; color: Theme.base; font.family: Theme.fontName; font.pixelSize: 14; font.bold: true; horizontalAlignment: Text.AlignHCenter }
                        background: Rectangle { color: Theme.mauve; radius: 12 }
                        onClicked: root.addProfile(profileInput.text)
                    }
                }
            }
            
            // Footer Status
            Rectangle {
                Layout.fillWidth: true; height: 30; color: "transparent"
                visible: root.statusMessage !== ""
                Text {
                    anchors.centerIn: parent; text: root.statusMessage; color: root.isError ? Theme.red : Theme.green
                    font.family: Theme.fontName; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
        }
    }
}
