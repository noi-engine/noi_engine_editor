import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor

Dialog {
    id: root

    signal imported(list<var> urls)

    title: qsTr("Import Resources")
    modal: true
    anchors.centerIn: Overlay.overlay

    implicitWidth: 560
    implicitHeight: 440

    ListModel {
        id: importModel
    }

    FileDialog {
        id: filePicker
        title: qsTr("Select Files")
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            for (let i = 0; i < selectedFiles.length; i++) {
                let path = selectedFiles[i].toString()
                if (!root.containsUrl(path)) {
                    let name = path.substring(path.lastIndexOf('/') + 1)
                    importModel.append({ "url": path, "fileName": name, "isFolder": false })
                }
            }
        }
    }

    FolderDialog {
        id: folderPicker
        title: qsTr("Select Folder")
        onAccepted: {
            let path = folderPicker.selectedFolder.toString()
            if (!root.containsUrl(path)) {
                let cleanPath = path.replace(/\/$/, "")
                let name = cleanPath.substring(cleanPath.lastIndexOf('/') + 1)
                importModel.append({ "url": path, "fileName": name, "isFolder": true })
            }
        }
    }

    function containsUrl(urlPath) {
        for (let i = 0; i < importModel.count; i++) {
            if (importModel.get(i).url === urlPath) return true
        }
        return false
    }

    onOpened: importModel.clear()

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppButton {
                icon: "insert_drive_file"
                text: qsTr("Add Files...")
                onClicked: filePicker.open()
            }

            AppButton {
                icon: "folder_open"
                text: qsTr("Add Folder...")
                onClicked: folderPicker.open()
            }

            Item { Layout.fillWidth: true }

            AppButton {
                icon: "clear_all"
                text: qsTr("Clear List")
                enabled: importModel.count > 0
                onClicked: importModel.clear()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.25)
            radius: 6
            border.color: Theme.borderColor
            border.width: 1

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6
                model: importModel

                delegate: Rectangle {
                    id: itemDelegate
                    required property string url
                    required property string fileName
                    required property bool isFolder
                    required property int index

                    width: listView.width
                    height: 44
                    color: delegateMouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                    radius: 4

                    MouseArea {
                        id: delegateMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        IconBadge {
                            icon: itemDelegate.isFolder ? "folder" : "description"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: itemDelegate.fileName
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Theme.white
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemDelegate.url.replace("file://", "")
                                font.pixelSize: 10
                                color: Theme.grey
                                elide: Text.ElideMiddle
                            }
                        }

                        AppButton {
                            icon: "close"
                            onClicked: importModel.remove(itemDelegate.index)
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: importModel.count === 0
                    text: qsTr("No files or folders added for import")
                    font.pixelSize: 12
                    color: Theme.grey
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("Total items: %1").arg(importModel.count)
                font.pixelSize: 11
                color: Theme.grey
            }

            Item { Layout.fillWidth: true }

            AppButton {
                text: qsTr("Cancel")
                onClicked: root.reject()
            }

            AppButton {
                text: qsTr("Import")
                enabled: importModel.count > 0
                onClicked: {
                    let result = []
                    for (let i = 0; i < importModel.count; i++) {
                        result.push(importModel.get(i).url)
                    }
                    root.imported(result)
                    root.accept()
                }
            }
        }
    }
}