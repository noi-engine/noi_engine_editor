import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import noi_engine_editor
import "../../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

AppDialog {
    id: root

    signal imported(list<string> paths)

    title: qsTr("Import into resources")
    subtitle: qsTr("Resources are the images and files your game uses. Imported items are copied into your project's resources folder.")
    icon: "upload_file"
    preferredWidth: 620

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

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        AppButton { icon: "insert_drive_file"; text: qsTr("Add files..."); onClicked: filePicker.open() }
        AppButton { icon: "folder_open"; text: qsTr("Add a folder..."); onClicked: folderPicker.open() }
        Item { Layout.fillWidth: true }
        AppButton { icon: "clear_all"; text: qsTr("Clear list"); enabled: importModel.count > 0; onClicked: importModel.clear() }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(150, Math.min(importModel.count * 50 + 16, 300))
        color: Theme.bgSecondary
        radius: Theme.radius
        border.color: Theme.borderColor

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            spacing: 6
            model: importModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                required property string path
                required property string fileName
                required property bool isFolder
                required property int index

                width: listView.width
                height: 44
                color: Theme.bgTertiary
                radius: 6

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

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 24
                visible: importModel.count === 0
                spacing: 4

                MuiIcon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "upload_file"
                    font.pixelSize: 30
                    color: Theme.lightGrey
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Nothing to import yet. Use “Add files” or “Add a folder”.")
                    font.pixelSize: 12
                    color: Theme.grey
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    footerContent: [
        Text { text: qsTr("%n item(s) to import", "", importModel.count); font.pixelSize: 12; color: Theme.grey },
        Item { Layout.fillWidth: true },
        AppButton { text: qsTr("Cancel"); onClicked: root.reject() },
        AppButton {
            text: qsTr("Import")
            icon: "upload"
            primary: true
            enabled: importModel.count > 0
            onClicked: {
                let result = []
                for (let i = 0; i < importModel.count; i++) result.push(importModel.get(i).path)
                root.imported(result)
                root.accept()
            }
        }
    ]
}
