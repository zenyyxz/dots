import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    property string entry
    property real maxWidth: 400
    property real maxHeight: 200
    
    property string source
    property string tempPath: `/tmp/cliphist_preview_${entryNumber}.png`

    property int entryNumber: {
        const match = entry.match(/^(\d+)\t/);
        return match ? parseInt(match[1]) : 0;
    }

    color: "transparent"
    radius: 12
    clip: true
    
    implicitWidth: maxWidth
    implicitHeight: Math.min(maxHeight, (img.implicitHeight / img.implicitWidth) * maxWidth)

    Component.onCompleted: {
        decodeProc.running = true;
    }

    Process {
        id: decodeProc
        command: ["bash", "-c", `cliphist decode <<< '${root.entry}' > ${root.tempPath}`]
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.source = "file://" + root.tempPath;
            }
        }
    }

    // Cleanup temp file on destruction
    Component.onDestruction: {
        Quickshell.execDetached(["rm", "-f", root.tempPath]);
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        visible: status === Image.Ready
        
        Rectangle {
            anchors.fill: parent
            color: Theme.surface0
            visible: parent.status !== Image.Ready
            radius: root.radius
            
            Text {
                anchors.centerIn: parent
                text: "Loading image..."
                color: Theme.surface2
                font.family: Theme.fontName
                font.pixelSize: 12
            }
        }
    }
}
