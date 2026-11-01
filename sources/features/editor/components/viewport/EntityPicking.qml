import QtQuick

import noi_engine_editor

// Select tool: click an entity to select it, drag it to move it, drag the handles of the
// selection to resize it (the opposite side stays put, Shift keeps the proportions). Presses
// on empty space fall through to ViewportNavigation (panning).
Item {
    id: root

    property Item viewport          // ViewportPanel: toScreen(), unit
    property var layout: []         // OpenGLView.entityLayout
    property var camera: ({})       // OpenGLView.sceneCamera
    property var selectedEntity: null

    signal entityPicked(int entityId, int entityGeneration)
    // scale is null when only the position changed.
    signal entityTransformed(int entityId, int entityGeneration, var position, var scale)

    function rectOf(entry) {
        const centre = viewport.toScreen(entry.position[0], entry.position[1]);
        const w = Math.abs(entry.size[0]) * viewport.unit;
        const h = Math.abs(entry.size[1]) * viewport.unit;
        return Qt.rect(centre.x - w / 2, centre.y - h / 2, w, h);
    }

    function isCamera(entry) {
        return !!camera && camera.valid && entry.id === camera.id && entry.generation === camera.generation;
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
            if (entry.id === root.selectedEntity.id && entry.generation === root.selectedEntity.generation
                && !isCamera(entry)) return entry;
        }
        return null;
    }

    // Moving: press on an entity, drag.
    MouseArea {
        property var dragged: null
        property point start
        property var startPosition: []
        property bool moving: false

        anchors.fill: parent
        preventStealing: true

        onPressed: mouse => {
            const entry = (mouse.modifiers & Qt.ShiftModifier) ? null : root.entityAt(mouse.x, mouse.y);
            if (!entry) {
                mouse.accepted = false; // empty space / Shift (zoom): ViewportNavigation handles it
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
            if (!moving && Math.abs(dx) + Math.abs(dy) < 3) return;
            moving = true;
            root.entityTransformed(dragged.id, dragged.generation,
                [startPosition[0] + dx / root.viewport.unit, startPosition[1] - dy / root.viewport.unit, startPosition[2]], null);
        }

        onReleased: dragged = null
        onCanceled: dragged = null
    }

    // Selection outline + resize handles.
    Item {
        id: selection

        readonly property rect area: root.selectedEntry ? root.rectOf(root.selectedEntry) : Qt.rect(0, 0, 0, 0)

        visible: root.selectedEntry !== null
        x: area.x
        y: area.y
        width: area.width
        height: area.height

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.primaryColor
            border.width: 2
        }

        Repeater {
            // -1 = left / top, 1 = right / bottom, 0 = middle (screen directions).
            model: [
                {hx: -1, hy: -1}, {hx: 0, hy: -1}, {hx: 1, hy: -1},
                {hx: -1, hy: 0},                   {hx: 1, hy: 0},
                {hx: -1, hy: 1},  {hx: 0, hy: 1},  {hx: 1, hy: 1}
            ]

            delegate: Rectangle {
                id: handle

                required property var modelData

                x: (modelData.hx + 1) / 2 * selection.width - width / 2
                y: (modelData.hy + 1) / 2 * selection.height - height / 2
                width: 9
                height: 9
                radius: 2
                color: handleArea.containsMouse || handleArea.pressed ? Theme.primaryColor : Theme.white
                border.color: Theme.primaryColor

                MouseArea {
                    id: handleArea

                    property point start
                    property var startPosition: []
                    property var startScale: []

                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: {
                        if (handle.modelData.hx === 0) return Qt.SizeVerCursor;
                        if (handle.modelData.hy === 0) return Qt.SizeHorCursor;
                        return handle.modelData.hx === handle.modelData.hy ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor;
                    }

                    onPressed: mouse => {
                        const entry = root.selectedEntry;
                        start = mapToItem(root, mouse.x, mouse.y);
                        startPosition = entry.position.slice();
                        startScale = [entry.size[0], entry.size[1]];
                    }

                    onPositionChanged: mouse => {
                        if (!pressed || !root.selectedEntry) return;
                        const p = mapToItem(root, mouse.x, mouse.y);
                        const hx = handle.modelData.hx;
                        const hy = -handle.modelData.hy; // world y goes up
                        const dxWorld = (p.x - start.x) / root.viewport.unit;
                        const dyWorld = -(p.y - start.y) / root.viewport.unit;

                        let w = hx === 0 ? startScale[0] : startScale[0] + hx * dxWorld;
                        let h = hy === 0 ? startScale[1] : startScale[1] + hy * dyWorld;
                        if ((mouse.modifiers & Qt.ShiftModifier) && hx !== 0 && hy !== 0) {
                            const factor = Math.max(w / startScale[0], h / startScale[1]);
                            w = startScale[0] * factor;
                            h = startScale[1] * factor;
                        }
                        const minimum = 4 / root.viewport.unit;
                        w = Math.max(minimum, w);
                        h = Math.max(minimum, h);

                        // Keep the opposite side where it is.
                        const x = startPosition[0] + hx * (w - startScale[0]) / 2;
                        const y = startPosition[1] + hy * (h - startScale[1]) / 2;
                        root.entityTransformed(root.selectedEntry.id, root.selectedEntry.generation,
                            [x, y, startPosition[2]], [w, h, 1]);
                    }
                }
            }
        }
    }
}
