import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entities: []
    property var selectedEntity: null

    signal entitySelected(var entity)
    signal entityCreateRequested(string name)
    signal entityRenameRequested(var entity, string newName)
    signal entityDuplicateRequested(var entity, string newName)
    signal entityDeleteRequested(var entity)

    color: Theme.bgSecondary

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    ListModel { id: entitiesModel }

    function findEntity(entityId, entityGeneration) {
        const items = root.entities || [];
        for (let i = 0; i < items.length; i++) {
            if (items[i].id === entityId && items[i].generation === entityGeneration) {
                return items[i];
            }
        }
        return null;
    }

    function nameTaken(name) {
        const items = root.entities || [];
        for (let i = 0; i < items.length; i++) {
            if (items[i].name === name) return true;
        }
        return false;
    }

    // Same " copy"/" copy N" suffixing idiom as SceneBrowserPanel.duplicateScene().
    function uniqueName(baseName) {
        if (!root.nameTaken(baseName)) return baseName;
        let suffix = 2;
        while (root.nameTaken(baseName + " " + suffix)) suffix++;
        return baseName + " " + suffix;
    }

    function refreshEntities() {
        entitiesModel.clear();
        // Insertion order from the bridge reorders on every destroy (swap-with-back in the
        // engine's entity_manager) - sort by id so create/delete/duplicate cycles don't visibly
        // shuffle unrelated rows.
        const items = (root.entities || []).slice().sort((a, b) => a.id - b.id);
        for (let i = 0; i < items.length; i++) {
            const e = items[i];
            entitiesModel.append({
                "entityId": e.id,
                "entityGeneration": e.generation,
                "rowName": e.name
            });
        }
    }

    Component.onCompleted: refreshEntities()
    onEntitiesChanged: refreshEntities()

    RenameDialog {
        id: renameEntityDialog
        property var targetEntity: null

        onConfirmed: (newName) => {
            if (renameEntityDialog.targetEntity) {
                root.entityRenameRequested(renameEntityDialog.targetEntity, newName)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: qsTr("HIERARCHY (%1)").arg(entitiesModel.count)
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.white
            }

            MuiIcon {
                name: "add"
                font.pixelSize: 16
                color: Theme.grey

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.entityCreateRequested(root.uniqueName("Entity"))
                }
            }
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            spacing: 2
            model: entitiesModel

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: HierarchyItem {
                required property int index
                required property int entityId
                required property int entityGeneration
                required property string rowName

                width: listView.width

                entityName: rowName !== "" ? rowName : ("Entity #" + entityId)
                isLocked: rowName === "main_camera"

                selected: root.selectedEntity !== null
                    && root.selectedEntity.id === entityId
                    && root.selectedEntity.generation === entityGeneration

                onClicked: {
                    const entity = root.findEntity(entityId, entityGeneration)
                    if (entity) root.entitySelected(entity)
                }

                onRenameRequested: {
                    const entity = root.findEntity(entityId, entityGeneration)
                    if (entity) {
                        renameEntityDialog.targetEntity = entity
                        renameEntityDialog.openFor("", entity.name)
                    }
                }

                onDuplicateRequested: {
                    const entity = root.findEntity(entityId, entityGeneration)
                    if (entity) {
                        root.entityDuplicateRequested(entity, root.uniqueName(entity.name + " copy"))
                    }
                }

                onDeleteRequested: {
                    const entity = root.findEntity(entityId, entityGeneration)
                    if (entity) root.entityDeleteRequested(entity)
                }
            }
        }
    }
}
