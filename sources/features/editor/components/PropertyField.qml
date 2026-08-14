import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

RowLayout {
    id: root

    property string label: ""
    property string value: "0"
    property color accentColor: Theme.grey

    spacing: 6

    Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 26
        radius: 6
        color: root.accentColor

        Text {
            anchors.centerIn: parent
            text: root.label
            font.pixelSize: 10
            font.weight: Font.Bold
            color: Theme.black
        }
    }

    TextField {
        Layout.fillWidth: true
        Layout.preferredHeight: 26

        text: root.value
        font.pixelSize: 12
        color: Theme.white

        background: Rectangle {
            radius: 6
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            border.width: 1
        }
    }
}