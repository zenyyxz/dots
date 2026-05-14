import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Item {
    id: dashboardRoot
    
    property bool studyVisible: true

    GridLayout {
        anchors.fill: parent
        columns: 4
        rows: 3
        columnSpacing: 15
        rowSpacing: 15
        
        // Column 1: Combined Maths (Full Height)
        StudyTracker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 0
            Layout.row: 0
            Layout.rowSpan: 3
            Layout.preferredWidth: 550
            subjectName: "Combined Maths"
            flexibleWidth: true
        }

        // Column 2: Physics (Top) and ICT (Bottom)
        // Physics spans row 0 and 1 to match Cockpit + Chess height
        StudyTracker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 1
            Layout.row: 0
            Layout.rowSpan: 2
            Layout.preferredWidth: 550
            subjectName: "Physics"
            initTopicCount: 10
            flexibleWidth: true
        }
        
        StudyTracker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 1
            Layout.row: 2
            Layout.preferredWidth: 550
            subjectName: "ICT"
            initTopicCount: 10
            flexibleWidth: true
        }

        // Column 3: Subject Cockpit (Top), Chess (Middle)
        ConfidenceTracker {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 2
            Layout.row: 0
            Layout.preferredWidth: 370
            Layout.preferredHeight: 290
        }
        
        ChessWidget {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 2
            Layout.row: 1
            Layout.preferredWidth: 370
            Layout.preferredHeight: 195
        }

        // Column 4: Daily Tasks (Top 2 rows)
        TodoList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 3
            Layout.row: 0
            Layout.rowSpan: 2
            Layout.preferredWidth: 390
            Layout.preferredHeight: 500
        }

        // Row 3 (Bottom): Study Dashboard (Spans Col 3 and 4)
        StudyDashboard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.column: 2
            Layout.row: 2
            Layout.columnSpan: 2
            Layout.preferredHeight: 500
        }
    }
}
