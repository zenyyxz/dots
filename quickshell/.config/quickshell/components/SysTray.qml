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
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                property var trayItem: modelData

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayItem.menu
                    anchor {
                        item: itemMouseArea
                        gravity: Edges.Bottom
                        edges: Edges.Bottom
                    }
                }

                onEntered: {
                    if (trayItem.tooltip) {
                        TooltipController.show(trayItem.tooltip, itemMouseArea);
                    }
                }
                onExited: TooltipController.hide()

                onWheel: (wheel) => {
                    if (typeof trayItem.scroll === "function") {
                        trayItem.scroll(wheel.angleDelta.y, Qt.Vertical);
                    }
                }

                onClicked: (mouse) => {
                    const globalPos = itemMouseArea.mapToGlobal(Qt.point(mouse.x, mouse.y));
                    if (mouse.button === Qt.LeftButton) {
                        if (typeof trayItem.activate === "function") {
                            trayItem.activate(globalPos.x, globalPos.y);
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        if (trayItem.hasMenu) {
                            trayMenu.open();
                        } else if (typeof trayItem.contextMenu === "function") {
                            trayItem.contextMenu(globalPos.x, globalPos.y);
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (typeof trayItem.secondaryActivate === "function") {
                            trayItem.secondaryActivate(globalPos.x, globalPos.y);
                        }
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
