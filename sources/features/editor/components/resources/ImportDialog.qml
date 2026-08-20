import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import noi_engine_editor
import "../../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

Dialog {
    id: root

    signal imported(list<string> paths)

    title: qsTr("Import Resources")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 560
    implicitHeight: 440

    ListModel { id: importModel }

    function containsPath(path) {
        for (let i = 0; i < importModel.count; i++) {
            if (importModel.get(i).path === path) return true
        }
        return false
    }

    function addPath(rawUrl, isFolder) {
        let localPath = UrlConverter.toLocalPath(rawUrl)

        if (!containsPath(localPath)) {
            let clean = localPath.replace(/\/$/, "")
            let name = clean.substring(clean.lastIndexOf('/') + 1)
            importModel.append({ "path": localPath, "fileName": name, "isFolder": isFolder })
        }
    }

    FileDialog {
        id: filePicker
        title: qsTr("Select Files")
        fileMode: FileDialog.OpenFiles
        onAccepted: selectedFiles.forEach(file => root.addPath(file.toString(), false))
    }

    FolderDialog {
        id: folderPicker
        title: qsTr("Select Folder")
        onAccepted: root.addPath(selectedFolder.toString(), true)
    }

    onOpened: importModel.clear()

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppButton { icon: "insert_drive_file"; text: qsTr("Add Files..."); onClicked: filePicker.open() }
            AppButton { icon: "folder_open"; text: qsTr("Add Folder..."); onClicked: folderPicker.open() }
            Item { Layout.fillWidth: true }
            AppButton { icon: "clear_all"; text: qsTr("Clear List"); enabled: importModel.count > 0; onClicked: importModel.clear() }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.25)
            radius: 6
            border.color: Theme.borderColor

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                spacing: 6
                model: importModel

                delegate: Rectangle {
                    required property string path
                    required property string fileName
                    required property bool isFolder
                    required property int index

                    width: listView.width
                    height: 44
                    color: Qt.rgba(1, 1, 1, 0.03)
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        IconBadge { icon: isFolder ? "folder" : "description" }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text { Layout.fillWidth: true; text: fileName; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.white; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: path; font.pixelSize: 10; color: Theme.grey; elide: Text.ElideMiddle }
                        }

                        AppButton { icon: "close"; onClicked: importModel.remove(index) }
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

            Text { text: qsTr("Total items: %1").arg(importModel.count); font.pixelSize: 11; color: Theme.grey }
            Item { Layout.fillWidth: true }
            AppButton { text: qsTr("Cancel"); onClicked: root.reject() }
            AppButton {
                text: qsTr("Import")
                enabled: importModel.count > 0
                onClicked: {
                    let result = []
                    for (let i = 0; i < importModel.count; i++) result.push(importModel.get(i).path)
                    root.imported(result)
                    root.accept()
                }
            }
        }
    }
}