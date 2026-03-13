pragma Singleton
import QtQuick

QtObject {
    property string trackName: ""
    property string artistName: ""
    property string artUrl: ""
    property bool isPlaying: false
    property point pos: Qt.point(0, 0)

    // Progress properties
    property real position: 0.0
    property real length: 0.0
    property bool shuffle: false
    property string loopStatus: "None"

    property bool widgetHovered: false
    property bool popupHovered: false

    // Derived property: Stay open if either is hovered or if we're in the grace period
    readonly property bool shouldBeVisible: widgetHovered || popupHovered || hideTimer.running

    function show(track, artist, art, playing, item) {
        if (!item) return;
        const globalPos = item.mapToGlobal(Qt.point(item.width / 2, item.height));
        trackName = track;
        artistName = artist;
        artUrl = art;
        isPlaying = playing;
        pos = globalPos;
        widgetHovered = true;
        hideTimer.stop();
    }

    function hide() {
        widgetHovered = false;
        hideTimer.start();
    }

    property Timer hideTimer: Timer {
        interval: 300 // Grace period to move mouse to popup
        onTriggered: {
            if (!widgetHovered && !popupHovered) {
                // Fully close
            }
        }
    }
}
