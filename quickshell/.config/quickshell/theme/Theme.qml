pragma Singleton
import QtQuick

QtObject {
    // Catppuccin Mocha Palette
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"

    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"

    readonly property color blue: "#8caaee"
    readonly property color lavender: "#b4befe"
    readonly property color sapphire: "#85c1dc"
    readonly property color sky: "#99d1db"
    readonly property color teal: "#81c8be"
    readonly property color green: "#a6d189"
    readonly property color yellow: "#e5c890"
    readonly property color peach: "#ef9f76"
    readonly property color maroon: "#ea999c"
    readonly property color red: "#e78284"
    readonly property color mauve: "#ca9ee6"
    readonly property color pink: "#f4b8e4"
    readonly property color flamingo: "#f2ce00"
    readonly property color rosewater: "#f2d5cf"

    // UI Globals
    readonly property int radius: 12
    readonly property int borderWidth: 1
    readonly property color borderColor: surface0
    
    readonly property string fontName: "JetBrains Mono"
    readonly property int fontSize: 11

    // Animations
    readonly property int animDuration: 300
    readonly property var animEasing: Easing.OutQuint
}
