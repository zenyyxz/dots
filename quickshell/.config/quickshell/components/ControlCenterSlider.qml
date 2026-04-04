import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

RowLayout {
    id: root
    property string icon: ""
    property real value: 0.0
    property color color: Theme.mauve
    property bool muted: false
    signal moved(real val)
    signal pressed()
    signal released()
    signal iconClicked()

    spacing: 15

    Rectangle {
        width: 45; height: 45; radius: 12
        color: Theme.base
        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
            color: root.muted ? Theme.surface2 : root.color
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.iconClicked()
        }
    }

    Slider {
        id: control
        Layout.fillWidth: true
        from: 0; to: 1.0; value: root.value
        onMoved: root.moved(value)
        onPressedChanged: {
            if (pressed) root.pressed();
            else root.released();
        }

        background: Rectangle {
            x: control.leftPadding; y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 200; implicitHeight: 6; width: control.availableWidth; height: implicitHeight
            radius: 3; color: Theme.base
            Rectangle {
                width: control.visualPosition * parent.width; height: parent.height
                color: root.muted ? Theme.surface2 : root.color
                radius: 3
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width); y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 16; implicitHeight: 16; radius: 8
            color: Theme.text; border.color: root.color; border.width: 2
        }
    }
}
