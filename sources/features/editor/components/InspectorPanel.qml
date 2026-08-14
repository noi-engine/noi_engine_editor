import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entity: null

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
                    icon: root.entity && root.entity.type === "camera" ? "camera_alt"
                        : root.entity && root.entity.type === "light" ? "light_mode"
                            : root.entity && root.entity.type === "mesh" ? "view_in_ar"
                                : "folder"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    TextField {
                        Layout.fillWidth: true
                        text: root.entity ? root.entity.name : ""
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.white
                        background: Item {}
                    }

                    Text {
                        text: root.entity ? root.entity.type : ""
                        font.pixelSize: 11
                        color: Theme.grey
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Transform")
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.darkGrey
                }

                Text {
                    text: qsTr("Position")
                    font.pixelSize: 11
                    color: Theme.grey
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PropertyField { Layout.fillWidth: true; label: "X"; accentColor: "#E05B5B" }
                    PropertyField { Layout.fillWidth: true; label: "Y"; accentColor: "#35C98A" }
                    PropertyField { Layout.fillWidth: true; label: "Z"; accentColor: "#4B8CE0" }
                }

                Text {
                    text: qsTr("Rotation")
                    font.pixelSize: 11
                    color: Theme.grey
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PropertyField { Layout.fillWidth: true; label: "X"; accentColor: "#E05B5B" }
                    PropertyField { Layout.fillWidth: true; label: "Y"; accentColor: "#35C98A" }
                    PropertyField { Layout.fillWidth: true; label: "Z"; accentColor: "#4B8CE0" }
                }

                Text {
                    text: qsTr("Scale")
                    font.pixelSize: 11
                    color: Theme.grey
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    PropertyField { Layout.fillWidth: true; label: "X"; value: "1"; accentColor: "#E05B5B" }
                    PropertyField { Layout.fillWidth: true; label: "Y"; value: "1"; accentColor: "#35C98A" }
                    PropertyField { Layout.fillWidth: true; label: "Z"; value: "1"; accentColor: "#4B8CE0" }
                }
            }

            ColumnLayout {
                visible: root.entity && root.entity.type === "mesh"
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Mesh Renderer")
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.darkGrey
                }

                PropertyField {
                    Layout.fillWidth: true
                    label: qsTr("Mesh")
                    value: qsTr("quad.mesh")
                    accentColor: Theme.lightGrey
                }

                PropertyField {
                    Layout.fillWidth: true
                    label: qsTr("Material")
                    value: qsTr("default_material")
                    accentColor: Theme.lightGrey
                }
            }

            ColumnLayout {
                visible: root.entity && root.entity.type === "camera"
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Camera")
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.darkGrey
                }

                PropertyField { Layout.fillWidth: true; label: qsTr("FOV"); value: "45"; accentColor: Theme.lightGrey }
                PropertyField { Layout.fillWidth: true; label: qsTr("Near"); value: "0.1"; accentColor: Theme.lightGrey }
                PropertyField { Layout.fillWidth: true; label: qsTr("Far"); value: "1000"; accentColor: Theme.lightGrey }
            }

            AppButton {
                Layout.fillWidth: true
                Layout.topMargin: 6

                icon: "add_circle"
                text: qsTr("Add Component")
            }

            Item { Layout.preferredHeight: 10 }
        }
    }
}