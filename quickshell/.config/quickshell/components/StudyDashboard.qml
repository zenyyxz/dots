import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: dashboardRoot
    
    // Horizontal Layout Dimensions
    implicitWidth: 800
    implicitHeight: 500
    
    radius: Theme.radius
    color: Qt.rgba(Theme.sapphire.r, Theme.sapphire.g, Theme.sapphire.b, 0.85)
    border.color: Theme.surface0
    border.width: 1
    
    StudyService { id: service }

    property var stats: ({ subjects: [], history: [], deadlines: [] })
    property bool loading: false
    property bool liveReload: true

    function refresh() {
        if (loading) return;
        loading = true;
        service.getDashboardStats((data) => {
            stats = data;
            loading = false;
        });
    }

    Timer {
        interval: 30000 // 30 seconds
        running: dashboardRoot.liveReload
        repeat: true
        onTriggered: dashboardRoot.refresh()
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 25

        // --- Column 1: Pomodoro Timer ---
        PomodoroTimer {
            Layout.preferredWidth: 350
            Layout.fillHeight: true
            onFinished: (s, sid) => service.logStudyTime(s, sid, () => dashboardRoot.refresh())
        }

        // Vertical Separator
        Rectangle { Layout.fillHeight: true; width: 1; color: Theme.surface1; opacity: 0.5 }

        // --- Column 2: History Chart ---
        StudyBarChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            history: dashboardRoot.stats.history
            liveReload: dashboardRoot.liveReload
            onToggleLiveReload: dashboardRoot.liveReload = !dashboardRoot.liveReload
        }
    }
}
