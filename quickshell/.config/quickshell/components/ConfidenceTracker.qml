import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: confidenceRoot
    
    property bool authenticated: false
    property bool isShowing: true

    StudyService { id: service }

    property var subjects: []
    property var subjectProgress: ({})
    property var subjectCounts: ({})
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
            
            // Percentage
            let newProgress = JSON.parse(JSON.stringify(subjectProgress));
            newProgress[subjectName] = percentage;
            subjectProgress = newProgress;

            // Counts
            let newCounts = JSON.parse(JSON.stringify(subjectCounts));
            newCounts[subjectName] = completed + "/" + total;
            subjectCounts = newCounts;
        });
    }

    Component.onCompleted: refresh()

    implicitWidth: 370
    implicitHeight: 310
    color: Theme.crust
    radius: Theme.radius
    border.color: Theme.surface0
    border.width: 1

    // Window Ghost Mode
    opacity: confidenceRoot.isShowing ? 1.0 : 0.2
    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Subject Cockpit"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
                
                opacity: confidenceRoot.isShowing ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }
            }

            // Sync/Refresh Button
            Button {
                id: refreshButton
                padding: 6
                opacity: confidenceRoot.isShowing ? 1.0 : 0.0
                enabled: confidenceRoot.isShowing
                background: Rectangle {
                    radius: 8
                    color: refreshButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                }
                contentItem: Text { 
                    text: "󰑐"
                    font.family: "JetBrainsMono Nerd Font"
                    color: Theme.subtext0
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: confidenceRoot.refresh()
            }

            // Eye Toggle
            Button {
                id: eyeButton
                padding: 6
                background: Rectangle {
                    radius: 8
                    color: eyeButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                }
                contentItem: Image {
                    source: confidenceRoot.isShowing ? "../assets/eye-svgrepo-com.svg" : "../assets/eye-slash-svgrepo-com.svg"
                    sourceSize: Qt.size(18, 18)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: confidenceRoot.isShowing ? Theme.sapphire : Theme.subtext0 }
                }
                onClicked: confidenceRoot.isShowing = !confidenceRoot.isShowing
            }

            // Auth Button
            Button {
                id: authButton
                padding: 6
                opacity: confidenceRoot.isShowing ? 1.0 : 0.0
                enabled: confidenceRoot.isShowing
                background: Rectangle {
                    radius: 8
                    color: authButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                }
                contentItem: Image {
                    source: confidenceRoot.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(18, 18)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: confidenceRoot.authenticated ? Theme.green : Theme.red
                    }
                }
                onClicked: confidenceRoot.authenticated = !confidenceRoot.authenticated
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            opacity: confidenceRoot.isShowing ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

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
                    property string counts: (subjectCounts[subjectName] !== undefined) ? subjectCounts[subjectName] : "0/0"

                    readonly property color subjectColor: {
                        const name = subjectName.toLowerCase();
                        if (name.includes("math")) return Theme.sapphire;
                        if (name.includes("physics")) return Theme.maroon;
                        if (name.includes("ict")) return Theme.green;
                        return Theme.mauve;
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 10

                        // Icon Pill
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 8
                            color: Qt.rgba(subjectColor.r, subjectColor.g, subjectColor.b, 0.15)
                            
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
                                layer.effect: ColorOverlay { color: subjectColor }
                            }
                        }

                        // Added spacer to push squares right
                        Item { Layout.preferredWidth: 5 }

                        // Confidence Boxes
                        RowLayout {
                            spacing: 5
                            Repeater {
                                model: 6
                                delegate: Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 5
                                    color: (index + 1) <= currentRating ? subjectColor : Theme.base
                                    border.color: (index + 1) <= currentRating ? subjectColor : Theme.surface1
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: confidenceRoot.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (confidenceRoot.authenticated) {
                                                service.updateRating(subjectId, index + 1, () => confidenceRoot.refresh());
                                            }
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

                        // Space to push the rest to the right
                        Item { Layout.fillWidth: true }

                        // Raw Lesson Count Label
                        Text {
                            text: counts
                            color: Theme.subtext0
                            font.family: Theme.fontName
                            font.pixelSize: 10
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Vertical Separator
                        Rectangle {
                            width: 1
                            height: 20
                            color: Theme.surface1
                            opacity: 0.5
                            Layout.leftMargin: 2
                            Layout.rightMargin: 2
                        }

                        // Mastery Circle
                        Item {
                            width: 36
                            height: 36

                            ProgressCircle {
                                anchors.fill: parent
                                value: progress / 100
                                color: subjectColor
                                strokeWidth: 3
                            }

                            Text {
                                anchors.centerIn: parent
                                text: progress + "%"
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
}
