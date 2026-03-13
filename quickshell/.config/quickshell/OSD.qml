import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "theme"

PanelWindow {
    id: osd
    
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "osd"

    anchors {
        bottom: true
        left: true
        right: true
    }
    
    margins {
        bottom: 100
    }

    implicitHeight: 80
    color: "transparent"
    
    property string type: "volume"
    property real value: 0.0
    property string icon: "󰕾"
    property bool active: false
    property bool isMuted: false

    visible: active || pill.opacity > 0

    // Dynamic color based on type
    readonly property color accentColor: type === "brightness" ? Theme.yellow : Theme.mauve

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: osd.active = false
    }

    function show(newType, newVal, newIcon, muted = false) {
        osd.type = newType;
        osd.value = newVal;
        osd.icon = muted ? "󰝟" : newIcon;
        osd.isMuted = muted;
        osd.active = true;
        hideTimer.restart();
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: 250
        height: 60
        color: Theme.base
        radius: 20
        border.color: osd.isMuted ? Theme.red : Theme.borderColor
        border.width: 1
        
        opacity: osd.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Text {
                text: osd.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                color: osd.isMuted ? Theme.red : osd.accentColor
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.surface0

                Rectangle {
                    width: parent.width * osd.value
                    height: parent.height
                    radius: 3
                    color: osd.isMuted ? Theme.surface1 : osd.accentColor
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                text: osd.isMuted ? "Muted" : Math.round(osd.value * 100) + "%"
                color: osd.isMuted ? Theme.red : Theme.text
                font.family: Theme.fontName
                font.pixelSize: 14
                font.bold: true
                Layout.preferredWidth: 50
            }
        }
    }
}
