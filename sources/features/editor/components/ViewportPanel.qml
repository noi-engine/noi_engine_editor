import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    property var selectedEntity: null
    property int activeTool: 0

    color: Theme.black

    Text {
        anchors.centerIn: parent
        text: qsTr("Viewport rendering will appear here")
        font.pixelSize: 13
        color: Theme.lightGrey
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 12

        width: toolRow.implicitWidth + 12
        height: 40
        radius: 10
        color: Theme.bgSecondary
        border.color: Theme.borderColor
        border.width: 1

        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: [
                    { icon: "near_me", tip: qsTr("Select") },
                    { icon: "open_with", tip: qsTr("Move") },
                    { icon: "sync", tip: qsTr("Rotate") },
                    { icon: "aspect_ratio", tip: qsTr("Scale") }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: 30
                    height: 30
                    radius: 7

                    color: root.activeTool === index ? Theme.primaryLightC : "transparent"

                    MuiIcon {
                        anchors.centerIn: parent
                        name: modelData.icon
                        font.pixelSize: 16
                        color: root.activeTool === index ? Theme.primaryColor : Theme.grey
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTool = index
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12

        width: statCol.implicitWidth + 20
        height: statCol.implicitHeight + 14
        radius: 10
        color: Theme.bgSecondary
        border.color: Theme.borderColor
        border.width: 1

        ColumnLayout {
            id: statCol
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: qsTr("60 FPS")
                font.pixelSize: 11
                color: Theme.darkGrey
            }

            Text {
                text: qsTr("Selected: %1").arg(root.selectedEntity ? root.selectedEntity.name : qsTr("None"))
                font.pixelSize: 11
                color: Theme.grey
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 26
        color: Theme.bgSecondary

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Theme.borderColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                text: qsTr("3D View")
                font.pixelSize: 10
                color: Theme.grey
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Grid Snap: Off")
                font.pixelSize: 10
                color: Theme.grey
            }
        }
    }
}