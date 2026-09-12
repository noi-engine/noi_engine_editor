import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entity: null
    property var componentsData: []
    property var loadedResources: []

    signal propertyEdited(string componentType, string propertyName, string propertyType, var value)
    signal componentAddRequested(string componentType)

    readonly property var allComponentTypes: [
        "transform", "camera_2d", "camera_3d", "orbit_camera", "render_layer",
        "name_component", "mesh_renderer", "mesh_renderer_properties", "script_component"
    ]

    function resourceLabelsFor(resourceType) {
        const items = root.loadedResources || [];
        const labels = [""];
        for (let i = 0; i < items.length; i++) {
            if (items[i].type === resourceType) {
                labels.push(items[i].label);
            }
        }
        return labels;
    }

    function missingComponentTypes() {
        const present = (root.componentsData || []).map(c => c.type);
        return root.allComponentTypes.filter(t => present.indexOf(t) === -1);
    }

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
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
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

                delegate: Rectangle {
                    id: componentSection

                    required property var modelData
                    readonly property string componentType: componentSection.modelData.type
                    readonly property var componentProperties: componentSection.modelData.properties

                    Layout.fillWidth: true
                    implicitHeight: cardColumn.implicitHeight + 24
                    radius: 8
                    color: Theme.bgTertiary
                    border.color: Theme.borderColor
                    border.width: 1

                    ColumnLayout {
                        id: cardColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            text: componentSection.componentType.toUpperCase()
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            color: Theme.primaryColor
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
                                    spacing: 6

                                    Text {
                                        visible: propRow.modelData.type !== "bool"
                                        text: propRow.modelData.name
                                        font.pixelSize: 10
                                        color: Theme.darkGrey
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

                                    RowLayout {
                                        visible: propRow.modelData.type === "vec4"
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Rectangle {
                                            Layout.preferredWidth: 26
                                            Layout.preferredHeight: 26
                                            radius: 6
                                            border.color: Theme.borderColor
                                            border.width: 1
                                            color: Qt.rgba(propRow.modelData.value[0], propRow.modelData.value[1],
                                                            propRow.modelData.value[2], propRow.modelData.value[3])
                                        }

                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "R"
                                            accentColor: "#E05B5B"
                                            readOnly: propRow.modelData.readOnly
                                            value: Number(propRow.modelData.value[0]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2], propRow.modelData.value[3]])
                                        }
                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "G"
                                            accentColor: "#35C98A"
                                            readOnly: propRow.modelData.readOnly
                                            value: Number(propRow.modelData.value[1]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2], propRow.modelData.value[3]])
                                        }
                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "B"
                                            accentColor: "#4B8CE0"
                                            readOnly: propRow.modelData.readOnly
                                            value: Number(propRow.modelData.value[2]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v), propRow.modelData.value[3]])
                                        }
                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "A"
                                            accentColor: Theme.lightGrey
                                            readOnly: propRow.modelData.readOnly
                                            value: Number(propRow.modelData.value[3]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                [propRow.modelData.value[0], propRow.modelData.value[1], propRow.modelData.value[2], parseFloat(v)])
                                        }
                                    }

                                    ComboBox {
                                        id: resourceCombo
                                        visible: propRow.modelData.type === "resourceRef"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        enabled: !propRow.modelData.readOnly

                                        model: root.resourceLabelsFor(propRow.modelData.resourceType)
                                        displayText: currentText !== "" ? currentText : qsTr("(none)")

                                        Component.onCompleted: currentIndex = find(propRow.modelData.value)

                                        onActivated: (index) => root.propertyEdited(componentSection.componentType,
                                            propRow.modelData.name, "resourceRef", textAt(index))

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
            }

            AppButton {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.entity !== null && root.missingComponentTypes().length > 0

                icon: "add_circle"
                text: qsTr("Add Component")

                onClicked: addComponentMenu.open()

                Menu {
                    id: addComponentMenu
                    y: parent.height

                    background: Rectangle {
                        implicitWidth: 200
                        color: Theme.bgTertiary
                        border.color: Theme.borderColor
                        border.width: 1
                        radius: 6
                    }

                    Repeater {
                        model: root.missingComponentTypes()

                        delegate: MenuItem {
                            id: addComponentMenuItem
                            required property string modelData

                            text: addComponentMenuItem.modelData
                            width: addComponentMenu.width

                            contentItem: Text {
                                text: addComponentMenuItem.modelData
                                font.pixelSize: 12
                                color: Theme.white
                                leftPadding: 8
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: addComponentMenuItem.highlighted ? Theme.primaryLightC : "transparent"
                            }

                            onTriggered: root.componentAddRequested(addComponentMenuItem.modelData)
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }
}
