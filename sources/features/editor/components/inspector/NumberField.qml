import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// A labelled number box for the Inspector's simple sections. Shows `value`, reports the typed
// number when the field is left or Enter is pressed.
ColumnLayout {
    id: root

    property string label: ""
    property real value: 0
    property int decimals: 2
    property string suffix: ""

    // "12.50" -> "12.5", "100" stays "100" (only decimals are trimmed).
    function format(number) {
        const text = Number(number).toFixed(root.decimals);
        return text.indexOf(".") >= 0 ? text.replace(/\.?0+$/, "") : text;
    }

    signal edited(real number)

    spacing: 2
    Layout.fillWidth: true

    Text {
        visible: root.label !== ""
        text: root.label
        font.pixelSize: 10
        color: Theme.grey
    }

    TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: 32
        font.pixelSize: 12
        color: Theme.white
        selectByMouse: true
        selectionColor: Theme.primaryColor
        selectedTextColor: Theme.black
        validator: DoubleValidator { notation: DoubleValidator.StandardNotation; locale: "C" }
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        leftPadding: 8
        rightPadding: root.suffix !== "" ? 26 : 8

        // Follows the value unless the user is typing.
        text: root.format(root.value)

        onEditingFinished: {
            const number = parseFloat(text.replace(",", "."));
            if (!isNaN(number) && Math.abs(number - root.value) > 1e-9) root.edited(number);
            // Typing replaced the binding: follow the value again.
            text = Qt.binding(() => root.format(root.value));
        }

        background: Rectangle {
            radius: 8
            color: Theme.bgPrimary
            border.width: 1
            border.color: field.activeFocus ? Theme.primaryColor : Theme.borderColor
        }

        Text {
            visible: root.suffix !== ""
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.suffix
            font.pixelSize: 10
            color: Theme.grey
        }
    }
}
