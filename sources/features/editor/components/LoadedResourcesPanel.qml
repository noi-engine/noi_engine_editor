import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Item {
    id: rootItem

    property var resources: []
    property var selectedResource: null

    signal resourceSelected(var resource)

    function sectionLabel(type) {
        switch (type) {
            case "mesh": return qsTr("MESHES")
            case "script": return qsTr("SCRIPTS")
            case "shader": return qsTr("SHADERS")
            case "texture": return qsTr("TEXTURES")
            case "material": return qsTr("MATERIALS")
            default: return type.toUpperCase()
        }
    }

    ListModel { id: resourcesModel }

    function refreshModel() {
        resourcesModel.clear();
        const items = rootItem.resources || [];
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            resourcesModel.append({
                "itemLabel": item.label,
                "itemType": item.type,
                "itemId": item.id,
                "itemGeneration": item.generation
            });
        }
    }

    Component.onCompleted: refreshModel()
    onResourcesChanged: refreshModel()

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Theme.bgTertiary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: qsTr("LOADED RESOURCES (%1)").arg(resourcesModel.count)
                        color: Theme.white
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            ListView {
                id: listView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 10

                clip: true
                spacing: 2
                model: resourcesModel

                visible: resourcesModel.count > 0

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                section.property: "itemType"
                section.criteria: ViewSection.FullString
                section.delegate: Text {
                    width: listView.width
                    topPadding: 8
                    bottomPadding: 4
                    text: rootItem.sectionLabel(section)
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.grey
                }

                delegate: LoadedResourceItem {
                    required property int index
                    required property string itemLabel
                    required property string itemType
                    required property int itemId
                    required property int itemGeneration

                    width: listView.width

                    resourceLabel: itemLabel
                    resourceType: itemType
                    resourceId: itemId
                    resourceGeneration: itemGeneration

                    selected: rootItem.selectedResource !== null
                        && rootItem.selectedResource.type === itemType
                        && rootItem.selectedResource.id === itemId
                        && rootItem.selectedResource.generation === itemGeneration

                    onClicked: rootItem.resourceSelected(rootItem.resources[index])
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                spacing: 8
                visible: resourcesModel.count === 0

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No Resources Loaded")
                    color: Theme.white
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Open a scene to see its meshes, scripts, shaders, textures and materials.")
                    color: Theme.darkGrey
                    font.pixelSize: 11
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
