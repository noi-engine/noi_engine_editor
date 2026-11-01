import QtQuick

import noi_engine_editor

// Click an entity in the viewport to select it, drag it to move it. Clicking empty space is
// left to the parent Flickable (panning). Fills the viewport content (unzoomed coordinates).
Item {
    id: root

    // OpenGLView.entityLayout / sceneCamera.
    property var layout: []
    property var camera: ({})
    // Logical pixels per world unit at camera zoom 1.
    property real pixelsPerUnit: 100
    // Parent's zoom factor, so outlines keep the same on-screen width.
    property real zoom: 1
    property var selectedEntity: null

    signal entityPicked(int entityId, int entityGeneration)
    signal entityMoved(int entityId, int entityGeneration, var position)

    readonly property bool cameraValid: !!camera && !!camera.valid
    readonly property real unit: pixelsPerUnit * (cameraValid ? camera.zoom : 1)

    // World -> item coordinates. The scene camera is at the centre of the viewport.
    function toItem(wx, wy) {
        const cx = cameraValid ? camera.x : 0;
        const cy = cameraValid ? camera.y : 0;
        return Qt.point(width / 2 + (wx - cx) * unit, height / 2 - (wy - cy) * unit);
    }

    function rectOf(entry) {
        const centre = toItem(entry.position[0], entry.position[1]);
        const w = Math.abs(entry.size[0]) * unit;
        const h = Math.abs(entry.size[1]) * unit;
        return Qt.rect(centre.x - w / 2, centre.y - h / 2, w, h);
    }

    function isCamera(entry) {
        return cameraValid && entry.id === camera.id && entry.generation === camera.generation;
    }

    // Topmost drawn entity under the point: highest render order, then the one created last.
    function entityAt(x, y) {
        let best = null;
        for (const entry of root.layout || []) {
            if (!entry.drawn || isCamera(entry)) continue;
            const r = rectOf(entry);
            if (x < r.x || x > r.x + r.width || y < r.y || y > r.y + r.height) continue;
            if (!best || entry.renderOrder > best.renderOrder
                || (entry.renderOrder === best.renderOrder && entry.id > best.id)) {
                best = entry;
            }
        }
        return best;
    }

    readonly property var selectedEntry: {
        if (!root.selectedEntity) return null;
        for (const entry of root.layout || []) {
            if (entry.id === root.selectedEntity.id && entry.generation === root.selectedEntity.generation) return entry;
        }
        return null;
    }

    Rectangle {
        readonly property rect area: root.selectedEntry ? root.rectOf(root.selectedEntry) : Qt.rect(0, 0, 0, 0)

        visible: root.selectedEntry !== null && !root.isCamera(root.selectedEntry)
        x: area.x
        y: area.y
        width: area.width
        height: area.height
        color: "transparent"
        border.color: Theme.primaryColor
        border.width: 2 / root.zoom
    }

    MouseArea {
        id: dragArea

        property var dragged: null
        property point start
        property var startPosition: []
        property bool moving: false

        anchors.fill: parent
        preventStealing: true

        onPressed: mouse => {
            const entry = root.entityAt(mouse.x, mouse.y);
            if (!entry) {
                mouse.accepted = false; // let the Flickable pan
                return;
            }
            dragged = entry;
            start = Qt.point(mouse.x, mouse.y);
            startPosition = entry.position.slice();
            moving = false;
            root.entityPicked(entry.id, entry.generation);
        }

        onPositionChanged: mouse => {
            if (!dragged) return;
            const dx = mouse.x - start.x;
            const dy = mouse.y - start.y;
            if (!moving && Math.abs(dx) + Math.abs(dy) < 3 / root.zoom) return;
            moving = true;
            root.entityMoved(dragged.id, dragged.generation,
                [startPosition[0] + dx / root.unit, startPosition[1] - dy / root.unit, startPosition[2]]);
        }

        onReleased: dragged = null
        onCanceled: dragged = null
    }
}
