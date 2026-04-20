import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../theme"

Rectangle {
    id: chessRoot
    
    property string username: "zen_dx"
    property int rapidRating: 0
    property int startOfDayRating: 0
    property bool loading: false
    property bool isShowing: true

    radius: Theme.radius
    color: Theme.crust
    border.color: Theme.surface0
    border.width: 1

    opacity: isShowing ? 1.0 : 0.2
    Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

    // Sapphire Tint Overlay
    Rectangle {
        anchors.fill: parent
        color: Theme.sapphire
        opacity: 0.08
        radius: parent.radius
        z: -1
    }

    readonly property int eloDiff: rapidRating - startOfDayRating

    function refresh() {
        if (loading) return;
        loading = true;
        rotateAnim.restart();
        fetchStats.running = true;
    }

    // --- Data Fetching ---
    Process {
        id: fetchStats
        command: ["/home/zenyyxz/dotfiles/quickshell/.config/quickshell/get_chess_stats.sh"]
        running: false
        stdout: SplitParser {
            onRead: msg => {
                try {
                    const data = JSON.parse(msg.trim());
                    if (data.current !== undefined) chessRoot.rapidRating = data.current;
                    if (data.baseline !== undefined) chessRoot.startOfDayRating = data.baseline;
                } catch (e) { 
                    console.error("Chess.com API Error parsing message:", msg, "Error:", e); 
                }
                chessRoot.loading = false;
            }
        }
    }

    // Refresh every 2 hours
    Timer { interval: 7200000; running: true; repeat: true; onTriggered: chessRoot.refresh() }
    
    // Check if it's a new day every minute (to reset baseline at midnight)
    property string currentDate: new Date().toLocaleDateString()
    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            const now = new Date().toLocaleDateString();
            if (now !== chessRoot.currentDate) {
                chessRoot.currentDate = now;
                chessRoot.refresh(); // Baseline is reset in the script on new day
            }
        }
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.leftMargin: 45
        spacing: 15

        // --- Left Side: Pawn Circle ---
        Item {
            id: pawnContainer
            Layout.preferredWidth: 90
            Layout.preferredHeight: 90
            Layout.alignment: Qt.AlignVCenter
            
            property color pawnColor: Theme.sapphire
            scale: 1.0
            antialiasing: true
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surface0
                border.color: Theme.sapphire
                border.width: 2
                opacity: 0.6
                antialiasing: true

                Image {
                    anchors.centerIn: parent
                    source: "../assets/pawn.svg"
                    sourceSize: Qt.size(100, 100) // Rendered larger to avoid artifacts when scaling
                    width: 50; height: 50
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: ColorOverlay { 
                        color: pawnContainer.pawnColor
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pawnContainer.scale = 1.2;
                        pawnContainer.pawnColor = Theme.green;
                        resetTimer.restart();
                        chessRoot.refresh();
                    }
                }

                Timer {
                    id: resetTimer
                    interval: 200
                    onTriggered: {
                        pawnContainer.scale = 1.0;
                        pawnContainer.pawnColor = Theme.sapphire;
                    }
                }
            }
        }

        // --- Right Side: Stats ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            RowLayout {
                spacing: 8
                
                Image {
                    source: "../assets/stopwatch.svg"
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay { color: Theme.green }
                }

                Text {
                    text: "RAPID"
                    color: Theme.subtext0
                    font.family: Theme.fontName
                    font.pixelSize: 14
                    font.bold: true
                }
            }

            Item {
                Layout.preferredWidth: eloDisplay.implicitWidth + 40
                Layout.preferredHeight: eloDisplay.implicitHeight
                
                Text {
                    id: eloDisplay
                    text: chessRoot.rapidRating > 0 ? chessRoot.rapidRating : "---"
                    color: Theme.text
                    font.family: Theme.fontName
                    font.pixelSize: 42
                    font.bold: true
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chessRoot.refresh()
                    }
                }

                // Top Right: Positive Change (Superscript)
                Text {
                    anchors.top: eloDisplay.top
                    anchors.topMargin: 2
                    anchors.left: eloDisplay.right
                    anchors.leftMargin: 8
                    text: "+" + (chessRoot.eloDiff > 0 ? chessRoot.eloDiff : 0)
                    color: Theme.green // Always green as requested
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    font.bold: true
                    opacity: chessRoot.eloDiff > 0 ? 1.0 : 0.4
                }

                // Bottom Right: Negative Change (Subscript)
                Text {
                    anchors.bottom: eloDisplay.bottom
                    anchors.bottomMargin: 6
                    anchors.left: eloDisplay.right
                    anchors.leftMargin: 8
                    text: "-" + (chessRoot.eloDiff < 0 ? Math.abs(chessRoot.eloDiff) : 0)
                    color: Theme.red // Always red as requested
                    font.family: Theme.fontName
                    font.pixelSize: 11
                    font.bold: true
                    opacity: chessRoot.eloDiff < 0 ? 1.0 : 0.4
                }
            }
        }
    }

    // Small Icons Row
    Row {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8; spacing: 6
        
        // Eye Toggle
        Button {
            id: eyeButton
            width: 24; height: 24
            background: Rectangle {
                radius: 6
                color: eyeButton.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
            }
            contentItem: Image {
                source: chessRoot.isShowing ? "../assets/eye-svgrepo-com.svg" : "../assets/eye-slash-svgrepo-com.svg"
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: chessRoot.isShowing ? Theme.sapphire : Theme.subtext0 }
            }
            onClicked: chessRoot.isShowing = !chessRoot.isShowing
        }

        // Refresh Icon
        Button {
            id: refreshBtn
            width: 24; height: 24
            background: Rectangle {
                radius: 6
                color: refreshBtn.hovered ? Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, 0.4) : "transparent"
            }
            contentItem: Text { 
                text: "󰑐"; 
                font.family: "JetBrainsMono Nerd Font"; 
                font.pixelSize: 14; 
                color: refreshBtn.hovered ? Theme.text : Theme.subtext0; 
                horizontalAlignment: Text.AlignHCenter; 
                verticalAlignment: Text.AlignVCenter 

                rotation: 0
                RotationAnimation on rotation {
                    id: rotateAnim
                    from: 0; to: 360; duration: 500; running: false; easing.type: Easing.OutCubic
                }
            }
            onClicked: chessRoot.refresh()
        }
    }
}
