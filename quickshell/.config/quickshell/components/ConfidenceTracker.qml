import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: confidenceRoot
    
    StudyService { id: service }

    property var subjects: []
    property bool loading: false

    function refresh() {
        loading = true;
        service.getSubjects((data) => {
            subjects = data;
            loading = false;
        });
    }

    Component.onCompleted: refresh()

    implicitWidth: 320
    implicitHeight: 280
    color: Theme.crust
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: 1

    // Sapphire Tint Overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.sapphire
        opacity: 0.08
        radius: parent.radius
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "Subject Confidence"
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            Repeater {
                model: confidenceRoot.subjects
                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    property int subjectId: modelData.id
                    property int currentRating: modelData.rating || 0

                    Text {
                        text: {
                            const name = modelData.name.toLowerCase();
                            if (name.includes("math")) return "\uf0626"; // Sigma
                            if (name.includes("physics")) return "\uf0831"; // Atom
                            if (name.includes("ict")) return "\uf066f"; // Monitor
                            return "\uf059d"; // Question mark
                        }
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 26
                        color: Theme.sapphire
                        Layout.preferredWidth: 35
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        spacing: 10
                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                width: 24
                                height: 24
                                radius: 6
                                color: (index + 1) <= currentRating ? Theme.sapphire : "transparent"
                                border.color: (index + 1) <= currentRating ? Theme.sapphire : Theme.surface1
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        service.updateRating(subjectId, index + 1, () => confidenceRoot.refresh());
                                    }
                                }

                                // Inner dot for better visibility
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 10
                                    height: 10
                                    radius: 3
                                    color: Theme.crust
                                    visible: (index + 1) <= currentRating
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
