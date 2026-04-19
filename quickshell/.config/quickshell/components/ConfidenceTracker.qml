import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: confidenceRoot
    
    StudyService { id: service }

    property var subjects: []
    property var subjectProgress: ({})
    property bool loading: false

    function refresh() {
        loading = true;
        service.getSubjects((data) => {
            subjects = data;
            loading = false;
            if (data) {
                data.forEach(s => updateProgressForSubject(s.name));
            }
        });
    }

    function updateProgressForSubject(subjectName) {
        service.getSubjectData(subjectName, (data) => {
            if (!data || data.length === 0) return;
            let total = data.length;
            let completed = 0;
            for (let i = 0; i < total; i++) {
                if (data[i].checked && data[i].checked[0]) completed++;
            }
            let percentage = Math.round((completed / total) * 100);
            
            // Trigger property update
            let newProgress = JSON.parse(JSON.stringify(subjectProgress));
            newProgress[subjectName] = percentage;
            subjectProgress = newProgress;
        });
    }

    Component.onCompleted: refresh()

    implicitWidth: 370
    implicitHeight: 300
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
        anchors.margins: 14
        spacing: 12

        Text {
            text: "Subject Cockpit"
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: 18
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Repeater {
                model: confidenceRoot.subjects
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 12
                    color: Theme.surface0
                    border.color: Theme.surface1
                    border.width: 1

                    property int subjectId: modelData ? modelData.id : -1
                    property string subjectName: modelData ? modelData.name : ""
                    property int currentRating: (modelData && modelData.rating) ? modelData.rating : 0
                    property int progress: (subjectProgress[subjectName] !== undefined) ? subjectProgress[subjectName] : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        // Icon Pill
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 8
                            color: Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.15)
                            
                            Image {
                                id: iconImage
                                anchors.centerIn: parent
                                source: {
                                    if (!modelData || !modelData.name) return "";
                                    const name = modelData.name.toLowerCase();
                                    if (name.includes("math")) return "../assets/sigma.svg";
                                    if (name.includes("physics")) return "../assets/atom.svg";
                                    if (name.includes("ict")) return "../assets/code.svg";
                                    return "../assets/eye-svgrepo-com.svg";
                                }
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: Theme.sapphire }
                            }
                        }

                        // Confidence Boxes
                        RowLayout {
                            spacing: 5
                            Repeater {
                                model: 6
                                delegate: Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 5
                                    color: (index + 1) <= currentRating ? Theme.sapphire : Theme.base
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

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 8
                                        height: 8
                                        radius: 2
                                        color: Theme.crust
                                        visible: (index + 1) <= currentRating
                                    }
                                }
                            }
                        }

                        // Vertical Separator
                        Rectangle {
                            width: 1
                            height: 20
                            color: Theme.surface1
                            opacity: 0.5
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                        }

                        // Mastery Square
                        Rectangle {
                            width: 40
                            height: 32
                            radius: 6
                            color: Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.1)
                            border.color: Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.3)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2
                                text: progress + "%"
                                color: Theme.sapphire
                                font.family: Theme.fontName
                                font.pixelSize: 11
                                font.bold: true
                            }
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 8
                                height: 2
                                radius: 1
                                color: Theme.base
                                anchors.bottomMargin: 3
                                
                                Rectangle {
                                    width: parent.width * (progress / 100)
                                    height: parent.height
                                    radius: 1
                                    color: Theme.sapphire
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
