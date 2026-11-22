import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import noi_engine_editor
import "../../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

Item {
    id: rootItem

    // A scene file was double-clicked: open it in the editor.
    signal sceneOpenRequested(string filePath)

    readonly property string rootFolder: CurrentProjectManager.resourcesPath()
    property string currentFolder: rootFolder
    property string selectedFilePath: ""
    property real gridScale: 1.0

    Component.onCompleted: {
        if (rootItem.currentFolder === "")
            rootItem.currentFolder = rootItem.rootFolder;
    }

    function relativePath(filePath) {
        return filePath.replace(rootItem.rootFolder + "/", "");
    }

    function setMainScene(filePath) {
        CurrentProjectManager.startScene = rootItem.relativePath(filePath);
        if (CurrentProjectManager.saveProject()) {
            Notifier.success(qsTr("The game will start on “%1”.").arg(filePath.substring(filePath.lastIndexOf("/") + 1)));
        } else {
            Notifier.error(qsTr("Couldn't save the project file."));
        }
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
                if (!CurrentProjectResourcesManager.renameItem(renameDialog.targetPath, newName)) {
                    Notifier.error(qsTr("Couldn't rename it to \"%1\": a file or folder with that name probably already exists.").arg(newName));
                }
            }
        }

        DeleteConfirmDialog {
            id: deleteDialog
            onConfirmed: {
                if (CurrentProjectResourcesManager.deleteItem(deleteDialog.targetPath)) {
                    rootItem.selectedFilePath = "";
                } else {
                    Notifier.error(qsTr("Couldn't delete %1. Check that no other program is using it.").arg(deleteDialog.targetName));
                }
            }
        }

        NewFolderDialog {
            id: newFolderDialog
            onConfirmed: function (folderName) {
                if (!CurrentProjectResourcesManager.createFolder(targetPath, folderName)) {
                    Notifier.error(qsTr("Couldn't create the folder \"%1\": it probably already exists.").arg(folderName));
                }
            }
        }

        ImportDialog {
            id: importDialog
            onImported: function (paths) {
                if (!CurrentProjectResourcesManager.importPaths(paths, rootItem.currentFolder)) {
                    Notifier.error(qsTr("Some items couldn't be imported. Check that they still exist and that the project folder is writable."));
                }
            }
        }

        ResourceDropArea {
            anchors.fill: parent
            onImportDropped: function (paths) {
                if (!CurrentProjectResourcesManager.importPaths(paths, rootItem.currentFolder)) {
                    Notifier.error(qsTr("Some dropped items couldn't be imported. Check that they still exist and that the project folder is writable."));
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Folder tree (like the left column of other editors' asset browsers).
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                color: Theme.bgSecondary

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.borderColor
                }

                property var folders: []
                function refresh() { folders = CurrentProjectResourcesManager.folderTree(rootItem.rootFolder); }
                Component.onCompleted: refresh()

                Connections {
                    target: folderModel
                    function onCountChanged() { treeColumn.parent.refresh(); }
                }

                ListView {
                    id: treeColumn
                    anchors.fill: parent
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    clip: true
                    model: parent.folders
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool current: rootItem.currentFolder === modelData.path
                        width: treeColumn.width - 1
                        height: 28
                        color: current ? Theme.primaryLightB : (treeArea.containsMouse ? Theme.bgTertiary : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10 + modelData.depth * 14
                            anchors.rightMargin: 8
                            spacing: 7

                            MuiIcon {
                                name: current ? "folder_open" : "folder"
                                font.pixelSize: 16
                                color: current ? Theme.primaryColor : Theme.warning
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.depth === 0 ? qsTr("Project files") : modelData.name
                                font.pixelSize: 12
                                font.weight: current ? Font.DemiBold : Font.Normal
                                color: current ? Theme.white : Theme.darkGrey
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: treeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootItem.enterFolder(modelData.path)
                        }
                    }
                }
            }

            ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                Layout.preferredHeight: 36
                color: Theme.bgSecondary

                PanelSearchField {
                    id: resourceSearch
                    anchors.fill: parent
                    anchors.margins: 6
                    placeholderText: qsTr("Search files in this folder...")
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.borderColor
            }

            // What this panel is for, and how to use a file in the scene.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: hintText.implicitHeight + 12
                color: Theme.bgTertiary

                Text {
                    id: hintText
                    anchors.fill: parent
                    anchors.margins: 6
                    anchors.leftMargin: 12
                    text: qsTr("Drag an image from here into the scene (or the scene objects list) to create a sprite. Double-click a scene to open it. Drop files from your computer to import them.")
                    color: Theme.darkGrey
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
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
                    caseSensitive: false
                    nameFilters: resourceSearch.text.trim() === "" ? ["*"] : ["*" + resourceSearch.text.trim() + "*"]
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
                        else if (isScene)
                            rootItem.sceneOpenRequested(model.filePath);
                    }
                    onRenameRequested: renameDialog.openFor(filePath, fileName)
                    isMainScene: isScene && rootItem.relativePath(filePath) === CurrentProjectManager.startScene
                    onMainSceneRequested: rootItem.setMainScene(filePath)
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
}
