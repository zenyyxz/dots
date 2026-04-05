import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: dashboardRoot
    
    // Horizontal Layout Dimensions
    width: 1000
    height: 500
    
    radius: Theme.radius
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    border.color: Theme.surface0
    border.width: 1
    
    StudyService { id: service }

    property var stats: ({ subjects: [], history: [] })
    property bool loading: false

    function refresh() {
        loading = true;
        service.getDashboardStats((data) => {
            stats = data;
            loading = false;
        });
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 25

        // --- Column 1: Subject Progress (Stacked Vertically) ---
        ColumnLayout {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: 15

            Text {
                text: "Subjects"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 22
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    spacing: 12
                    
                    Repeater {
                        model: dashboardRoot.stats.subjects
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 70
                            radius: 12
                            color: Theme.surface0
                            border.color: Theme.surface1
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                
                                Text {
                                    text: modelData.name
                                    color: Theme.text; font.family: Theme.fontName; font.pixelSize: 13; font.bold: true
                                }
                                
                                RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 80; height: 18; radius: 9; color: Theme.mauve
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.completed + " / " + modelData.total
                                            color: Theme.crust; font.pixelSize: 9; font.bold: true
                                        }
                                    }
                                    Row {
                                        spacing: 2
                                        Repeater {
                                            model: 5
                                            Text {
                                                text: index < modelData.rating ? "󰓎" : "󰓏"
                                                font.family: "JetBrainsMono Nerd Font"
                                                color: index < modelData.rating ? Theme.yellow : Theme.surface2
                                                font.pixelSize: 12
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: service.updateRating(modelData.id, index + 1, () => dashboardRoot.refresh())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Vertical Separator
        Rectangle { Layout.fillHeight: true; width: 1; color: Theme.surface1; opacity: 0.5 }

        // --- Column 2: Pomodoro Timer ---
        PomodoroTimer {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            onFinished: (s) => service.logStudyTime(s, () => dashboardRoot.refresh())
        }

        // Vertical Separator
        Rectangle { Layout.fillHeight: true; width: 1; color: Theme.surface1; opacity: 0.5 }

        // --- Column 3: History Chart ---
        StudyBarChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: dashboardRoot.stats.history
        }
    }
}
