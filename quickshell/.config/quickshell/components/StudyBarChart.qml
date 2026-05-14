import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: root
    
    property var history: []
    property real maxHours: 8.0
    property bool liveReload: false
    property bool authenticated: false
    property string motivation: "Study like there's no tomorrow."
    signal toggleLiveReload()
    signal timeSet(string date, int seconds)
    
    StudyService { id: service }

    Component.onCompleted: {
        service.getConfig("motivation_quote", (val) => {
            if (val) root.motivation = val;
        });
    }

    radius: Theme.radius
    color: Theme.crust
    border.color: Theme.surface0
    border.width: 1
    
    width: 400
    height: 300

    function getAverage() {
        if (!history || history.length === 0) return 0;
        let total = 0;
        for (let i = 0; i < history.length; i++) {
            total += history[i].seconds;
        }
        return (total / history.length) / 3600;
    }

    function getOptimisticAverage(targetIndex, targetSeconds) {
        if (!history || history.length === 0) return 0;
        let total = 0;
        for (let i = 0; i < history.length; i++) {
            if (i === targetIndex) total += targetSeconds;
            else total += history[i].seconds;
        }
        return (total / history.length) / 3600;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Text {
                text: "History"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 22
                font.bold: true
                Layout.fillWidth: true
            }

            // --- Live Reload Toggle Button ---
            Button {
                id: liveToggle
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                enabled: root.authenticated
                
                background: Rectangle {
                    radius: 8
                    color: liveToggle.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: liveToggle.pressed ? Theme.green : "transparent"
                    border.width: 1
                    opacity: root.authenticated ? 1.0 : 0.5
                }

                contentItem: Item {
                    Rectangle {
                        id: glowDot
                        width: 8; height: 8; radius: 4
                        color: root.liveReload ? Theme.green : Theme.subtext0
                        anchors.centerIn: parent
                        
                        SequentialAnimation on opacity {
                            running: root.liveReload
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.4; duration: 1000; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.4; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
                        }

                        layer.enabled: root.liveReload
                        layer.effect: Glow {
                            radius: 12
                            samples: 15
                            color: Theme.green
                            transparentBorder: true
                        }
                    }
                }

                onClicked: root.toggleLiveReload()
            }

            // --- Auth Button ---
            Button {
                id: authButton
                padding: 8
                
                background: Rectangle {
                    radius: 6
                    color: authButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
                    border.color: authButton.pressed ? Theme.mauve : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                
                contentItem: Image {
                    source: root.authenticated ? "../assets/unlock.svg" : "../assets/lock.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: root.authenticated ? Theme.green : Theme.red
                    }
                    opacity: authButton.hovered ? 1.0 : 0.8
                }
                
                scale: pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                
                onClicked: root.authenticated = !root.authenticated
            }
        }

        // --- Summary Stats Pill ---
        Rectangle {
            id: statsPill
            Layout.fillWidth: true
            height: 48
            radius: 12
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1
            
            readonly property real actualTodayHours: (root.history && root.history.length > 0) ? root.history[root.history.length - 1].seconds / 3600 : 0
            readonly property real actualYesterdayHours: (root.history && root.history.length > 1) ? root.history[root.history.length - 2].seconds / 3600 : 0
            readonly property real actualAvgHours: root.getAverage()

            property real visualToday: actualTodayHours
            property real visualYesterday: actualYesterdayHours
            property real visualAvg: actualAvgHours

            Behavior on visualToday { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            Behavior on visualYesterday { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            Behavior on visualAvg { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

            onActualTodayHoursChanged: visualToday = actualTodayHours
            onActualYesterdayHoursChanged: visualYesterday = actualYesterdayHours
            onActualAvgHoursChanged: visualAvg = actualAvgHours

            Row {
                anchors.centerIn: parent
                spacing: 50

                Repeater {
                    model: [
                        { val: statsPill.visualYesterday.toFixed(1) + "h", color: Theme.subtext0, label: "Yest" },
                        { val: statsPill.visualToday.toFixed(1) + "h", color: Theme.teal, label: "Today" },
                        { val: statsPill.visualAvg.toFixed(1) + "h", color: Theme.mauve, label: "Avg" }
                    ]
                    delegate: Row {
                        spacing: 25
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: -2
                            Text { 
                                text: modelData.label
                                color: Theme.subtext0
                                font.family: Theme.smallFontName
                                font.pixelSize: 9
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text { 
                                text: modelData.val
                                color: modelData.color
                                font.family: Theme.fontName
                                font.pixelSize: 20
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        
                        // Vertical Separator
                        Rectangle {
                            visible: index < 2
                            width: 1; height: 24
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.surface1
                            opacity: 0.3
                        }
                    }
                }
            }
        }

        // --- Motivation Box ---
        Rectangle {
            id: motivationBox
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 10
            color: root.authenticated ? Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.08) : Theme.mantle
            border.color: root.authenticated ? Theme.teal : Theme.surface1
            border.width: 1
            Behavior on color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Text {
                    text: root.authenticated ? "󰏫" : "󰄬"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Theme.teal
                }

                TextInput {
                    id: motivationInput
                    Layout.fillWidth: true
                    text: root.motivation
                    color: Theme.text
                    font.family: Theme.smallFontName
                    font.pixelSize: 13
                    font.italic: !root.authenticated
                    enabled: root.authenticated
                    selectByMouse: true
                    
                    onEditingFinished: {
                        if (text !== root.motivation) {
                            root.motivation = text;
                            service.setConfig("motivation_quote", text);
                        }
                    }
                }
            }
        }

        // --- Chart ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                anchors.fill: parent
                spacing: 10

                Repeater {
                    model: root.history
                    delegate: ColumnLayout {
                        id: barCol
                        width: (parent.width - (parent.spacing * 6)) / 7
                        height: parent.height
                        spacing: 6
                        
                        readonly property int dayIndex: index
                        readonly property string date: modelData.date
                        readonly property string day: modelData.day
                        property bool dayHovered: false
                        
                        property real visualHours: modelData.seconds / 3600

                        NumberAnimation {
                            id: fillAnim
                            target: barCol
                            property: "visualHours"
                            duration: 700
                            easing.type: Easing.OutCubic
                        }

                        function animateTo(target) {
                            fillAnim.stop();
                            fillAnim.from = visualHours;
                            fillAnim.to = target;
                            fillAnim.start();
                        }

                        // Keep visualHours in sync with model updates when locked
                        Binding {
                            target: barCol
                            property: "visualHours"
                            value: modelData.seconds / 3600
                            when: !root.authenticated && !fillAnim.running
                        }
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Column {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                spacing: 3
                                
                                Repeater {
                                    model: 16
                                    delegate: Rectangle {
                                        id: pill
                                        width: parent.width
                                        height: 12
                                        radius: 5
                                        
                                        readonly property int pillIndex: 15 - index
                                        readonly property bool active: pillIndex < Math.floor(barCol.visualHours)
                                        property bool showNumber: false
                                        
                                        color: {
                                            if (root.authenticated && (pillHover.containsMouse || barCol.dayHovered)) {
                                                return active ? Theme.red : (pillHover.containsMouse ? Theme.green : Theme.surface1);
                                            }
                                            if (!active) return Theme.surface1;
                                            if (pillIndex < 4) return Theme.sky;
                                            if (pillIndex < 8) return Theme.teal;
                                            if (pillIndex < 12) return Theme.lavender;
                                            return Theme.mauve;
                                        }
                                        
                                        opacity: {
                                            if (active) return 1.0;
                                            if (root.authenticated && pillHover.containsMouse) return 1.0;
                                            return 0.3;
                                        }
                                        
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Timer {
                                            id: hideTimer
                                            interval: 2000 // 2 seconds delay
                                            onTriggered: pill.showNumber = false
                                        }

                                        MouseArea {
                                            id: pillHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: root.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onEntered: {
                                                if (!root.authenticated) {
                                                    hideTimer.stop();
                                                    pill.showNumber = true;
                                                }
                                            }
                                            onExited: {
                                                if (!root.authenticated) {
                                                    hideTimer.start();
                                                }
                                            }
                                            onClicked: {
                                                if (root.authenticated) {
                                                    let targetHours = pillIndex + 1;
                                                    let targetSeconds = targetHours * 3600;
                                                    
                                                    barCol.animateTo(targetHours);
                                                    
                                                    // Optimistic Summary Update: Update numbers immediately to align with pill animation
                                                    if (barCol.dayIndex === 6) statsPill.visualToday = targetHours;
                                                    if (barCol.dayIndex === 5) statsPill.visualYesterday = targetHours;
                                                    statsPill.visualAvg = root.getOptimisticAverage(barCol.dayIndex, targetSeconds);
                                                    
                                                    root.timeSet(barCol.date, targetSeconds);
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: {
                                                if (root.authenticated) return active ? "－" : "＋";
                                                return (pillIndex + 1).toString();
                                            }
                                            color: Theme.crust
                                            font.family: Theme.smallFontName
                                            font.pixelSize: root.authenticated ? 12 : 9
                                            font.weight: Font.DemiBold
                                            
                                            opacity: {
                                                if (root.authenticated) return pillHover.containsMouse ? 1.0 : 0.0;
                                                return pill.active && pill.showNumber ? 1.0 : 0.0;
                                            }
                                            scale: opacity
                                            
                                            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: barCol.visualHours.toFixed(1) + "h"
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 9
                                font.bold: true
                                visible: barCol.visualHours > 0
                            }
                        }
                        
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: parent.width
                            Layout.preferredHeight: 20

                            Text {
                                id: dayLabel
                                anchors.centerIn: parent
                                text: root.authenticated && barCol.dayHovered ? "－" : barCol.day
                                color: root.authenticated && barCol.dayHovered ? Theme.red : Theme.subtext0
                                font.family: Theme.smallFontName
                                font.pixelSize: root.authenticated && barCol.dayHovered ? 12 : 9
                                font.bold: true
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: root.authenticated ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: if (root.authenticated) barCol.dayHovered = true
                                onExited: barCol.dayHovered = false
                                onClicked: {
                                    if (root.authenticated) {
                                        barCol.animateTo(0);
                                        if (barCol.dayIndex === 6) statsPill.visualToday = 0;
                                        if (barCol.dayIndex === 5) statsPill.visualYesterday = 0;
                                        statsPill.visualAvg = root.getOptimisticAverage(barCol.dayIndex, 0);
                                        root.timeSet(barCol.date, 0);
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
