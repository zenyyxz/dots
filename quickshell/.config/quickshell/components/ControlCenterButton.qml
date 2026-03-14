import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    height: 60
    radius: 16
    
    // Animate color change
    color: active ? Theme.mauve : Theme.surface0
    Behavior on color { ColorAnimation { duration: 250 } }
    
    border.color: active ? "transparent" : Theme.surface1
    border.width: 1

    // Scale animation on click/hover
    scale: mouseArea.pressed ? 0.96 : (mouseArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            width: 36; height: 36; radius: 10
            color: root.active ? Qt.rgba(0,0,0,0.1) : Theme.surface1
            
            Behavior on color { ColorAnimation { duration: 250 } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
                color: root.active ? Theme.base : Theme.mauve
                
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }

        ColumnLayout {
            spacing: 0
            Text { 
                text: root.label
                color: root.active ? Theme.base : Theme.text
                font.family: Theme.fontName; font.pixelSize: 13; font.bold: true 
                Behavior on color { ColorAnimation { duration: 250 } }
            }
            Text { 
                text: root.active ? "On" : "Off"
                color: root.active ? Theme.base : Theme.subtext0
                font.family: Theme.fontName; font.pixelSize: 11; opacity: 0.8 
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }
    }

    MouseArea { 
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked() 
    }
}
