import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// A message that stays in the layout: what happened and, when there is one, what to do.
// kind: "info" | "success" | "warning" | "error"
Rectangle {
    id: root

    property string kind: "info"
    property string text: ""
    property string title: ""
    property string actionText: ""
    property bool closable: false

    signal actionTriggered()
    signal closed()

    readonly property color accent: kind === "error" ? Theme.error
        : kind === "warning" ? Theme.warning
        : kind === "success" ? Theme.success
        : Theme.primaryLightA

    visible: text !== "" || title !== ""
    implicitHeight: row.implicitHeight + 20
    radius: Theme.radius
    color: Qt.rgba(accent.r, accent.g, accent.b, 0.10)
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.45)
    border.width: 1

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        MuiIcon {
            Layout.alignment: Qt.AlignTop
            name: root.kind === "error" ? "error" : root.kind === "warning" ? "warning"
                : root.kind === "success" ? "check_circle" : "info"
            font.pixelSize: 18
            color: root.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                visible: root.title !== ""
                text: root.title
                color: Theme.white
                font.bold: true
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: root.text !== ""
                text: root.text
                color: Theme.darkGrey
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        AppButton {
            visible: root.actionText !== ""
            text: root.actionText
            onClicked: root.actionTriggered()
        }

        MuiIcon {
            visible: root.closable
            name: "close"
            font.pixelSize: 16
            color: Theme.grey

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closed()
            }
        }
    }
}
