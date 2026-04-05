import QtQuick
import Quickshell
import "../theme"

Item {
    id: control
    
    property int topicId: -1
    property int columnIdx: -1
    property var service: null
    property color checkedColor: Theme.mauve
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
            logToFile(`[StudyCheckBox] ID:${topicId} Col:${columnIdx} Clicked -> newVal:${newVal}`);
            control.updating = true;
            service.updateProgress(topicId, columnIdx, newVal, () => {
                logToFile(`[StudyCheckBox] ID:${topicId} update finished`);
                control.updating = false;
                toggled();
            });
        }
    }

    Rectangle {
        id: indicator
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: 3
        color: control.checked ? control.checkedColor : "transparent"
        border.color: control.checked ? control.checkedColor : Theme.surface1
        border.width: Theme.borderWidth
        
        opacity: control.updating ? 0.5 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Optional: Add a checkmark icon or dot when checked
        Rectangle {
            anchors.centerIn: parent
            width: 8; height: 8; radius: 2
            color: Theme.base
            visible: control.checked && !control.updating
        }
    }
}
