import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    signal settingsRequested()
    signal playRequested()
    signal backRequested()

    property var scenes: ListModel {
        ListElement { name: "MainScene" }
    }
    property int currentSceneIndex: 0

    color: Theme.bgSecondary

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 16

        MuiIcon {
            name: "arrow_back"
            font.pixelSize: 20
            color: Theme.grey

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }

        ColumnLayout {
            spacing: 1

            Text {
                text: CurrentProjectManager.name
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.white
            }

            Text {
                text: CurrentProjectManager.path
                font.pixelSize: 10
                color: Theme.grey
                elide: Text.ElideMiddle
                Layout.maximumWidth: 220
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 26
            color: Theme.borderColor
        }

        Row {
            spacing: 6

            Repeater {
                model: root.scenes

                delegate: Rectangle {
                    required property string name
                    required property int index

                    readonly property bool active: index === root.currentSceneIndex

                    width: sceneLabel.implicitWidth + 24
                    height: 30
                    radius: 8

                    color: active ? Theme.primaryLightC : "transparent"
                    border.color: active ? Theme.primaryDark : "transparent"
                    border.width: 1

                    Text {
                        id: sceneLabel

                        anchors.centerIn: parent
                        text: name
                        font.pixelSize: 12
                        color: active ? Theme.primaryColor : Theme.darkGrey
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentSceneIndex = index
                    }
                }
            }

            Rectangle {
                width: 30
                height: 30
                radius: 8
                color: addSceneArea.containsMouse ? Theme.bgTertiary : "transparent"

                MuiIcon {
                    anchors.centerIn: parent
                    name: "add"
                    font.pixelSize: 16
                    color: Theme.grey
                }

                MouseArea {
                    id: addSceneArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.scenes.append({ name: "Scene" + (root.scenes.count + 1) })
                }
            }
        }

        Item { Layout.fillWidth: true }

        AppButton {
            icon: "settings"
            text: qsTr("Settings")
            onClicked: root.settingsRequested()
        }

        AppButton {
            primary: true
            icon: "play_arrow"
            text: qsTr("Play")
            onClicked: root.playRequested()
        }
    }
}