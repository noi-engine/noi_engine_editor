import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Labelled text input with a hint underneath and an error state.
ColumnLayout {
    id: root

    property string label: ""
    property string hint: ""
    property string error: ""
    property alias text: field.text
    property string placeholderText: ""
    property alias readOnly: field.readOnly
    property alias field: field

    signal accepted()
    signal edited()

    spacing: 4

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.darkGrey
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    TextField {
        id: field
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Theme.white
        selectedTextColor: Theme.black
        selectionColor: Theme.primaryColor
        font.pixelSize: 13
        selectByMouse: true
        leftPadding: 12
        rightPadding: 12
        onAccepted: root.accepted()
        onTextEdited: root.edited()

        // Our own placeholder: the Material one floats up onto the border when focused.
        Text {
            visible: field.text === "" && root.placeholderText !== ""
            anchors.left: parent.left
            anchors.leftMargin: field.leftPadding
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholderText
            color: Theme.grey
            font.pixelSize: field.font.pixelSize
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: Theme.radius
            color: Theme.bgSecondary
            border.width: 1
            border.color: root.error !== "" ? Theme.error : (field.activeFocus ? Theme.primaryColor : Theme.borderColor)
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.error !== "" || root.hint !== ""
        text: root.error !== "" ? root.error : root.hint
        color: root.error !== "" ? Theme.error : Theme.grey
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
