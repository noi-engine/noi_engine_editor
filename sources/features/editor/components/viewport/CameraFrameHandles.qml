import QtQuick

import noi_engine_editor

// The scene camera's red border (what it films in the game): drag its label to move the
// camera, its handles to resize it (symmetric around the centre, Shift on a corner keeps the
// proportions). Changes apply on release. Fills the viewport; only the label and handles
// take presses.
Item {
    id: root

    property Item viewport      // ViewportPanel: toScreen(), unit
    // OpenGLView.sceneCamera: {valid, id, generation, x, y, orthographicSize, aspectRatio, zoom}
    property var camera: ({})

    // OpenGLView.entityLayout, to count what the culling keeps.
    property var layout: []

    signal resized(real orthographicSize, real aspectRatio)
    signal moved(real x, real y)

    readonly property bool valid: !!camera && !!camera.valid
    // Size of the filmed area in world units.
    readonly property real worldHeight: valid ? 2 * camera.orthographicSize / camera.zoom : 0
    readonly property real worldWidth: worldHeight * (valid ? camera.aspectRatio : 0)

    // Live preview while dragging: world centre and size.
    property bool dragging: false
    property real previewX: 0
    property real previewY: 0
    property real previewWidth: 0
    property real previewHeight: 0

    readonly property real shownX: dragging ? previewX : (valid ? camera.x : 0)
    readonly property real shownY: dragging ? previewY : (valid ? camera.y : 0)
    readonly property real shownWidth: dragging ? previewWidth : worldWidth
    readonly property real shownHeight: dragging ? previewHeight : worldHeight

    readonly property point centre: valid ? viewport.toScreen(shownX, shownY) : Qt.point(0, 0)
    readonly property real frameWidth: shownWidth * viewport.unit
    readonly property real frameHeight: shownHeight * viewport.unit

    // ---- Culling (on the camera): area kept active = what the camera films + margin.
    readonly property bool cullingEnabled: valid && !!camera.cullingEnabled
    readonly property real cullingMargin: cullingEnabled ? camera.cullingMargin : 0
    readonly property string cullingSummary: {
        if (!cullingEnabled) return "";
        const halfW = worldWidth / 2 + cullingMargin, halfH = worldHeight / 2 + cullingMargin;
        let drawn = 0, kept = 0;
        for (const entry of root.layout || []) {
            if (!entry.drawn || (entry.id === camera.id && entry.generation === camera.generation)) continue;
            drawn++;
            const w = Math.abs(entry.size[0]) / 2, h = Math.abs(entry.size[1]) / 2;
            if (Math.abs(entry.position[0] - camera.x) <= halfW + w && Math.abs(entry.position[1] - camera.y) <= halfH + h) kept++;
        }
        return qsTr("culling: %1/%2 drawn").arg(kept).arg(drawn);
    }

    function startDrag() {
        previewX = camera.x;
        previewY = camera.y;
        previewWidth = worldWidth;
        previewHeight = worldHeight;
        dragging = true;
    }

    // Culling area: what stays drawn (and simulated) in the game, around the camera border.
    Rectangle {
        visible: root.cullingEnabled && !root.dragging
        x: frame.x - root.cullingMargin * root.viewport.unit
        y: frame.y - root.cullingMargin * root.viewport.unit
        width: frame.width + 2 * root.cullingMargin * root.viewport.unit
        height: frame.height + 2 * root.cullingMargin * root.viewport.unit
        color: "transparent"
        border.color: "#E0B85B"
        border.width: 2
        opacity: 0.8
    }

    Item {
        id: frame

        visible: root.valid
        x: root.centre.x - width / 2
        y: root.centre.y - height / 2
        width: root.frameWidth
        height: root.frameHeight

        // Preview outline while dragging (the red border itself updates on release).
        Rectangle {
            anchors.fill: parent
            visible: root.dragging
            color: "transparent"
            border.color: Theme.primaryColor
            border.width: 1.5
        }

        // Label: drag it to move the camera.
        Rectangle {
            x: 0
            y: -height - 4
            width: label.implicitWidth + 16
            height: 20
            radius: 4
            color: labelArea.containsMouse || labelArea.pressed ? Theme.primaryColor : "#C0392B"

            Text {
                id: label
                anchors.centerIn: parent
                text: root.dragging && root.previewWidth === root.worldWidth && root.previewHeight === root.worldHeight
                    ? qsTr("camera  %1, %2").arg(root.previewX.toFixed(2)).arg(root.previewY.toFixed(2))
                    : (root.dragging ? qsTr("%1 × %2 px").arg(Math.round(root.previewWidth * 100)).arg(Math.round(root.previewHeight * 100))
                                     : qsTr("camera  %1 × %2 px").arg(Math.round(root.worldWidth * 100)).arg(Math.round(root.worldHeight * 100))
                                       + (root.cullingSummary !== "" ? "  ·  " + root.cullingSummary : ""))
                font.pixelSize: 10
                color: Theme.white
            }

            MouseArea {
                id: labelArea

                property point start

                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: mouse => {
                    start = mapToItem(root, mouse.x, mouse.y);
                    root.startDrag();
                }
                onPositionChanged: mouse => {
                    if (!pressed) return;
                    const p = mapToItem(root, mouse.x, mouse.y);
                    root.previewX = root.camera.x + (p.x - start.x) / root.viewport.unit;
                    root.previewY = root.camera.y - (p.y - start.y) / root.viewport.unit;
                }
                onReleased: {
                    root.dragging = false;
                    if (root.previewX !== root.camera.x || root.previewY !== root.camera.y) {
                        root.moved(root.previewX, root.previewY);
                    }
                }
            }
        }

        Repeater {
            // Direction of each handle: -1 = left/top edge, 1 = right/bottom edge, 0 = middle.
            model: [
                {hx: -1, hy: -1}, {hx: 0, hy: -1}, {hx: 1, hy: -1},
                {hx: -1, hy: 0},                   {hx: 1, hy: 0},
                {hx: -1, hy: 1},  {hx: 0, hy: 1},  {hx: 1, hy: 1}
            ]

            delegate: Rectangle {
                id: handle

                required property var modelData

                x: (modelData.hx + 1) / 2 * frame.width - width / 2
                y: (modelData.hy + 1) / 2 * frame.height - height / 2
                width: 9
                height: 9
                radius: 2
                color: handleArea.containsMouse || handleArea.pressed ? Theme.primaryColor : Theme.white
                border.color: "#E05B5B"

                MouseArea {
                    id: handleArea

                    property point start

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
                        start = mapToItem(root, mouse.x, mouse.y);
                        root.startDrag();
                    }

                    onPositionChanged: mouse => {
                        if (!pressed) return;
                        const p = mapToItem(root, mouse.x, mouse.y);
                        const unit = root.viewport.unit;
                        let w = handle.modelData.hx === 0 ? root.worldWidth : root.worldWidth + 2 * (p.x - start.x) * handle.modelData.hx / unit;
                        let h = handle.modelData.hy === 0 ? root.worldHeight : root.worldHeight + 2 * (p.y - start.y) * handle.modelData.hy / unit;
                        if ((mouse.modifiers & Qt.ShiftModifier) && handle.modelData.hx !== 0 && handle.modelData.hy !== 0) {
                            const factor = Math.max(w / root.worldWidth, h / root.worldHeight);
                            w = root.worldWidth * factor;
                            h = root.worldHeight * factor;
                        }
                        root.previewWidth = Math.max(0.1, w);
                        root.previewHeight = Math.max(0.1, h);
                    }

                    onReleased: {
                        root.dragging = false;
                        if (root.previewWidth !== root.worldWidth || root.previewHeight !== root.worldHeight) {
                            root.resized(root.previewHeight * root.camera.zoom / 2, root.previewWidth / root.previewHeight);
                        }
                    }
                }
            }
        }
    }
}
