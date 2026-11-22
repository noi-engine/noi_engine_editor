pragma Singleton

import QtQuick

QtObject {
    // ---- Surfaces: near-black with a green tint, three elevations.
    readonly property color bgPrimary: "#0A0E0C"      // app background
    readonly property color bgSecondary: "#111713"    // panels, cards
    readonly property color bgTertiary: "#18201B"     // raised: hover, inputs, menus
    readonly property color bgElevated: "#1E2822"     // popovers, selected rows

    readonly property color borderColor: "#202B25"
    readonly property color borderStrong: "#2D3B33"

    // ---- Accent: mint to teal.
    readonly property color primaryColor: "#3DDC97"
    readonly property color primaryDark: "#26B27A"
    readonly property color primaryLightA: "#7BEBB8"
    readonly property color primaryLightB: "#14392A"
    readonly property color primaryLightC: "#12291F"

    readonly property color gradientStart: "#3DDC97"
    readonly property color gradientEnd: "#2BC4C0"

    // ---- Text and greys.
    readonly property color black: "#06100B"
    readonly property color darkGrey: "#A4B2AA"
    readonly property color grey: "#76847C"
    readonly property color lightGrey: "#4A5851"
    readonly property color white: "#F3F8F5"

    readonly property color success: "#3DDC97"
    readonly property color warning: "#F0B455"
    readonly property color error: "#EF6B6B"

    // Soft glow / shadow colours for the fake drop shadows of cards.
    readonly property color glow: Qt.rgba(0.24, 0.86, 0.59, 0.18)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.45)

    // Spacing and corner radii shared by every component.
    readonly property int spacingSmall: 8
    readonly property int spacing: 14
    readonly property int spacingLarge: 20
    readonly property int radius: 12
    readonly property int radiusLarge: 20

    function darker(color) {
        return Qt.darker(color, 1.2)
    }

    function lighter(color) {
        return Qt.lighter(color, 1.2)
    }
}