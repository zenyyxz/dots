import QtQuick
import Quickshell
import "../theme"

Item {
    id: control
    
    property int todoId: -1
    property var service: null
    property color checkedColor: Theme.sapphire
    property bool initialChecked: false
    property bool checked: false
    property bool updating: false
    property bool studyEnabled: true
    readonly property bool hovered: checkMouse.containsMouse

    onInitialCheckedChanged: {
        if (!updating) {
            checked = initialChecked;
        }
    }

    signal toggled()

    function logToFile(msg) {
        const timestamp = new Date().toISOString();
        const fullMsg = `[${timestamp}] ${msg}`;
        Quickshell.execDetached(["bash", "-c", `echo '${fullMsg}' >> /tmp/quickshell_study.log`]);
    }

    MouseArea {
        id: checkMouse
        anchors.fill: parent
        enabled: control.studyEnabled && !control.updating
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        onClicked: {
            const newVal = !control.checked;
            control.checked = newVal;
            logToFile(`[TodoCheckBox] ID:${todoId} Clicked -> newVal:${newVal}`);
            control.updating = true;
            service.updateTodo(todoId, newVal, () => {
                logToFile(`[TodoCheckBox] ID:${todoId} update finished`);
                control.updating = false;
                toggled();
            });
        }
    }

    Rectangle {
        id: indicator
        anchors.centerIn: parent
        width: 18
        height: 18
        radius: 4
        color: control.checked ? control.checkedColor : "transparent"
        border.color: control.checked ? control.checkedColor : Theme.surface1
        border.width: 1.5
        
        opacity: control.updating ? 0.6 : 1.0
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: Theme.base
            visible: control.checked && !control.updating
        }

        RotationAnimation on rotation {
            from: 0; to: 360; duration: 1000
            running: control.updating
            loops: Animation.Infinite
        }
    }
}
