import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

CustomPage {
    id: root

    title: qsTr("HomePage")

    RecentProjectsModel {
        id: recentProjectsModel
        manager: RecentProjectsManager
    }

    SettingsDialog {
        id: settingsDialog
    }

    CreateProjectDialog {
        id: createProjectDialog
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    FolderDialog {
        id: openProjectFolderDialog
        title: qsTr("Select Project Folder")

        onAccepted: {
            let localPath = UrlConverter.toLocalPath(selectedFolder);
            if (CurrentProjectManager.openProject(localPath)) {
                RecentProjectsManager.addProject(UrlConverter.getFolderName(localPath), localPath);
                Router.push("/editor");
            }
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent

        anchors.leftMargin: root.width >= 1200 ? 48 : 24
        anchors.rightMargin: root.width >= 1200 ? 48 : 24
        anchors.topMargin: root.height >= 700 ? 40 : 24
        anchors.bottomMargin: root.height >= 700 ? 40 : 24

        contentWidth: flickable.width
        contentHeight: contentColumn.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn

            width: Math.min(flickable.width, 1500)
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 40

            RowLayout {
                Layout.fillWidth: true
                spacing: 36

                Rectangle {
                    id: imageContainer

                    Layout.preferredHeight: Math.min(root.height * 0.62, 550)
                    Layout.preferredWidth: Layout.preferredHeight * (1280 / 720)
                    Layout.alignment: Qt.AlignTop

                    radius: 14
                    clip: true
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.borderColor

                    Image {
                        anchors.fill: parent
                        source: "/images/hero.png"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: qsTr("Welcome to Noi Engine")
                            font.pixelSize: 26
                            font.weight: Font.Bold
                            color: Theme.white
                        }

                        Text {
                            text: qsTr("Select an action or open a recent workspace to start editing.")
                            font.pixelSize: 13
                            color: Qt.rgba(1, 1, 1, 0.55)
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.borderColor
                        opacity: 0.5
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        AppButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            primary: true
                            text: qsTr("Create New Project")
                            icon: "add"
                            onClicked: createProjectDialog.open()
                        }

                        AppButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            primary: false
                            text: qsTr("Open Project")
                            icon: "folder_open"
                            onClicked: openProjectFolderDialog.open()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        AppButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            primary: false
                            text: qsTr("Settings")
                            icon: "settings"
                            onClicked: settingsDialog.open()
                        }

                        AppButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            primary: false
                            text: qsTr("Credits")
                            icon: "info"
                            enabled: false
                            opacity: 0.4
                        }
                    }
                }
            }

            RecentProjectsSection {
                Layout.fillWidth: true
                model: recentProjectsModel
                onProjectClicked: path => {
                    if (CurrentProjectManager.openProject(path)) {
                        Router.push("/editor");
                    } else {
                        RecentProjectsManager.removeProject(path);
                    }
                }
            }

            Item {
                Layout.preferredHeight: 20
                Layout.fillWidth: true
            }
        }
    }
}