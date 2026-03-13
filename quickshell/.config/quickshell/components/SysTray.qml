import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../theme"

Rectangle {
    id: root
    
    color: Theme.base
    radius: Theme.radius
    border.color: Theme.borderColor
    border.width: Theme.borderWidth
    
    implicitWidth: visible ? (layout.implicitWidth + 20) : 0
    implicitHeight: 32
    
    visible: trayRepeater.count > 0

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: trayRepeater
            model: SystemTray.items
            delegate: MouseArea {
                id: itemMouseArea
                width: 24
                height: 24
                hoverEnabled: true

                property var trayItem: modelData

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        trayItem.activate();
                    } else if (mouse.button === Qt.RightButton) {
                        trayItem.contextMenu();
                    }
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: trayItem.icon
                    fillMode: Image.PreserveAspectFit
                }

                // Hover highlight
                Rectangle {
                    anchors.fill: parent
                    color: Theme.text
                    opacity: itemMouseArea.containsMouse ? 0.1 : 0
                    radius: 4
                }
            }
        }
    }
}
