import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Dialog {
    id: root

    title: qsTr("Project Settings")
    modal: true
    anchors.centerIn: parent
    width: 460
    standardButtons: Dialog.Close

    ColumnLayout {
        width: parent.width
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Project Name")
                font.pixelSize: 12
                color: Theme.darkGrey
            }

            TextField {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: CurrentProjectManager.name
                readOnly: true
                color: Theme.white
                font.pixelSize: 13

                background: Rectangle {
                    radius: 8
                    color: Theme.bgTertiary
                    border.color: Theme.borderColor
                    border.width: 1
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Project Path")
                font.pixelSize: 12
                color: Theme.darkGrey
            }

            TextField {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: CurrentProjectManager.path
                readOnly: true
                color: Theme.white
                font.pixelSize: 12

                background: Rectangle {
                    radius: 8
                    color: Theme.bgTertiary
                    border.color: Theme.borderColor
                    border.width: 1
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Target Platform")
                font.pixelSize: 12
                color: Theme.darkGrey
            }

            ComboBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: [qsTr("Desktop"), qsTr("Web"), qsTr("Mobile")]
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Resolution Width")
                    font.pixelSize: 12
                    color: Theme.darkGrey
                }

                TextField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: "1280"
                    color: Theme.white

                    background: Rectangle {
                        radius: 8
                        color: Theme.bgTertiary
                        border.color: Theme.borderColor
                        border.width: 1
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Resolution Height")
                    font.pixelSize: 12
                    color: Theme.darkGrey
                }

                TextField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: "720"
                    color: Theme.white

                    background: Rectangle {
                        radius: 8
                        color: Theme.bgTertiary
                        border.color: Theme.borderColor
                        border.width: 1
                    }
                }
            }
        }
    }
}