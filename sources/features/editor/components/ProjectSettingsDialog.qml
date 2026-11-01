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
    standardButtons: Dialog.Save | Dialog.Cancel

    // The game window size is also the start scene camera's size (its red border).
    signal resolutionChanged(int width, int height)

    onAccepted: {
        const width = parseInt(widthInput.text) || 1280
        const height = parseInt(heightInput.text) || 720
        const resolutionEdited = width !== CurrentProjectManager.windowWidth || height !== CurrentProjectManager.windowHeight

        CurrentProjectManager.name = nameInput.text
        CurrentProjectManager.startScene = sceneInput.text
        CurrentProjectManager.windowWidth = width
        CurrentProjectManager.windowHeight = height

        CurrentProjectManager.saveProject()
        if (resolutionEdited) root.resolutionChanged(width, height)
    }

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
                id: nameInput
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: CurrentProjectManager.name
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
                text: qsTr("Start Scene")
                font.pixelSize: 12
                color: Theme.darkGrey
            }

            TextField {
                id: sceneInput
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: CurrentProjectManager.startScene
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

        Text {
            Layout.fillWidth: true
            text: qsTr("Game window size, in pixels. It is also the start scene camera (the red border in the viewport): resizing one resizes the other.")
            font.pixelSize: 11
            color: Theme.grey
            wrapMode: Text.WordWrap
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
                    id: widthInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: CurrentProjectManager.windowWidth.toString()
                    color: Theme.white
                    validator: IntValidator { bottom: 100; top: 7680 }

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
                    id: heightInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: CurrentProjectManager.windowHeight.toString()
                    color: Theme.white
                    validator: IntValidator { bottom: 100; top: 4320 }

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