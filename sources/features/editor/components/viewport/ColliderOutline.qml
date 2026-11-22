import QtQuick

import noi_engine_editor

// Draws the selected entity's box collider (green outline, tinted when it's a trigger), so the
// physics shape is visible next to the sprite, like in other 2D editors.
Item {
    id: root

    property Item viewport          // ViewportPanel: toScreen(), unit
    property var components: []     // OpenGLView.inspectedComponents of the selected entity

    function valueOf(component, name, fallback) {
        if (!component) return fallback;
        const property = (component.properties || []).find(p => p.name === name);
        return property && property.value !== undefined ? property.value : fallback;
    }

    readonly property var transformComponent: (components || []).find(c => c.type === "transform")
    readonly property var colliderComponent: (components || []).find(c => c.type === "box_collider")
    readonly property bool active: !!colliderComponent && !!transformComponent

    readonly property var position: valueOf(transformComponent, "position", [0, 0, 0])
    readonly property real halfWidth: valueOf(colliderComponent, "half_width", 0.5)
    readonly property real halfHeight: valueOf(colliderComponent, "half_height", 0.5)
    readonly property real offsetX: valueOf(colliderComponent, "offset_x", 0)
    readonly property real offsetY: valueOf(colliderComponent, "offset_y", 0)
    readonly property bool isTrigger: valueOf(colliderComponent, "is_trigger", false) === true

    readonly property point centre: active && viewport ? viewport.toScreen(position[0] + offsetX, position[1] + offsetY) : Qt.point(0, 0)

    visible: active

    Rectangle {
        x: root.centre.x - root.halfWidth * root.viewport.unit
        y: root.centre.y - root.halfHeight * root.viewport.unit
        width: 2 * root.halfWidth * root.viewport.unit
        height: 2 * root.halfHeight * root.viewport.unit
        color: root.isTrigger ? Qt.rgba(0.94, 0.7, 0.33, 0.12) : "transparent"
        border.width: 2
        border.color: root.isTrigger ? Theme.warning : Theme.primaryLightA
        radius: 1

        Rectangle {
            visible: parent.width > 60
            anchors.left: parent.left
            anchors.bottom: parent.top
            anchors.bottomMargin: 2
            width: label.implicitWidth + 10
            height: 16
            radius: 4
            color: root.isTrigger ? Theme.warning : Theme.primaryLightA

            Text {
                id: label
                anchors.centerIn: parent
                text: root.isTrigger ? qsTr("Trigger") : qsTr("Collider")
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.black
            }
        }
    }
}
