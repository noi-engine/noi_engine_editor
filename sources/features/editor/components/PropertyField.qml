import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

RowLayout {
    id: root

    property string label: ""
    property string value: "0"
    property color accentColor: Theme.grey
    property bool readOnly: false

    signal edited(string newValue)

    spacing: 6

    Rectangle {
        Layout.preferredWidth: 20
        Layout.preferredHeight: 30
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
        Layout.preferredHeight: 30

        topPadding: 0
        bottomPadding: 0
        leftPadding: 8
        rightPadding: 8

        text: root.value
        readOnly: root.readOnly
        opacity: root.readOnly ? 0.55 : 1.0
        font.pixelSize: 12
        color: Theme.white
        selectByMouse: true
        verticalAlignment: TextInput.AlignVCenter

        background: Rectangle {
            radius: 6
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            border.width: 1
        }

        onEditingFinished: {
            if (!root.readOnly && text !== root.value) {
                root.edited(text)
            }
        }
    }
}
