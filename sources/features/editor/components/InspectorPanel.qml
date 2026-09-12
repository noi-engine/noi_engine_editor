import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entity: null
    property var componentsData: []

    signal propertyEdited(string componentType, string propertyName, string propertyType, var value)

    color: Theme.bgSecondary

    Rectangle {
        anchors.left: parent.left
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    EmptyState {
        visible: !root.entity

        anchors.centerIn: parent
        width: parent.width - 24

        icon: "ads_click"
        title: qsTr("No Selection")
        description: qsTr("Select an entity in the hierarchy to inspect its properties.")
    }

    Flickable {
        visible: root.entity !== null

        anchors.fill: parent
        anchors.margins: 14

        contentWidth: width
        contentHeight: column.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column

            width: parent.width
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                IconBadge {
                    icon: "category"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.entity ? (root.entity.name !== "" ? root.entity.name : ("Entity #" + root.entity.id)) : ""
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.white
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.entity ? qsTr("#%1 / gen %2").arg(root.entity.id).arg(root.entity.generation) : ""
                        font.pixelSize: 11
                        color: Theme.grey
                    }
                }
            }

            Repeater {
                model: root.componentsData

                delegate: ColumnLayout {
                    id: componentSection

                    required property var modelData
                    readonly property string componentType: componentSection.modelData.type
                    readonly property var componentProperties: componentSection.modelData.properties

                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: componentSection.componentType.toUpperCase()
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.darkGrey
                    }

                    Repeater {
                        model: componentSection.componentProperties

                        delegate: Item {
                            id: propRow

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: propColumn.implicitHeight

                            ColumnLayout {
                                id: propColumn
                                width: parent.width
                                spacing: 4

                                Text {
                                    visible: propRow.modelData.type !== "bool"
                                    text: propRow.modelData.name
                                    font.pixelSize: 9
                                    color: Theme.grey
                                }

                                RowLayout {
                                    visible: propRow.modelData.type === "vec3"
                                    Layout.fillWidth: true
                                    spacing: 6

                                    PropertyField {
                                        Layout.fillWidth: true
                                        label: "X"
                                        accentColor: "#E05B5B"
                                        readOnly: propRow.modelData.readOnly
                                        value: Number(propRow.modelData.value[0]).toFixed(2)
                                        onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                            [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2]])
                                    }
                                    PropertyField {
                                        Layout.fillWidth: true
                                        label: "Y"
                                        accentColor: "#35C98A"
                                        readOnly: propRow.modelData.readOnly
                                        value: Number(propRow.modelData.value[1]).toFixed(2)
                                        onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                            [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2]])
                                    }
                                    PropertyField {
                                        Layout.fillWidth: true
                                        label: "Z"
                                        accentColor: "#4B8CE0"
                                        readOnly: propRow.modelData.readOnly
                                        value: Number(propRow.modelData.value[2]).toFixed(2)
                                        onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                            [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v)])
                                    }
                                }

                                PropertyField {
                                    visible: propRow.modelData.type === "float" || propRow.modelData.type === "string"
                                    Layout.fillWidth: true
                                    label: propRow.modelData.name.substring(0, 1).toUpperCase()
                                    accentColor: Theme.lightGrey
                                    readOnly: propRow.modelData.readOnly
                                    value: propRow.modelData.type === "float"
                                        ? Number(propRow.modelData.value).toFixed(3)
                                        : String(propRow.modelData.value)
                                    onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name,
                                        propRow.modelData.type, propRow.modelData.type === "float" ? parseFloat(v) : v)
                                }

                                RowLayout {
                                    visible: propRow.modelData.type === "bool"
                                    Layout.fillWidth: true
                                    spacing: 8

                                    CheckBox {
                                        checked: !!propRow.modelData.value
                                        enabled: !propRow.modelData.readOnly
                                        onToggled: root.propertyEdited(componentSection.componentType, propRow.modelData.name, "bool", checked)
                                    }
                                    Text {
                                        text: propRow.modelData.name
                                        font.pixelSize: 11
                                        color: Theme.darkGrey
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: componentSection.componentProperties.length === 0
                        text: qsTr("No editable fields")
                        font.pixelSize: 10
                        font.italic: true
                        color: Theme.grey
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }
}
