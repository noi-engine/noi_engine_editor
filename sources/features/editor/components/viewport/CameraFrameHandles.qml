import QtQuick

import noi_engine_editor

// Resize handles on the scene camera's red border. The camera is always at the centre of the
// viewport, so the frame is centred and resizing is symmetric. Hold Shift on a corner to keep
// the aspect ratio. The new size is applied on release.
Item {
    id: root

    // OpenGLView.sceneCamera: {valid, id, generation, orthographicSize, aspectRatio}
    property var camera: ({})
    // Logical pixels per world unit in the parent's (unzoomed) coordinates.
    property real pixelsPerUnit: 100
    // Parent's zoom factor, so handles keep the same on-screen size.
    property real zoom: 1

    signal resized(real orthographicSize, real aspectRatio)

    readonly property bool valid: !!camera && !!camera.valid
    readonly property real cameraWidth: valid ? 2 * camera.orthographicSize * camera.aspectRatio * pixelsPerUnit : 0
    readonly property real cameraHeight: valid ? 2 * camera.orthographicSize * pixelsPerUnit : 0

    property bool dragging: false
    property real dragWidth: 0
    property real dragHeight: 0

    readonly property real minimumSize: 8 / zoom

    visible: valid
    width: dragging ? dragWidth : cameraWidth
    height: dragging ? dragHeight : cameraHeight
    x: ((parent ? parent.width : 0) - width) / 2
    y: ((parent ? parent.height : 0) - height) / 2

    // Preview of the new size while dragging (the red border itself updates on release).
    Rectangle {
        anchors.fill: parent
        visible: root.dragging
        color: "transparent"
        border.color: Theme.primaryColor
        border.width: 1.5 / root.zoom
    }

    Rectangle {
        visible: root.dragging
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 6 / root.zoom
        width: sizeLabel.implicitWidth + 12 / root.zoom
        height: sizeLabel.implicitHeight + 6 / root.zoom
        radius: 4 / root.zoom
        color: Theme.bgTertiary

        Text {
            id: sizeLabel
            anchors.centerIn: parent
            text: qsTr("%1 × %2 units").arg((root.dragWidth / root.pixelsPerUnit).toFixed(2))
                .arg((root.dragHeight / root.pixelsPerUnit).toFixed(2))
            font.pixelSize: 11 / root.zoom
            color: Theme.white
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
            readonly property real size: 9 / root.zoom

            x: (modelData.hx + 1) / 2 * root.width - size / 2
            y: (modelData.hy + 1) / 2 * root.height - size / 2
            width: size
            height: size
            radius: 2 / root.zoom
            color: handleArea.containsMouse || handleArea.pressed ? Theme.primaryColor : Theme.white
            border.color: "#E05B5B"
            border.width: 1 / root.zoom

            MouseArea {
                id: handleArea

                property point start
                property real startWidth
                property real startHeight

                anchors.fill: parent
                anchors.margins: -4 / root.zoom
                hoverEnabled: true
                preventStealing: true
                cursorShape: {
                    if (handle.modelData.hx === 0) return Qt.SizeVerCursor;
                    if (handle.modelData.hy === 0) return Qt.SizeHorCursor;
                    return handle.modelData.hx === handle.modelData.hy ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor;
                }

                onPressed: mouse => {
                    start = mapToItem(root.parent, mouse.x, mouse.y);
                    startWidth = root.cameraWidth;
                    startHeight = root.cameraHeight;
                    root.dragWidth = startWidth;
                    root.dragHeight = startHeight;
                    root.dragging = true;
                }

                onPositionChanged: mouse => {
                    if (!pressed) return;
                    const p = mapToItem(root.parent, mouse.x, mouse.y);
                    let w = startWidth + 2 * (p.x - start.x) * handle.modelData.hx;
                    let h = startHeight + 2 * (p.y - start.y) * handle.modelData.hy;
                    if (handle.modelData.hx === 0) w = startWidth;
                    if (handle.modelData.hy === 0) h = startHeight;

                    if ((mouse.modifiers & Qt.ShiftModifier) && handle.modelData.hx !== 0 && handle.modelData.hy !== 0) {
                        const factor = Math.max(w / startWidth, h / startHeight);
                        w = startWidth * factor;
                        h = startHeight * factor;
                    }

                    root.dragWidth = Math.max(root.minimumSize, w);
                    root.dragHeight = Math.max(root.minimumSize, h);
                }

                onReleased: {
                    root.dragging = false;
                    if (root.dragWidth !== startWidth || root.dragHeight !== startHeight) {
                        root.resized(root.dragHeight / (2 * root.pixelsPerUnit), root.dragWidth / root.dragHeight);
                    }
                }
            }
        }
    }
}
