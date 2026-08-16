import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import noi_engine_editor

Item {
    id: rootItem

    function toFolderUrl(pathStr) {
        if (!pathStr) return ""
        let str = pathStr.toString()
        if (str.startsWith("file://")) return str
        return "file://" + str
    }

    function refreshFolderModel() {
        let current = rootItem.currentFolder
        folderModel.folder = ""
        Qt.callLater(function() {
            folderModel.folder = current
        })
    }

    readonly property string rootFolder: toFolderUrl(CurrentProjectManager.resourcesPath())
    property string currentFolder: rootFolder
    property string selectedFilePath: ""
    property real gridScale: 1.0

    Component.onCompleted: {
        if (rootItem.currentFolder === "") {
            rootItem.currentFolder = rootItem.rootFolder
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        RenameDialog {
            id: renameDialog
            property string targetPath: ""
            onConfirmed: newName => {
                if (CurrentProjectResourcesManager.renameItem(targetPath, newName)) {
                    refreshFolderModel()
                }
            }
        }

        DeleteConfirmDialog {
            id: deleteDialog
            property string targetPath: ""
            onConfirmed: {
                if (CurrentProjectResourcesManager.deleteItem(targetPath)) {
                    rootItem.selectedFilePath = ""
                    refreshFolderModel()
                }
            }
        }

        ImportDialog {
            id: importDialog
            onImported: urls => {
                CurrentProjectResourcesManager.importPaths(urls, rootItem.currentFolder)
                refreshFolderModel()
            }
        }

        RenameDialog {
            id: newFolderDialog
            title: qsTr("New Folder")
            onConfirmed: folderName => {
                CurrentProjectResourcesManager.createFolder(rootItem.currentFolder, folderName)
                refreshFolderModel()
            }
        }

        DropArea {
            id: dropArea
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.primaryColor, 0.1)
                border.color: Theme.primaryColor
                border.width: 2
                visible: dropArea.containsDrag
                z: 10

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    IconBadge {
                        Layout.alignment: Qt.AlignHCenter
                        icon: "file_upload"
                    }

                    Text {
                        text: qsTr("Drop files or folders here")
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.white
                    }
                }
            }

            onDropped: drop => {
                if (drop.hasUrls) {
                    CurrentProjectResourcesManager.importPaths(drop.urls, rootItem.currentFolder)
                    refreshFolderModel()
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 8

                AppButton {
                    icon: "arrow_back"
                    enabled: rootItem.currentFolder.toString() !== rootItem.rootFolder.toString() && folderModel.parentFolder !== ""
                    onClicked: {
                        if (rootItem.currentFolder.toString() !== rootItem.rootFolder.toString() && folderModel.parentFolder !== "") {
                            rootItem.currentFolder = folderModel.parentFolder
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: rootItem.currentFolder.replace("file://", "")
                    font.pixelSize: 11
                    color: Theme.grey
                    elide: Text.ElideLeft
                }

                Slider {
                    id: zoomSlider
                    implicitWidth: 100
                    from: 0.75
                    to: 1.5
                    value: rootItem.gridScale
                    onValueChanged: rootItem.gridScale = value
                }

                AppButton {
                    icon: "file_upload"
                    text: qsTr("Import")
                    onClicked: importDialog.open()
                }

                AppButton {
                    icon: "create_new_folder"
                    text: qsTr("New Folder")
                    onClicked: {
                        newFolderDialog.targetName = "NewFolder"
                        newFolderDialog.open()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.borderColor
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8

                readonly property Item panelRoot: rootItem
                readonly property string rootFolderPath: rootItem.rootFolder
                property string currentFolderPath: rootItem.currentFolder
                property string selectedPath: rootItem.selectedFilePath
                property real currentScale: rootItem.gridScale

                cellWidth: 94 * gridView.currentScale
                cellHeight: 94 * gridView.currentScale
                clip: true

                model: FolderListModel {
                    id: folderModel
                    folder: rootItem.currentFolder
                    showDirs: true
                    showFiles: true
                    showDirsFirst: true
                    showDotAndDotDot: false
                    showHidden: false
                }

                delegate: ResourceItemDelegate {
                    property string itemPath: model.filePath || ""
                    property string itemName: model.fileName || ""
                    property bool itemIsDir: model.fileIsDir || false

                    fileName: itemName
                    filePath: itemPath
                    isDir: itemIsDir
                    isSelected: GridView.view.selectedPath === itemPath
                    iconScale: GridView.view.currentScale

                    onSelected: GridView.view.panelRoot.selectedFilePath = itemPath
                    onDoubleClicked: {
                        if (itemIsDir) {
                            let targetFolder = model.fileUrl.toString()
                            if (targetFolder.startsWith(GridView.view.rootFolderPath)) {
                                GridView.view.panelRoot.currentFolder = targetFolder
                                GridView.view.panelRoot.selectedFilePath = ""
                            }
                        }
                    }
                    onRenameRequested: {
                        renameDialog.targetPath = itemPath
                        renameDialog.targetName = itemName
                        renameDialog.open()
                    }
                    onDeleteRequested: {
                        deleteDialog.targetPath = itemPath
                        deleteDialog.targetName = itemName
                        deleteDialog.open()
                    }
                }

                WheelHandler {
                    acceptedModifiers: Qt.ControlModifier
                    onWheel: event => {
                        if (event.angleDelta.y > 0) {
                            rootItem.gridScale = Math.min(1.5, rootItem.gridScale + 0.1)
                        } else if (event.angleDelta.y < 0) {
                            rootItem.gridScale = Math.max(0.75, rootItem.gridScale - 0.1)
                        }
                    }
                }
            }
        }
    }
}