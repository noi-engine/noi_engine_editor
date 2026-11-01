import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// One component (or the material) in the Inspector. Collapsed by default: click the header to
// open it, several can be open at once. While searching, only matching sections/properties
// show, already opened.
Rectangle {
    id: section

    property var modelData
    property var inspector
    property string query: "" // lower-case search text

    readonly property string componentType: section.modelData.type
    readonly property var componentProperties: (section.modelData.properties || [])
        .filter(p => p.name !== "scene_camera")
    readonly property bool forcedReadOnly: inspector.isEditorManaged(section.componentType)
    readonly property string title: inspector.sectionTitle(section.componentType)

    readonly property bool titleMatches: section.query === ""
        || section.title.toLowerCase().indexOf(section.query) !== -1
        || section.componentType.indexOf(section.query) !== -1
    readonly property var shownProperties: section.titleMatches
        ? section.componentProperties
        : section.componentProperties.filter(p => inspector.displayName(p.name).toLowerCase().indexOf(section.query) !== -1)
    readonly property bool expanded: section.query !== "" || inspector.isExpanded(section.componentType)

    visible: section.titleMatches || section.shownProperties.length > 0
    Layout.fillWidth: true
    implicitHeight: visible ? cardColumn.implicitHeight + 16 : 0
    radius: 8
    color: Theme.bgTertiary
    border.color: Theme.borderColor
    border.width: 1

    ColumnLayout {
        id: cardColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MuiIcon {
                name: section.expanded ? "expand_more" : "chevron_right"
                font.pixelSize: 16
                color: Theme.grey
            }

            Text {
                Layout.fillWidth: true
                text: section.title
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: section.expanded ? Theme.white : Theme.darkGrey
                elide: Text.ElideRight
            }

            Text {
                visible: section.forcedReadOnly
                text: qsTr("editor-managed")
                font.pixelSize: 9
                font.italic: true
                color: Theme.grey
            }

            Text {
                visible: !section.expanded && section.componentProperties.length > 0
                text: section.componentProperties.length
                font.pixelSize: 10
                color: Theme.grey
            }

            MuiIcon {
                readonly property string blockedReason: inspector.removeBlockedReason(section.componentType)

                name: "delete"
                font.pixelSize: 14
                color: blockedReason === "" ? Theme.grey : Theme.borderColor
                visible: inspector.entity !== null && !section.forcedReadOnly
                    && section.componentType !== "name_component" && section.componentType !== "world_matrix"
                ToolTip.visible: deleteArea.containsMouse && blockedReason !== ""
                ToolTip.text: qsTr("Can't remove: %1").arg(blockedReason)

                MouseArea {
                    id: deleteArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: parent.blockedReason === "" ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    onClicked: {
                        if (parent.blockedReason === "") inspector.componentRemoved(section.componentType);
                    }
                }
            }
        }

        Repeater {
            model: section.expanded ? section.shownProperties : []

            delegate: PropertyRow {
                inspector: section.inspector
                componentType: section.componentType
                sectionReadOnly: section.forcedReadOnly
            }
        }

        Text {
            visible: section.expanded && section.componentProperties.length === 0
            text: qsTr("No editable fields")
            font.pixelSize: 10
            font.italic: true
            color: Theme.grey
        }

        // Material Overrides the current material doesn't define: leftovers from another material.
        Rectangle {
            readonly property var unused: section.componentType === "mesh_renderer_properties"
                ? inspector.unusedOverrides() : []

            visible: section.expanded && unused.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: unusedColumn.implicitHeight + 12
            radius: 6
            color: "#3A2E1A"
            border.color: "#E0B85B"

            ColumnLayout {
                id: unusedColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: 10
                    color: "#E0B85B"
                    text: qsTr("Not used by %1: %2").arg(inspector.entityMaterial())
                        .arg(parent.parent.unused.map(n => n.substring(n.indexOf(":") + 1)).join(", "))
                }

                AppButton {
                    text: qsTr("Remove unused")
                    icon: "cleaning_services"
                    onClicked: {
                        for (const name of parent.parent.unused) inspector.propertyRemoved("mesh_renderer_properties", name);
                    }
                }
            }
        }

        Rectangle {
            visible: section.expanded && inspector.supportsAddProperty(section.componentType) && !section.forcedReadOnly
            Layout.fillWidth: true
            Layout.preferredHeight: addPropertyRow.implicitHeight + 12
            radius: 6
            color: "transparent"
            border.color: Theme.borderColor
            border.width: 1

            RowLayout {
                id: addPropertyRow
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                MuiIcon {
                    name: "add"
                    font.pixelSize: 14
                    color: Theme.grey
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Add Property")
                    font.pixelSize: 11
                    color: Theme.grey
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: inspector.openAddProperty(section.componentType, section.componentProperties.map(p => p.name))
            }
        }
    }

    // Header click target, behind the delete icon's own MouseArea.
    MouseArea {
        x: 0
        y: 0
        width: parent.width - 32
        height: 32
        cursorShape: Qt.PointingHandCursor
        enabled: section.query === ""
        onClicked: inspector.toggleExpanded(section.componentType)
    }
}
