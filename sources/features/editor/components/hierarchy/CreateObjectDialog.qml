import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// "Create object": pick the kind of object to add to the scene, with a search field, like the
// Create Node window of other engines. The preset ids are applied by
// ProjectEditorPage.applyEntityPreset().
AppDialog {
    id: root

    signal presetChosen(string preset)

    title: qsTr("Create an object")
    subtitle: qsTr("Pick what to add to the scene. You can change everything afterwards in the Inspector.")
    icon: "add_circle"
    preferredWidth: 520

    readonly property var kinds: [
        { id: "empty", group: qsTr("General"), icon: "radio_button_unchecked", name: qsTr("Empty object"), text: qsTr("Nothing but a position. Add the components you need.") },
        { id: "sprite", group: qsTr("2D"), icon: "image", name: qsTr("Sprite"), text: qsTr("A coloured rectangle. Switch it to an image in the Inspector, or drag an image from Project into the scene.") },
        { id: "background", group: qsTr("2D"), icon: "wallpaper", name: qsTr("Background"), text: qsTr("Fills the whole window, behind everything: a sky, a backdrop.") },
        { id: "static_platform", group: qsTr("Physics"), icon: "crop_square", name: qsTr("Platform / wall"), text: qsTr("Solid, never moves. Other things stand on it or bump into it.") },
        { id: "physics_body", group: qsTr("Physics"), icon: "sports_basketball", name: qsTr("Body"), text: qsTr("Falls with gravity and collides with solid things.") },
        { id: "trigger_zone", group: qsTr("Physics"), icon: "crop_free", name: qsTr("Trigger zone"), text: qsTr("Invisible area: tells your scripts when something enters it (coins, doors, damage).") }
    ]

    property string query: ""
    property int currentIndex: 0

    readonly property var shown: kinds.filter(k => query.trim() === ""
        || k.name.toLowerCase().indexOf(query.trim().toLowerCase()) >= 0
        || k.text.toLowerCase().indexOf(query.trim().toLowerCase()) >= 0
        || k.group.toLowerCase().indexOf(query.trim().toLowerCase()) >= 0)

    onAboutToShow: { query = ""; currentIndex = 0; search.text = ""; }
    onOpened: search.field.forceActiveFocus()

    function choose(index) {
        if (index < 0 || index >= shown.length) return;
        presetChosen(shown[index].id);
        close();
    }

    AppTextField {
        id: search
        Layout.fillWidth: true
        placeholderText: qsTr("Search: sprite, platform, trigger…")
        onEdited: { root.query = text; root.currentIndex = 0; }
        onAccepted: root.choose(root.currentIndex)
        field.Keys.onDownPressed: root.currentIndex = Math.min(root.shown.length - 1, root.currentIndex + 1)
        field.Keys.onUpPressed: root.currentIndex = Math.max(0, root.currentIndex - 1)
    }

    Repeater {
        model: root.shown

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: root.currentIndex === index

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + 20
            radius: Theme.radius
            color: current ? Theme.primaryLightB : (area.containsMouse ? Theme.bgTertiary : Theme.bgSecondary)
            border.color: current ? Theme.primaryColor : Theme.borderColor

            RowLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 8
                    color: Theme.bgPrimary

                    MuiIcon {
                        anchors.centerIn: parent
                        name: row.modelData.icon
                        font.pixelSize: 22
                        color: Theme.primaryColor
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        spacing: 8

                        Text {
                            text: row.modelData.name
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: Theme.white
                        }

                        Text {
                            text: row.modelData.group
                            font.pixelSize: 10
                            color: Theme.lightGrey
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.text
                        font.pixelSize: 12
                        color: Theme.darkGrey
                        wrapMode: Text.WordWrap
                    }
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentIndex = row.index
                onDoubleClicked: root.choose(row.index)
            }
        }
    }

    Text {
        visible: root.shown.length === 0
        Layout.fillWidth: true
        text: qsTr("Nothing matches “%1”.").arg(root.query)
        color: Theme.grey
        font.pixelSize: 13
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        AppButton {
            primary: true
            icon: "add"
            text: qsTr("Create")
            enabled: root.shown.length > 0
            onClicked: root.choose(root.currentIndex)
        }
    ]
}
