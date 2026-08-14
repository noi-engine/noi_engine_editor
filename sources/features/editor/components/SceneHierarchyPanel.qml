import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    signal entitySelected(var entity)

    property string selectedName: ""

    color: Theme.bgSecondary

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    ListModel {
        id: entitiesModel

        ListElement { name: "Main Camera"; type: "camera"; depth: 0 }
        ListElement { name: "Directional Light"; type: "light"; depth: 0 }
        ListElement { name: "Ground"; type: "mesh"; depth: 0 }
        ListElement { name: "Player"; type: "mesh"; depth: 0 }
        ListElement { name: "UI Canvas"; type: "empty"; depth: 0 }
        ListElement { name: "Score Label"; type: "mesh"; depth: 1 }
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
                text: qsTr("Hierarchy")
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.white
            }

            MuiIcon {
                name: "add"
                font.pixelSize: 18
                color: Theme.grey

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: entitiesModel.append({ name: "Entity", type: "empty", depth: 0 })
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
                required property string name
                required property string type
                required property int depth

                width: listView.width

                entityName: name
                entityType: type
                entityDepth: depth

                selected: root.selectedName === name

                onClicked: root.entitySelected({ name: name, type: type })
            }
        }
    }
}