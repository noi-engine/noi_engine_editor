import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// One property of a component (or material) in the Inspector, with the editor matching its type.
Item {
    id: propRow

    required property var modelData
    property var inspector
    property string componentType: ""
    property bool sectionReadOnly: false

    readonly property bool effectiveReadOnly: propRow.modelData.readOnly || propRow.sectionReadOnly

    Layout.fillWidth: true
    implicitHeight: propColumn.implicitHeight

    ColumnLayout {
        id: propColumn
        width: parent.width
        spacing: 6

        RowLayout {
            visible: propRow.modelData.type !== "bool" && propRow.modelData.type !== "vec4"
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: propRow.inspector.displayName(propRow.modelData.name)
                font.pixelSize: 10
                color: Theme.darkGrey
            }

            MuiIcon {
                name: "delete"
                font.pixelSize: 12
                color: Theme.grey
                visible: propRow.inspector.supportsAddProperty(propRow.componentType)
                    && propRow.inspector.isDynamicProperty(propRow.modelData.name)
                    && !propRow.effectiveReadOnly

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: propRow.inspector.propertyRemoved(propRow.componentType, propRow.modelData.name)
                }
            }
        }

        RowLayout {
            visible: propRow.modelData.type === "vec3"
            Layout.fillWidth: true
            spacing: 6

            PropertyField {
                Layout.fillWidth: true
                label: "X"
                accentColor: "#E05B5B"
                readOnly: propRow.effectiveReadOnly
                isNumeric: true
                value: Number(propRow.modelData.value[0]).toFixed(2)
                onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec3",
                    [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2]])
            }
            PropertyField {
                Layout.fillWidth: true
                label: "Y"
                accentColor: "#35C98A"
                readOnly: propRow.effectiveReadOnly
                isNumeric: true
                value: Number(propRow.modelData.value[1]).toFixed(2)
                onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec3",
                    [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2]])
            }
            PropertyField {
                Layout.fillWidth: true
                label: "Z"
                accentColor: "#4B8CE0"
                readOnly: propRow.effectiveReadOnly
                isNumeric: true
                value: Number(propRow.modelData.value[2]).toFixed(2)
                onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec3",
                    [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v)])
            }
        }

        // Color (vec4): swatch + stripped name on their own row, RGBA fields
        // on a second full-width row - packing swatch+4 fields into one row
        // left each TextField too narrow to show its value.
        ColumnLayout {
            visible: propRow.modelData.type === "vec4"
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 8
                    border.color: Theme.borderColor
                    border.width: 1
                    color: propRow.modelData.type === "vec4"
                        ? Qt.rgba(propRow.modelData.value[0], propRow.modelData.value[1],
                                  propRow.modelData.value[2], propRow.modelData.value[3])
                        : "transparent"
                }

                Text {
                    Layout.fillWidth: true
                    text: propRow.inspector.displayName(propRow.modelData.name)
                    font.pixelSize: 11
                    color: Theme.darkGrey
                    elide: Text.ElideRight
                }

                MuiIcon {
                    name: "delete"
                    font.pixelSize: 12
                    color: Theme.grey
                    visible: propRow.inspector.supportsAddProperty(propRow.componentType)
                        && propRow.inspector.isDynamicProperty(propRow.modelData.name)
                        && !propRow.effectiveReadOnly

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: propRow.inspector.propertyRemoved(propRow.componentType, propRow.modelData.name)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                PropertyField {
                    Layout.fillWidth: true
                    label: "R"
                    accentColor: "#E05B5B"
                    readOnly: propRow.effectiveReadOnly
                    isNumeric: true
                    minValue: 0
                    maxValue: 1
                    value: Number(propRow.modelData.value[0]).toFixed(2)
                    onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec4",
                        [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2], propRow.modelData.value[3]])
                }
                PropertyField {
                    Layout.fillWidth: true
                    label: "G"
                    accentColor: "#35C98A"
                    readOnly: propRow.effectiveReadOnly
                    isNumeric: true
                    minValue: 0
                    maxValue: 1
                    value: Number(propRow.modelData.value[1]).toFixed(2)
                    onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec4",
                        [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2], propRow.modelData.value[3]])
                }
                PropertyField {
                    Layout.fillWidth: true
                    label: "B"
                    accentColor: "#4B8CE0"
                    readOnly: propRow.effectiveReadOnly
                    isNumeric: true
                    minValue: 0
                    maxValue: 1
                    value: Number(propRow.modelData.value[2]).toFixed(2)
                    onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec4",
                        [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v), propRow.modelData.value[3]])
                }
                PropertyField {
                    Layout.fillWidth: true
                    label: "A"
                    accentColor: Theme.lightGrey
                    readOnly: propRow.effectiveReadOnly
                    isNumeric: true
                    minValue: 0
                    maxValue: 1
                    value: Number(propRow.modelData.value[3]).toFixed(2)
                    onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "vec4",
                        [propRow.modelData.value[0], propRow.modelData.value[1], propRow.modelData.value[2], parseFloat(v)])
                }
            }
        }

        ComboBox {
            id: resourceCombo
            visible: propRow.modelData.type === "resourceRef"
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            enabled: !propRow.effectiveReadOnly

            model: propRow.inspector.resourceLabelsFor(propRow.modelData.resourceType)
            displayText: currentText !== "" ? currentText : qsTr("(none)")

            Component.onCompleted: currentIndex = find(propRow.modelData.value)

            onActivated: (index) => propRow.inspector.resourceRefChosen(propRow.componentType,
                propRow.modelData.name, textAt(index), () => resourceCombo.currentIndex = resourceCombo.find(propRow.modelData.value))

            background: Rectangle {
                radius: 6
                color: Theme.bgPrimary
                border.color: resourceCombo.activeFocus ? Theme.primaryColor : Theme.borderColor
                border.width: 1
            }

            contentItem: Text {
                leftPadding: 10
                rightPadding: 24
                text: resourceCombo.displayText
                font.pixelSize: 12
                font.italic: resourceCombo.currentText === ""
                color: resourceCombo.enabled ? (resourceCombo.currentText !== "" ? Theme.white : Theme.grey) : Theme.lightGrey
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            indicator: MuiIcon {
                x: resourceCombo.width - width - 8
                y: (resourceCombo.height - height) / 2
                name: "expand_more"
                font.pixelSize: 16
                color: Theme.grey
            }

            popup.background: Rectangle {
                color: Theme.bgTertiary
                border.color: Theme.borderColor
                border.width: 1
                radius: 6
            }

            delegate: ItemDelegate {
                width: resourceCombo.width
                highlighted: resourceCombo.highlightedIndex === index

                contentItem: Text {
                    text: modelData !== "" ? modelData : qsTr("(none)")
                    font.pixelSize: 12
                    font.italic: modelData === ""
                    color: Theme.white
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: highlighted ? Theme.primaryLightC : "transparent"
                }
            }

            MouseArea {
                // ComboBox changes its value on mouse wheel by default (Qt Quick
                // Controls' QQuickComboBox::wheelEvent), which fires just from
                // scrolling the Inspector past it - not what a "click to pick a
                // value" control should do. acceptedButtons: Qt.NoButton makes
                // this MouseArea ignore presses (they fall through to the
                // ComboBox underneath, so clicking still opens it normally) while
                // still intercepting - and swallowing - wheel events.
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: (wheel) => wheel.accepted = true
            }
        }

        PropertyField {
            visible: propRow.modelData.type === "float" || propRow.modelData.type === "string"
            Layout.fillWidth: true
            label: propRow.inspector.displayName(propRow.modelData.name).substring(0, 1).toUpperCase()
            accentColor: Theme.lightGrey
            readOnly: propRow.effectiveReadOnly
            isNumeric: propRow.modelData.type === "float"
            integerValue: propRow.modelData.type === "float"
                && !!propRow.inspector.constraintFor(propRow.componentType, propRow.modelData.name).integer
            minValue: propRow.modelData.type === "float"
                ? (propRow.inspector.constraintFor(propRow.componentType, propRow.modelData.name).min ?? NaN)
                : NaN
            maxValue: propRow.modelData.type === "float"
                ? (propRow.inspector.constraintFor(propRow.componentType, propRow.modelData.name).max ?? NaN)
                : NaN
            value: propRow.modelData.type === "float"
                ? (integerValue ? String(Math.round(propRow.modelData.value)) : Number(propRow.modelData.value).toFixed(3))
                : String(propRow.modelData.value)
            onEdited: (v) => propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name,
                propRow.modelData.type, propRow.modelData.type === "float" ? parseFloat(v) : v)
        }

        RowLayout {
            visible: propRow.modelData.type === "bool"
            Layout.fillWidth: true
            spacing: 8

            CheckBox {
                checked: !!propRow.modelData.value
                enabled: !propRow.effectiveReadOnly
                onToggled: propRow.inspector.propertyEdited(propRow.componentType, propRow.modelData.name, "bool", checked)
            }
            Text {
                text: propRow.inspector.displayName(propRow.modelData.name)
                font.pixelSize: 11
                color: Theme.darkGrey
            }
        }
    }
}
