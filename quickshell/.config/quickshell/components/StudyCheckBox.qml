import QtQuick
import QtQuick.Controls
import "../theme"

CheckBox {
    id: control
    
    padding: 0
    implicitWidth: indicator.implicitWidth
    implicitHeight: indicator.implicitHeight

    property int topicId: -1
    property int columnIdx: -1
    property var service: null
    property color checkedColor: Theme.mauve

    onToggled: {
        if (service && topicId !== -1) {
            service.updateProgress(topicId, columnIdx, checked);
        }
    }

    indicator: Rectangle {
        implicitWidth: 14
        implicitHeight: 14
        radius: 3
        color: control.checked ? control.checkedColor : "transparent"
        border.color: control.checked ? control.checkedColor : Theme.surface1
        border.width: Theme.borderWidth

        Rectangle {
            width: 8
            height: 8
            anchors.centerIn: parent
            radius: 2
            color: Theme.crust
            visible: control.checked
        }
    }
}
