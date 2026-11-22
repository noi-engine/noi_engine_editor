import QtQuick

import noi_engine_editor

// A surface: rounded, hairline border, optional hover lift. The base of every panel and tile.
Rectangle {
    id: root

    property bool interactive: false
    property bool selected: false
    property bool hovered: false
    property color accent: Theme.primaryColor

    radius: Theme.radius
    color: selected ? Theme.primaryLightC : (hovered && interactive ? Theme.bgTertiary : Theme.bgSecondary)
    border.width: 1
    border.color: selected ? Qt.rgba(accent.r, accent.g, accent.b, 0.7)
                  : (hovered && interactive ? Theme.borderStrong : Theme.borderColor)

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
}
