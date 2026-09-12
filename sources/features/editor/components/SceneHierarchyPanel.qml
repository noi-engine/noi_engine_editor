import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entities: []
    property var selectedEntity: null

    signal entitySelected(var entity)

    color: Theme.bgSecondary

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    ListModel { id: entitiesModel }

    function refreshEntities() {
        entitiesModel.clear();
        const items = root.entities || [];
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: qsTr("HIERARCHY (%1)").arg(entitiesModel.count)
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Theme.white
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

                selected: root.selectedEntity !== null
                    && root.selectedEntity.id === entityId
                    && root.selectedEntity.generation === entityGeneration

                onClicked: root.entitySelected(root.entities[index])
            }
        }
    }
}
