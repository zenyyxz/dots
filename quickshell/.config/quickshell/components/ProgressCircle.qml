import QtQuick
import QtQuick.Shapes
import "../theme"

Item {
    id: root
    property real value: 0.0 // 0.0 to 1.0
    property color color: Theme.mauve
    property real strokeWidth: 2
    
    implicitWidth: 16
    implicitHeight: 16

    Behavior on value {
        NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4 // Antialiasing

        // Background Circle (the "track")
        ShapePath {
            strokeColor: Theme.surface1
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.strokeWidth) / 2; radiusY: (root.height - root.strokeWidth) / 2
                startAngle: -90
                sweepAngle: 360
            }
        }

        // Foreground Circle (the "usage")
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2; centerY: root.height / 2
                radiusX: (root.width - root.strokeWidth) / 2; radiusY: (root.height - root.strokeWidth) / 2
                startAngle: -90
                sweepAngle: 360 * root.value
            }
        }
    }
}
