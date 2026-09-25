import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import noi_engine_editor
import "../../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

Item {
    id: rootItem

    readonly property string rootFolder: CurrentProjectManager.resourcesPath()
    property string currentFolder: rootFolder
    property string selectedFilePath: ""
    property real gridScale: 1.0

    Component.onCompleted: {
        if (rootItem.currentFolder === "")
            rootItem.currentFolder = rootItem.rootFolder;
    }

    function enterFolder(targetFolder) {
        if (targetFolder.startsWith(rootItem.rootFolder)) {
            rootItem.currentFolder = targetFolder;
            rootItem.selectedFilePath = "";
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        RenameDialog {
            id: renameDialog
            onConfirmed: function (newName) {
                CurrentProjectResourcesManager.renameItem(renameDialog.targetPath, newName);
            }
        }

        DeleteConfirmDialog {
            id: deleteDialog
            onConfirmed: {
                if (CurrentProjectResourcesManager.deleteItem(deleteDialog.targetPath)) {
                    rootItem.selectedFilePath = "";
                }
            }
        }

        NewFolderDialog {
            id: newFolderDialog
            onConfirmed: function (folderName) {
                CurrentProjectResourcesManager.createFolder(targetPath, folderName);
            }
        }

        ImportDialog {
            id: importDialog
            onImported: function (paths) {
                CurrentProjectResourcesManager.importPaths(paths, rootItem.currentFolder);
            }
        }

        ResourceDropArea {
            anchors.fill: parent
            onImportDropped: function (paths) {
                CurrentProjectResourcesManager.importPaths(paths, rootItem.currentFolder);
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            ResourceToolbar {
                currentFolder: rootItem.currentFolder
                rootFolder: rootItem.rootFolder
                parentFolder: UrlConverter.toLocalPath(folderModel.parentFolder)
                gridScale: rootItem.gridScale

                onGridScaleChanged: rootItem.gridScale = gridScale
                onNavigateBack: rootItem.currentFolder = UrlConverter.toLocalPath(folderModel.parentFolder)
                onImportRequested: importDialog.open()
                onNewFolderRequested: newFolderDialog.openFor(rootItem.currentFolder, "NewFolder")
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

                cellWidth: 94 * rootItem.gridScale
                cellHeight: 94 * rootItem.gridScale
                clip: true

                model: FolderListModel {
                    id: folderModel
                    folder: UrlConverter.toUrl(rootItem.currentFolder)
                    showDirs: true
                    showFiles: true
                    showDirsFirst: true
                    showDotAndDotDot: false
                    showHidden: false
                }

                delegate: ResourceItemDelegate {
                    id: delegateItem

                    fileName: model.fileName || ""
                    filePath: model.filePath || ""
                    isDir: model.fileIsDir || false

                    isSelected: rootItem.selectedFilePath === filePath
                    iconScale: rootItem.gridScale

                    onSelected: rootItem.selectedFilePath = filePath
                    onDoubleClicked: {
                        if (isDir)
                            rootItem.enterFolder(model.filePath);
                    }
                    onRenameRequested: renameDialog.openFor(filePath, fileName)
                    onDeleteRequested: deleteDialog.openFor(filePath, fileName)
                }

                WheelHandler {
                    acceptedModifiers: Qt.ControlModifier
                    onWheel: function (event) {
                        if (event.angleDelta.y > 0)
                            rootItem.gridScale = Math.min(1.5, rootItem.gridScale + 0.1);
                        else if (event.angleDelta.y < 0)
                            rootItem.gridScale = Math.max(0.75, rootItem.gridScale - 0.1);
                    }
                }
            }
        }
    }
}
