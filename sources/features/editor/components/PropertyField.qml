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

    // Numeric validation - all optional. Leave minValue/maxValue as NaN for "no bound".
    // isNumeric enables a validator at all (plain string fields should leave this false).
    property bool isNumeric: false
    property bool integerValue: false
    property real minValue: NaN
    property real maxValue: NaN

    // True while the field holds text a validator would reject/that's out of range - the
    // caller can style around this (e.g. a red border) instead of silently clamping every
    // keystroke, which fights the user mid-typing.
    readonly property bool hasInvalidInput: field.acceptableInput === false

    signal edited(string newValue)

    // Clamps to [minValue, maxValue] (whichever bounds are finite) and rounds to an integer
    // when integerValue is set. Applied on commit, not on every keystroke.
    function clampNumeric(raw) {
        let n = parseFloat(raw)
        if (isNaN(n)) return root.value
        if (root.integerValue) n = Math.round(n)
        if (!isNaN(root.minValue)) n = Math.max(root.minValue, n)
        if (!isNaN(root.maxValue)) n = Math.min(root.maxValue, n)
        return String(n)
    }

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
        id: field
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

        validator: root.isNumeric
            ? (root.integerValue
                ? intValidator
                : doubleValidator)
            : null

        IntValidator {
            id: intValidator
            bottom: isNaN(root.minValue) ? -2147483647 : root.minValue
            top: isNaN(root.maxValue) ? 2147483647 : root.maxValue
        }

        DoubleValidator {
            id: doubleValidator
            bottom: isNaN(root.minValue) ? -Number.MAX_VALUE : root.minValue
            top: isNaN(root.maxValue) ? Number.MAX_VALUE : root.maxValue
            notation: DoubleValidator.StandardNotation
        }

        background: Rectangle {
            radius: 6
            color: Theme.bgTertiary
            border.color: field.acceptableInput ? Theme.borderColor : Theme.error
            border.width: 1
        }

        onEditingFinished: {
            if (root.readOnly) return
            const committed = root.isNumeric ? root.clampNumeric(text) : text
            if (committed !== root.value) {
                root.edited(committed)
            } else if (committed !== text) {
                text = committed // revert visible text if clamping changed nothing semantically
            }
        }
    }
}
