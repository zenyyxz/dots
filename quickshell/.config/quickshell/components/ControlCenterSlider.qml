import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

RowLayout {
    id: root
    property string icon: ""
    property real value: 0.0
    property color color: Theme.mauve
    signal moved(real val)
    signal pressed()
    signal released()

    spacing: 15

    Rectangle {
        width: 45; height: 45; radius: 12
        color: Theme.surface0
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
            color: root.color
        }
    }

    Slider {
        Layout.fillWidth: true
        from: 0; to: 1.0; value: root.value
        onMoved: root.moved(value)
        onPressedChanged: {
            if (pressed) root.pressed();
            else root.released();
        }

        background: Rectangle {
            x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
            implicitWidth: 200; implicitHeight: 6; width: parent.availableWidth; height: implicitHeight
            radius: 3; color: Theme.surface0
            Rectangle {
                width: parent.visualPosition * parent.width; height: parent.height
                color: root.color; radius: 3
            }
        }

        handle: Rectangle {
            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width); y: parent.topPadding + parent.availableHeight / 2 - height / 2
            implicitWidth: 16; implicitHeight: 16; radius: 8
            color: Theme.text; border.color: root.color; border.width: 2
        }
    }
}
