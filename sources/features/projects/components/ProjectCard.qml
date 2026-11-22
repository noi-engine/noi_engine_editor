import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// One project of the home grid: a generated cover (colour from the name), the name, where it
// lives and when it was opened. Hover lifts it and shows the way in.
Item {
    id: root

    required property string projectName
    required property string projectPath
    required property string projectDate

    signal clicked()
    signal removeRequested()

    implicitHeight: 196

    // A stable hue per project so each one is recognisable at a glance.
    readonly property real hue: {
        let h = 0;
        for (let i = 0; i < projectName.length; ++i) h = (h * 31 + projectName.charCodeAt(i)) % 360;
        return h / 360;
    }

    readonly property bool hovered: area.containsMouse || removeArea.containsMouse

    Card {
        id: card
        anchors.fill: parent
        anchors.topMargin: root.hovered ? 0 : 3
        anchors.bottomMargin: root.hovered ? 3 : 0
        interactive: true
        hovered: root.hovered
        clip: true
        Behavior on anchors.topMargin { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Cover
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.hsla(root.hue, 0.42, 0.27, 1) }
                    GradientStop { position: 1; color: Qt.hsla((root.hue + 0.1) % 1, 0.5, 0.16, 1) }
                }

                // Soft shapes, so the cover isn't a flat gradient.
                Rectangle {
                    width: 120; height: 120; radius: 60
                    x: parent.width - 80; y: -40
                    color: Qt.hsla((root.hue + 0.08) % 1, 0.7, 0.55, 0.18)
                }
                Rectangle {
                    width: 70; height: 70; radius: 35
                    x: -20; y: parent.height - 30
                    color: Qt.hsla(root.hue, 0.7, 0.6, 0.14)
                }

                Text {
                    anchors.centerIn: parent
                    text: root.projectName.length > 0 ? root.projectName.charAt(0).toUpperCase() : "?"
                    font.pixelSize: 54
                    font.weight: Font.Black
                    color: Qt.rgba(1, 1, 1, 0.9)
                }

                // Remove from the list (the files stay where they are).
                Rectangle {
                    visible: root.hovered
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 8
                    width: 26; height: 26; radius: 13
                    color: removeArea.containsMouse ? Theme.error : Qt.rgba(0, 0, 0, 0.45)

                    MuiIcon {
                        anchors.centerIn: parent
                        name: "close"
                        font.pixelSize: 15
                        color: Theme.white
                    }

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeRequested()
                    }

                    ToolTip { visible: removeArea.containsMouse; delay: 400; text: qsTr("Remove from this list (keeps the files)") }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 14
                Layout.topMargin: 11
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.projectName
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Theme.white
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.projectPath
                    font.pixelSize: 11
                    color: Theme.grey
                    elide: Text.ElideMiddle
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: root.projectDate !== "" ? qsTr("Opened %1").arg(root.projectDate) : qsTr("Never opened")
                        font.pixelSize: 11
                        color: Theme.grey
                        elide: Text.ElideRight
                    }

                    Text {
                        text: qsTr("Open")
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.primaryColor
                        opacity: root.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    MuiIcon {
                        name: "arrow_forward"
                        font.pixelSize: 15
                        color: Theme.primaryColor
                        opacity: root.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: root.clicked()
    }
}
