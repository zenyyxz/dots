import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import Qt5Compat.GraphicalEffects
import "../theme"

Rectangle {
    id: root
    
    property int secondsRemaining: 25 * 60
    property bool running: false
    property string mode: "focus" // focus, custom
    
    property int selectedSubjectId: -1
    property var subjects: []
    StudyService { id: service }

    property var customTimersList: []
    property int _internalSelectedIndex: -1

    function refreshTimers() {
        service.getTimers((data) => {
            customTimersList = data;
        });
    }

    function saveState() {
        service.setConfig("pomodoro_subject_id", root.selectedSubjectId.toString());
        service.setConfig("pomodoro_mode", root.mode);
        if (root.mode === "custom" && customTimersList.length > 0 && _internalSelectedIndex !== -1) {
            let currentTimer = customTimersList[_internalSelectedIndex];
            if (currentTimer) service.setConfig("pomodoro_custom_id", currentTimer.id.toString());
        }
    }

    Component.onCompleted: {
        Qt.application.name = "PomodoroTimer";
        Qt.application.organization = "quickshell";
        
        service.getTimers((timers) => {
            customTimersList = timers;
            
            service.getConfig("pomodoro_mode", (modeVal) => {
                if (modeVal) root.mode = modeVal;
                
                service.getConfig("pomodoro_custom_id", (idVal) => {
                    if (idVal) {
                        let idx = timers.findIndex(t => t.id === parseInt(idVal));
                        if (idx !== -1) {
                            _internalSelectedIndex = idx;
                            if (root.mode === "custom") {
                                setCustomMode(idx, false);
                            }
                        }
                    }
                });
            });
        });

        service.getSubjects((data) => {
            subjects = data;
            service.getConfig("pomodoro_subject_id", (val) => {
                if (val && parseInt(val) !== -1) {
                    root.selectedSubjectId = parseInt(val);
                } else if (data.length > 0) {
                    root.selectedSubjectId = data[0].id;
                }
            });
        });
    }

    onSelectedSubjectIdChanged: saveState()
    onModeChanged: saveState()

    signal finished(int totalSeconds, int subjectId)
    
    radius: Theme.radius
    color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.85)
    border.color: Theme.surface0
    border.width: 1
    
    width: 300
    height: 380

    function setMode(newMode) {
        root.running = false;
        root.mode = newMode;
        if (newMode === "focus") root.secondsRemaining = 25 * 60;
        saveState();
    }

    function setCustomMode(index, shouldSave = true) {
        if (index >= 0 && index < root.customTimersList.length) {
            root.running = false;
            root.mode = "custom";
            let mins = root.customTimersList[index].minutes;
            root.secondsRemaining = mins * 60;
            _internalSelectedIndex = index;
            if (shouldSave) saveState();
        }
    }

    function addCustomTimer(name, minutes) {
        service.addTimer(name, minutes, () => {
            service.getTimers((data) => {
                customTimersList = data;
                setCustomMode(data.length - 1);
            });
        });
    }

    function deleteCustomTimer(id) {
        service.deleteTimer(id, () => {
            refreshTimers();
            if (root.mode === "custom") {
                root.setMode("focus");
                _internalSelectedIndex = -1;
            }
        });
    }

    function formatTime(s) {
        let mins = Math.floor(s / 60);
        let secs = s % 60;
        return (mins < 10 ? "0" : "") + mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    property int _elapsedSeconds: 0

    Timer {
        id: mainTimer
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            if (root.secondsRemaining > 0) {
                root.secondsRemaining--;
                root._elapsedSeconds++;
                
                // Log every minute to the DB
                if (root._elapsedSeconds >= 60) {
                    service.logStudyTime(60, root.selectedSubjectId);
                    root._elapsedSeconds = 0;
                    service.logToFile(`[Pomodoro] Synced 60s to DB (Running)`);
                }
            } else {
                root.running = false;
                
                // Log any remaining seconds that didn't make a full minute
                if (root._elapsedSeconds > 0) {
                    service.logStudyTime(root._elapsedSeconds, root.selectedSubjectId);
                    service.logToFile(`[Pomodoro] Synced final ${root._elapsedSeconds}s to DB (Finished)`);
                    root._elapsedSeconds = 0;
                }

                let totalSeconds = 0;
                if (root.mode === "focus") {
                    totalSeconds = 25 * 60;
                } else if (root.mode === "custom") {
                    if (_internalSelectedIndex >= 0 && _internalSelectedIndex < root.customTimersList.length) {
                        totalSeconds = root.customTimersList[_internalSelectedIndex].minutes * 60;
                    }
                }
                
                root.finished(totalSeconds, root.selectedSubjectId);
                service.logToFile(`[Pomodoro] Timer sequence completed`);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        Text {
            text: "Pomodoro"
            color: Theme.text
            font.family: Theme.fontName
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Subject Selector
        Rectangle {
            id: subjectPillContainer
            Layout.alignment: Qt.AlignHCenter
            height: 32
            implicitWidth: subRow.implicitWidth + 8
            radius: 16
            color: Theme.surface1

            Rectangle {
                id: selectionIndicator
                height: 26
                radius: 13
                color: Theme.mauve
                y: 3
                visible: root.selectedSubjectId !== -1
                Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            }
            
            RowLayout {
                id: subRow
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: root.subjects
                    delegate: Item {
                        id: subjectItem
                        height: 26
                        implicitWidth: subLabel.implicitWidth + 24
                        
                        Text {
                            id: subLabel
                            anchors.centerIn: parent
                            text: {
                                if (modelData.name === "Combined Maths") return "CM";
                                if (modelData.name === "Physics") return "P6";
                                if (modelData.name === "ICT") return "IT";
                                return modelData.name;
                            }
                            color: root.selectedSubjectId === modelData.id ? Theme.crust : Theme.text
                            font.family: Theme.fontName
                            font.pixelSize: 11
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectedSubjectId = modelData.id
                        }

                        function updateIndicator() {
                            if (root.selectedSubjectId === modelData.id) {
                                selectionIndicator.x = subjectItem.x + subRow.x;
                                selectionIndicator.width = subjectItem.width;
                            }
                        }

                        Connections {
                            target: root
                            function onSelectedSubjectIdChanged() { subjectItem.updateIndicator(); }
                        }
                        
                        Component.onCompleted: subjectItem.updateIndicator();
                        onXChanged: subjectItem.updateIndicator();
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 30
            
            Text {
                text: "Focus"
                color: root.mode === "focus" ? Theme.mauve : Theme.subtext0
                font.family: Theme.fontName
                font.pixelSize: 16
                font.bold: root.mode === "focus"
                Behavior on color { ColorAnimation { duration: 250 } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setMode("focus")
                }
            }

            Text {
                id: customPlaceholder
                text: {
                    if (root.customTimersList.length === 0) return "Custom +";
                    if (_internalSelectedIndex >= 0 && _internalSelectedIndex < root.customTimersList.length) {
                        let t = root.customTimersList[_internalSelectedIndex];
                        return t.name + " " + t.minutes + "m";
                    }
                    return "Custom";
                }
                color: root.mode === "custom" ? Theme.sapphire : Theme.subtext0
                font.family: Theme.fontName
                font.pixelSize: 16
                font.bold: root.mode === "custom"
                Behavior on color { ColorAnimation { duration: 250 } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.customTimersList.length === 0) {
                            addTimerDialog.open();
                        } else {
                            if (root.mode !== "custom") {
                                root.setCustomMode(_internalSelectedIndex);
                            } else {
                                customTimerPopup.open();
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 145
            
            // Background Glow (Replacement for RectangularGloss)
            Rectangle {
                id: backgroundGlow
                anchors.centerIn: parent
                width: 130; height: 130
                radius: 65
                color: root.mode === "focus" ? Theme.mauve : Theme.sapphire
                opacity: root.running ? 0.1 : 0.0
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                layer.enabled: true
                layer.effect: Glow {
                    radius: 20
                    color: backgroundGlow.color
                    transparentBorder: true
                }
            }

            ProgressCircle {
                id: progCircle
                anchors.centerIn: parent
                width: 155; height: 155
                strokeWidth: 8
                value: {
                    let total = 25 * 60;
                    if (root.mode === "custom") {
                        if (_internalSelectedIndex >= 0 && _internalSelectedIndex < root.customTimersList.length) {
                            total = root.customTimersList[_internalSelectedIndex].minutes * 60;
                        }
                    }
                    return (total - root.secondsRemaining) / total;
                }
                color: root.mode === "focus" ? Theme.mauve : Theme.sapphire
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -5
                
                Text {
                    text: {
                        if (root.mode === "focus") return "FOCUS";
                        if (_internalSelectedIndex >= 0 && _internalSelectedIndex < root.customTimersList.length) {
                            return root.customTimersList[_internalSelectedIndex].name.toUpperCase();
                        }
                        return "CUSTOM";
                    }
                    color: root.mode === "focus" ? Theme.mauve : Theme.sapphire
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                    opacity: 0.8
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: root.formatTime(root.secondsRemaining)
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: root.secondsRemaining >= 3600 ? 28 : 34
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 4
                        color: Qt.rgba(0,0,0,0.5)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 0
            Layout.bottomMargin: 10

            Button {
                id: startBtn
                implicitWidth: 54
                implicitHeight: 54
                
                background: Rectangle {
                    radius: 27
                    color: startBtn.down ? Qt.darker(buttonColor, 1.2) : (startBtn.hovered ? buttonColor : "transparent")
                    border.color: buttonColor
                    border.width: 2
                    
                    readonly property color buttonColor: root.mode === "focus" ? Theme.mauve : Theme.sapphire
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                contentItem: Item {
                    Image {
                        id: playIcon
                        anchors.centerIn: parent
                        source: "../assets/play.svg"
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                        opacity: root.running ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: startBtn.hovered || startBtn.down ? Theme.crust : (root.mode === "focus" ? Theme.mauve : Theme.sapphire)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Image {
                        id: pauseIcon
                        anchors.centerIn: parent
                        source: "../assets/pause.svg"
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectFit
                        opacity: root.running ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: startBtn.hovered || startBtn.down ? Theme.crust : (root.mode === "focus" ? Theme.mauve : Theme.sapphire)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                onClicked: root.running = !root.running
            }
        }
    }

    Popup {
        id: customTimerPopup
        width: 240
        height: Math.min(300, contentCol.implicitHeight + 30)
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: Theme.surface0
            radius: Theme.radius
            border.color: Theme.sapphire
            border.width: 1
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            
            ColumnLayout {
                id: contentCol
                width: parent.width - 20
                spacing: 8

                Repeater {
                    model: root.customTimersList
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 6
                        color: {
                            if (_internalSelectedIndex === index && root.mode === "custom") return Theme.surface1;
                            return timerHover.containsMouse ? Theme.surface1 : "transparent";
                        }
                        border.color: (_internalSelectedIndex === index && root.mode === "custom") ? Theme.sapphire : "transparent"
                        border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            Text {
                                text: modelData.name
                                color: Theme.text
                                font.family: Theme.fontName
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.minutes + "m"
                                color: Theme.sapphire
                                font.family: Theme.fontName
                                font.pixelSize: 12
                                font.bold: true
                            }
                            
                            // Delete Button
                            Rectangle {
                                width: 24; height: 24
                                radius: 12
                                color: deleteHover.containsMouse ? Theme.red : "transparent"
                                opacity: deleteHover.containsMouse ? 1.0 : 0.5
                                visible: !root.running // Don't allow deleting while running
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: deleteHover.containsMouse ? Theme.crust : Theme.subtext0
                                }
                                
                                MouseArea {
                                    id: deleteHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.deleteCustomTimer(modelData.id);
                                    }
                                }
                            }
                        }
                        
                        MouseArea {
                            id: timerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.setCustomMode(index);
                                customTimerPopup.close();
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: addTimerHover.containsMouse ? Theme.surface1 : "transparent"
                    border.color: Theme.sapphire
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: "+ Add New Timer"
                        color: Theme.sapphire
                        font.family: Theme.fontName
                        font.pixelSize: 13
                        font.bold: true
                    }
                    
                    MouseArea {
                        id: addTimerHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            customTimerPopup.close();
                            addTimerDialog.open();
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: addTimerDialog
        width: 280
        height: 220
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: Theme.surface0
            radius: Theme.radius
            border.color: Theme.sapphire
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: "New Custom Timer"
                color: Theme.sapphire
                font.family: Theme.fontName
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            TextField {
                id: timerNameInput
                Layout.fillWidth: true
                placeholderText: "Timer Name (e.g. Break)"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 13
                background: Rectangle {
                    color: Theme.surface1
                    radius: 6
                    border.color: timerNameInput.activeFocus ? Theme.sapphire : "transparent"
                }
            }

            TextField {
                id: timerTimeInput
                Layout.fillWidth: true
                placeholderText: "Duration (minutes)"
                color: Theme.text
                font.family: Theme.fontName
                font.pixelSize: 13
                validator: IntValidator { bottom: 1; top: 999 }
                background: Rectangle {
                    color: Theme.surface1
                    radius: 6
                    border.color: timerTimeInput.activeFocus ? Theme.sapphire : "transparent"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 5
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    radius: 6
                    color: Theme.surface1
                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.text; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: addTimerDialog.close() }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 35
                    radius: 6
                    color: Theme.sapphire
                    Text { anchors.centerIn: parent; text: "Create"; color: Theme.crust; font.pixelSize: 13; font.bold: true }
                    MouseArea { 
                        anchors.fill: parent; 
                        onClicked: {
                            if (timerNameInput.text !== "" && timerTimeInput.text !== "") {
                                let mins = parseInt(timerTimeInput.text);
                                if (mins > 0) {
                                    root.addCustomTimer(timerNameInput.text, mins);
                                }
                            }
                            timerNameInput.text = "";
                            timerTimeInput.text = "";
                            addTimerDialog.close();
                        }
                    }
                }
            }
        }
    }
}
