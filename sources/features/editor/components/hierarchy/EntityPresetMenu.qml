import QtQuick
import QtQuick.Controls

// The "Create" menu, grouped like in other engines. The preset ids are applied by
// ProjectEditorPage.applyEntityPreset().
Menu {
    id: root

    signal presetChosen(string preset)

    MenuItem { text: qsTr("Empty object"); onTriggered: root.presetChosen("empty") }

    MenuSeparator {}

    Menu {
        title: qsTr("2D object")

        MenuItem { text: qsTr("Sprite (coloured square)"); onTriggered: root.presetChosen("sprite") }
        // Behind everything, always the size of the window (fill_screen): a sky, a backdrop...
        MenuItem { text: qsTr("Background (fills the window)"); onTriggered: root.presetChosen("background") }
    }

    Menu {
        title: qsTr("Physics")

        MenuItem { text: qsTr("Platform / wall (solid, never moves)"); onTriggered: root.presetChosen("static_platform") }
        MenuItem { text: qsTr("Body (falls, collides)"); onTriggered: root.presetChosen("physics_body") }
        MenuItem { text: qsTr("Trigger zone (reports who enters)"); onTriggered: root.presetChosen("trigger_zone") }
    }
}
