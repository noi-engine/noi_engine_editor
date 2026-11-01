import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// Scene entities, filed in editor-only folders (each entity's "folder" path, "Level/Platforms"
// for a sub-folder). Searching shows a flat list of entities matching by name, folder or
// component type.
Rectangle {
    id: root

    property var entities: []
    property var selectedEntity: null

    signal entitySelected(var entity)
    // folder: where to file the new entity ("" = root).
    signal entityCreateRequested(string name, string folder)
    signal entityRenameRequested(var entity, string newName)
    // folder: where to file the copy, or null to keep the original's folder.
    signal entityDuplicateRequested(var entity, string newName, var folder)
    signal entityDeleteRequested(var entity)
    // folder === "" removes the entity from its folder.
    signal entityFolderChangeRequested(var entity, string folder)

    function focusSearch() {
        searchField.focusField();
    }

    color: Theme.bgSecondary

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    // Folders created with "New Folder" that hold no entity yet (not saved until they do).
    property var emptyFolders: []
    // Collapsed folders, by path.
    property var collapsedFolders: ({})

    readonly property string query: searchField.text.trim().toLowerCase()
    readonly property var sortedEntities: (root.entities || []).slice().sort((a, b) => a.id - b.id)
    readonly property var allFolders: {
        const folders = new Set(root.emptyFolders);
        for (const e of root.sortedEntities) {
            const parts = (e.folder || "").split("/").filter(p => p !== "");
            for (let i = 1; i <= parts.length; i++) {
                folders.add(parts.slice(0, i).join("/"));
            }
        }
        return Array.from(folders).sort();
    }
    readonly property var rows: root.query !== "" ? root.searchRows() : root.treeRows()

    function parentFolder(path) {
        const idx = path.lastIndexOf("/");
        return idx === -1 ? "" : path.substring(0, idx);
    }

    function isInside(entityFolder, folder) {
        return entityFolder === folder || entityFolder.startsWith(folder + "/");
    }

    function matches(entity, q) {
        if (entity.name.toLowerCase().indexOf(q) !== -1) return true;
        if ((entity.folder || "").toLowerCase().indexOf(q) !== -1) return true;
        return (entity.componentTypes || []).some(t => t.indexOf(q) !== -1);
    }

    function searchRows() {
        return root.sortedEntities.filter(e => root.matches(e, root.query))
            .map(e => ({kind: "entity", entity: e, depth: 0, subtitle: e.folder || ""}));
    }

    function treeRows() {
        const rows = [];
        const emit = (parent, depth) => {
            for (const folder of root.allFolders.filter(f => root.parentFolder(f) === parent)) {
                const expanded = !root.collapsedFolders[folder];
                rows.push({
                    kind: "folder", path: folder, depth: depth, expanded: expanded,
                    name: folder.substring(folder.lastIndexOf("/") + 1),
                    count: root.sortedEntities.filter(e => root.isInside(e.folder || "", folder)).length
                });
                if (expanded) emit(folder, depth + 1);
            }
            for (const e of root.sortedEntities.filter(e => (e.folder || "") === parent)) {
                rows.push({kind: "entity", entity: e, depth: depth, subtitle: ""});
            }
        };
        emit("", 0);
        return rows;
    }

    function nameTaken(name) {
        return root.sortedEntities.some(e => e.name === name);
    }

    // Same " copy"/" copy N" suffixing idiom as SceneBrowserPanel.duplicateScene().
    function uniqueName(baseName) {
        if (!root.nameTaken(baseName)) return baseName;
        let suffix = 2;
        while (root.nameTaken(baseName + " " + suffix)) suffix++;
        return baseName + " " + suffix;
    }

    function joinPath(parent, name) {
        return [parent, name].filter(p => p !== "").join("/");
    }

    function uniqueFolder(path) {
        if (root.allFolders.indexOf(path) === -1) return path;
        let suffix = 2;
        while (root.allFolders.indexOf(path + " " + suffix) !== -1) suffix++;
        return path + " " + suffix;
    }

    function entitiesInside(folder) {
        return root.sortedEntities.filter(e => root.isInside(e.folder || "", folder));
    }

    function duplicateFolder(path) {
        const copy = root.uniqueFolder(path + " copy");
        for (const e of root.entitiesInside(path)) {
            const rest = (e.folder || "").substring(path.length).replace(/^\//, "");
            root.entityDuplicateRequested(e, root.uniqueName(e.name + " copy"), root.joinPath(copy, rest));
        }
        const emptyCopies = root.emptyFolders.filter(f => root.isInside(f, path))
            .map(f => root.joinPath(copy, f.substring(path.length).replace(/^\//, "")));
        if (root.entitiesInside(path).length === 0) emptyCopies.push(copy);
        root.emptyFolders = root.emptyFolders.concat(emptyCopies);
    }

    function deleteFolder(path) {
        for (const e of root.entitiesInside(path)) {
            if (e.name !== "main_camera") root.entityDeleteRequested(e);
        }
        root.emptyFolders = root.emptyFolders.filter(f => !root.isInside(f, path));
    }

    // ---- Drag & drop: rows report their drag, the panel finds the drop target under the cursor.
    property var dragged: null // the dragged row (a `rows` entry)
    property point dragPoint: Qt.point(0, 0) // in listView coordinates
    readonly property int dropRowIndex: root.dragged ? listView.indexAt(root.dragPoint.x, root.dragPoint.y + listView.contentY) : -1

    function dragStarted(row, item, x, y) {
        root.dragged = row;
        root.dragMoved(item, x, y);
    }

    function dragMoved(item, x, y) {
        root.dragPoint = item.mapToItem(listView, x, y);
    }

    // Folder a drop at the current point files into: a folder row -> that folder, an entity
    // row -> that entity's folder, empty space -> the root.
    function dropFolder() {
        const target = root.rows[root.dropRowIndex];
        if (!target) return "";
        return target.kind === "folder" ? target.path : (target.entity.folder || "");
    }

    function dragEnded() {
        const row = root.dragged;
        const folder = root.dropFolder();
        root.dragged = null;
        if (!row) return;

        if (row.kind === "entity") {
            if ((row.entity.folder || "") !== folder) {
                root.entityFolderChangeRequested(row.entity, folder);
                root.emptyFolders = root.emptyFolders.filter(f => !root.isInside(folder, f));
            }
        } else if (!root.isInside(folder, row.path)) { // can't drop a folder into itself
            const destination = root.uniqueFolder(root.joinPath(folder, row.name));
            if (destination !== row.path) root.moveFolderContents(row.path, destination);
        }
    }

    function toggleFolder(path) {
        const next = Object.assign({}, root.collapsedFolders);
        next[path] = !next[path];
        root.collapsedFolders = next;
    }

    // Moves everything filed under `from` (and its sub-folders) under `to`.
    function moveFolderContents(from, to) {
        for (const e of root.sortedEntities) {
            const folder = e.folder || "";
            if (root.isInside(folder, from)) {
                const rest = folder.substring(from.length).replace(/^\//, "");
                root.entityFolderChangeRequested(e, [to, rest].filter(p => p !== "").join("/"));
            }
        }
        root.emptyFolders = root.emptyFolders
            .map(f => root.isInside(f, from) ? [to, f.substring(from.length).replace(/^\//, "")].filter(p => p !== "").join("/") : f)
            .filter(f => f !== "");
    }

    RenameDialog {
        id: renameEntityDialog
        property var targetEntity: null

        onConfirmed: (newName) => {
            if (renameEntityDialog.targetEntity) {
                root.entityRenameRequested(renameEntityDialog.targetEntity, newName)
            }
        }
    }

    RenameDialog {
        id: folderNameDialog
        // "" = create a new folder (inside parentPath), otherwise the path of the folder being renamed.
        property string renamingPath: ""
        property string parentPath: ""

        title: folderNameDialog.renamingPath === "" ? qsTr("New Folder") : qsTr("Rename Folder")

        onConfirmed: (newName) => {
            const name = newName.trim().replace(/\//g, "-");
            if (name === "") return;
            if (folderNameDialog.renamingPath === "") {
                const path = root.joinPath(folderNameDialog.parentPath, name);
                if (root.allFolders.indexOf(path) === -1) root.emptyFolders = root.emptyFolders.concat([path]);
            } else {
                const parent = root.parentFolder(folderNameDialog.renamingPath);
                root.moveFolderContents(folderNameDialog.renamingPath, [parent, name].filter(p => p !== "").join("/"));
            }
        }
    }

    DeleteConfirmDialog {
        id: deleteFolderDialog
        title: qsTr("Delete Folder")
        onConfirmed: root.deleteFolder(deleteFolderDialog.targetPath)
    }

    MoveToFolderDialog {
        id: moveToFolderDialog
        folders: root.allFolders
        onConfirmed: (entity, folder) => {
            root.entityFolderChangeRequested(entity, folder);
            root.emptyFolders = root.emptyFolders.filter(f => !root.isInside(folder, f));
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: qsTr("HIERARCHY (%1)").arg(root.sortedEntities.length)
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.white
            }

            MuiIcon {
                name: "create_new_folder"
                font.pixelSize: 16
                color: Theme.grey

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        folderNameDialog.renamingPath = "";
                        folderNameDialog.parentPath = "";
                        folderNameDialog.openFor("", qsTr("New Folder"));
                    }
                }
            }

            MuiIcon {
                name: "add"
                font.pixelSize: 16
                color: Theme.grey

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.entityCreateRequested(root.uniqueName("Entity"), "")
                }
            }
        }

        PanelSearchField {
            id: searchField
            placeholderText: qsTr("Search entities, folders, components...")
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            spacing: 2
            model: root.rows

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: Loader {
                id: rowLoader

                required property var modelData
                required property int index

                width: listView.width
                sourceComponent: rowLoader.modelData.kind === "folder" ? folderRow : entityRow

                Component {
                    id: folderRow

                    FolderItem {
                        id: folderItem
                        readonly property string path: rowLoader.modelData.path

                        folderName: rowLoader.modelData.name
                        depth: rowLoader.modelData.depth
                        entityCount: rowLoader.modelData.count
                        expanded: rowLoader.modelData.expanded
                        dropTarget: root.dragged !== null && root.dropRowIndex === rowLoader.index

                        onDragStarted: (x, y) => root.dragStarted(rowLoader.modelData, folderItem, x, y)
                        onDragMoved: (x, y) => root.dragMoved(folderItem, x, y)
                        onDragEnded: root.dragEnded()

                        onToggled: root.toggleFolder(path)
                        onNewEntityRequested: root.entityCreateRequested(root.uniqueName("Entity"), path)
                        onNewSubfolderRequested: {
                            folderNameDialog.renamingPath = "";
                            folderNameDialog.parentPath = path;
                            folderNameDialog.openFor("", qsTr("New Folder"));
                        }
                        onDuplicateRequested: root.duplicateFolder(path)
                        onDeleteRequested: deleteFolderDialog.openFor(path, qsTr("%1 and all its entities").arg(path))
                        onRenameRequested: {
                            folderNameDialog.renamingPath = rowLoader.modelData.path;
                            folderNameDialog.openFor("", rowLoader.modelData.name);
                        }
                        onUngroupRequested: root.moveFolderContents(rowLoader.modelData.path,
                            root.parentFolder(rowLoader.modelData.path))
                    }
                }

                Component {
                    id: entityRow

                    HierarchyItem {
                        id: entityItem
                        readonly property var entity: rowLoader.modelData.entity

                        dropTarget: root.dragged !== null && root.dropRowIndex === rowLoader.index
                        onDragStarted: (x, y) => root.dragStarted(rowLoader.modelData, entityItem, x, y)
                        onDragMoved: (x, y) => root.dragMoved(entityItem, x, y)
                        onDragEnded: root.dragEnded()

                        entityName: entity.name !== "" ? entity.name : ("Entity #" + entity.id)
                        subtitle: rowLoader.modelData.subtitle
                        depth: rowLoader.modelData.depth
                        isLocked: entity.name === "main_camera"
                        inFolder: (entity.folder || "") !== ""

                        selected: root.selectedEntity !== null
                            && root.selectedEntity.id === entity.id
                            && root.selectedEntity.generation === entity.generation

                        onClicked: root.entitySelected(entity)
                        onRenameRequested: {
                            renameEntityDialog.targetEntity = entity;
                            renameEntityDialog.openFor("", entity.name);
                        }
                        onDuplicateRequested: root.entityDuplicateRequested(entity, root.uniqueName(entity.name + " copy"), null)
                        onDeleteRequested: root.entityDeleteRequested(entity)
                        onMoveToFolderRequested: moveToFolderDialog.openFor(entity, entity.folder || "")
                        onRemoveFromFolderRequested: root.entityFolderChangeRequested(entity, "")
                    }
                }
            }

            // Follows the cursor while dragging.
            Rectangle {
                visible: root.dragged !== null
                x: root.dragPoint.x + 12
                y: root.dragPoint.y - height / 2
                z: 10
                width: dragLabel.implicitWidth + 16
                height: 24
                radius: 6
                color: Theme.bgTertiary
                border.color: Theme.primaryColor
                opacity: 0.9

                Text {
                    id: dragLabel
                    anchors.centerIn: parent
                    text: !root.dragged ? "" : (root.dragged.kind === "folder" ? root.dragged.name : root.dragged.entity.name)
                        + "  →  " + (root.dropFolder() === "" ? qsTr("(root)") : root.dropFolder())
                    font.pixelSize: 11
                    color: Theme.white
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.query !== "" && listView.count === 0
                text: qsTr("No entity matches \"%1\"").arg(searchField.text.trim())
                font.pixelSize: 11
                font.italic: true
                color: Theme.grey
            }
        }
    }
}
