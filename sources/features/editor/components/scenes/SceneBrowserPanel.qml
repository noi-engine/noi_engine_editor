import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import noi_engine_editor

Item {
    id: rootItem

    function toFolderUrl(pathStr) {
        if (!pathStr) return "";
        let str = pathStr.toString();
        return str.startsWith("file://") ? str : "file://" + str;
    }

    readonly property string rootFolder: toFolderUrl(CurrentProjectManager.resourcesPath())

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        GridView {
            anchors.fill: parent
            anchors.margins: 8

            cellWidth: 94
            cellHeight: 94
            clip: true

            model: FolderListModel {
                folder: rootItem.rootFolder
                nameFilters: ["*.scene"]
                showDirs: false
                showFiles: true
            }

            delegate: ResourceItemDelegate {
                property string itemPath: model.filePath || ""
                property string itemName: model.fileName || ""

                fileName: itemName
                filePath: itemPath
                isDir: false
                isSelected: false
                iconScale: 1.0

                onDoubleClicked: {
                    console.log("Ouverture de la scène :", itemPath);
                }
            }
        }
    }
}