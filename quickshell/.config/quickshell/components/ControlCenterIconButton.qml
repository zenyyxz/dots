import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: root
    property string icon: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    height: 60
    radius: 16
    
    color: active ? Theme.mauve : Theme.surface0
    Behavior on color { ColorAnimation { duration: 250 } }
    
    border.color: active ? "transparent" : Theme.surface1
    border.width: 1

    scale: mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }

    Item {
        anchors.centerIn: parent
        width: 24; height: 24

        // SVG Path logic
        Image {
            id: svgImg
            anchors.fill: parent
            source: (root.icon.endsWith(".svg") || root.icon.startsWith("/")) ? root.icon : ""
            visible: source != ""
            smooth: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(48, 48) // High resolution for sharp rendering
        }

        ColorOverlay {
            anchors.fill: svgImg
            source: svgImg
            color: root.active ? Theme.base : Theme.mauve
            visible: svgImg.visible
        }

        // Text icon fallback (if not an SVG path)
        Text {
            anchors.centerIn: parent
            text: root.icon
            visible: !svgImg.visible
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            color: root.active ? Theme.base : Theme.mauve
            Behavior on color { ColorAnimation { duration: 250 } }
        }
    }

    MouseArea { 
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked() 
    }
}
