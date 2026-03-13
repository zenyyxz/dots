pragma Singleton
import QtQuick

QtObject {
    property string text: ""
    property bool active: false
    property point pos: Qt.point(0, 0)

    function show(newText, item) {
        if (!item) return;
        const globalPos = item.mapToGlobal(Qt.point(item.width / 2, 0));
        text = newText;
        pos = globalPos;
        active = true;
    }

    function hide() {
        active = false;
    }
}
