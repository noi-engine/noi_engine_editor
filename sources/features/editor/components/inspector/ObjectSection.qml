import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// The basics of any object, in one place: its name, where it is and in which order it is drawn.
// (Size lives in the Appearance section next to the picture.)
Rectangle {
    id: section

    property var modelData // {type: "object", name, transform, renderLayer}
    property var inspector

    function valueOf(properties, name, fallback) {
        for (const p of properties || []) {
            if (p.name === name) return p.value;
        }
        return fallback;
    }

    readonly property string objectName: valueOf(modelData.name, "name", "")
    readonly property var position: valueOf(modelData.transform, "position", [0, 0, 0])
    readonly property var scale: valueOf(modelData.transform, "scale", [1, 1, 1])
    readonly property bool hasRenderLayer: !!modelData.renderLayer

    // Whether the object is inside what the scene camera sees: outside, it won't be on screen
    // when the game runs.
    readonly property var camera: inspector.sceneCamera
    readonly property bool outsideCamera: {
        const cam = camera;
        if (!cam || !cam.valid || !modelData.renderLayer) return false; // invisible objects (triggers...) don't matter
        const halfH = cam.orthographicSize / cam.zoom;
        const halfW = halfH * cam.aspectRatio;
        const objectHalfW = Math.abs(scale[0]) / 2, objectHalfH = Math.abs(scale[1]) / 2;
        return position[0] + objectHalfW < cam.x - halfW || position[0] - objectHalfW > cam.x + halfW
            || position[1] + objectHalfH < cam.y - halfH || position[1] - objectHalfH > cam.y + halfH;
    }
    readonly property real drawOrder: valueOf(modelData.renderLayer, "order", 0)

    readonly property bool expanded: inspector.isExpanded("object")

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 24
    radius: Theme.radius
    color: Theme.bgTertiary
    border.color: Theme.borderColor

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MuiIcon {
                name: section.expanded ? "expand_more" : "chevron_right"
                font.pixelSize: 16
                color: Theme.grey
            }

            MuiIcon {
                name: "open_with"
                font.pixelSize: 17
                color: Theme.primaryColor
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Object")
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.white
            }

            // The whole header folds / unfolds the card.
            TapHandler { onTapped: section.inspector.toggleExpanded("object") }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        ColumnLayout {
            visible: section.expanded
            Layout.fillWidth: true
            spacing: 12
            AppTextField {
                Layout.fillWidth: true
                label: qsTr("Name")
                text: section.objectName
                onAccepted: if (text.trim() !== "" && text.trim() !== section.objectName)
                                section.inspector.propertyEdited("name_component", "name", "string", text.trim())
                field.onEditingFinished: if (text.trim() !== "" && text.trim() !== section.objectName)
                                section.inspector.propertyEdited("name_component", "name", "string", text.trim())
            }

            Text {
                text: qsTr("Position (pixels, 100 pixels = 1 unit in your code)")
                font.pixelSize: 11
                color: Theme.darkGrey
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                NumberField {
                    label: qsTr("X")
                    decimals: 1
                    value: section.position[0] * 100
                    onEdited: number => section.inspector.propertyEdited("transform", "position", "vec3",
                                                                          [number / 100, section.position[1], section.position[2]])
                }

                NumberField {
                    label: qsTr("Y (up is positive)")
                    decimals: 1
                    value: section.position[1] * 100
                    onEdited: number => section.inspector.propertyEdited("transform", "position", "vec3",
                                                                          [section.position[0], number / 100, section.position[2]])
                }
            }

            Banner {
                Layout.fillWidth: true
                visible: section.outsideCamera
                kind: "warning"
                title: qsTr("Outside the camera's view")
                text: qsTr("It won't be on screen when the game runs.")
                actionText: qsTr("Move into view")
                onActionTriggered: section.inspector.propertyEdited("transform", "position", "vec3",
                                                                    [section.camera.x, section.camera.y, section.position[2]])
            }

            NumberField {
                visible: section.hasRenderLayer
                label: qsTr("Draw order (higher is in front of lower)")
                decimals: 0
                value: section.drawOrder
                onEdited: number => section.inspector.propertyEdited("render_layer", "order", "float", number)
            }
    
        }
    }
}
