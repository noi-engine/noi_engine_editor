import QtQuick
import QtQuick.Controls

// Ready-made entities, so common objects don't have to be assembled component by component.
// The preset ids are applied by ProjectEditorPage.applyEntityPreset().
Menu {
    id: root

    signal presetChosen(string preset)

    MenuItem { text: qsTr("Empty Entity"); onTriggered: root.presetChosen("empty") }
    MenuSeparator {}
    MenuItem { text: qsTr("Sprite"); onTriggered: root.presetChosen("sprite") }
    MenuItem { text: qsTr("Static Platform"); onTriggered: root.presetChosen("static_platform") }
    MenuItem { text: qsTr("Physics Body"); onTriggered: root.presetChosen("physics_body") }
    MenuSeparator {}
    // Behind everything, always the size of the window (fill_screen): a sky, a backdrop...
    MenuItem { text: qsTr("Background (fills the window)"); onTriggered: root.presetChosen("background") }
}
