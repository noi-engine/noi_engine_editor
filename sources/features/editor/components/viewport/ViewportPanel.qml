import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import noi_engine_editor

Item {
    id: root

    property string scenePath: ""
    property var selectedEntity: null

    readonly property alias loadedResources: openGLView.loadedResources
    readonly property alias loadedEntities: openGLView.loadedEntities
    readonly property alias inspectedComponents: openGLView.inspectedComponents
    property alias hasInspectedEntity: openGLView.hasInspectedEntity
    property alias inspectedEntityId: openGLView.inspectedEntityId
    property alias inspectedEntityGeneration: openGLView.inspectedEntityGeneration

    readonly property alias inspectedMaterialProperties: openGLView.inspectedMaterialProperties
    property alias hasInspectedMaterial: openGLView.hasInspectedMaterial
    property alias inspectedMaterialId: openGLView.inspectedMaterialId
    property alias inspectedMaterialGeneration: openGLView.inspectedMaterialGeneration

    readonly property alias playing: openGLView.playing

    signal sceneSaved(bool success)
    signal entityCreated(int entityId, int entityGeneration)
    // The scene camera was moved / resized with its red border.
    signal cameraEdited()
    // Clicked / dragged in the viewport.
    signal entityPicked(int entityId, int entityGeneration)
    signal entityMoved()
    // An image file dropped on the viewport, at a world position.
    signal imageDropped(string filePath, real x, real y)

    readonly property var sceneCamera: openGLView.sceneCamera

    Connections {
        target: openGLView
        function onSceneSaved(success) { root.sceneSaved(success) }
        function onEntityCreated(entityId, entityGeneration) { root.entityCreated(entityId, entityGeneration) }
    }

    function setPlaying(playing) {
        openGLView.setPlaying(playing)
    }

    function saveScene() {
        openGLView.saveScene()
    }

    // Forces a reload of the currently-open scene from disk - used after editor tooling (the
    // Inspector's texture import) edits the scene file directly, outside the normal
    // propertyEdited/componentAddRequested bridge-call path.
    function reloadScene() {
        openGLView.reloadScene()
    }

    function setComponentProperty(entityId, entityGeneration, componentType, propertyName, propertyType, value) {
        openGLView.setComponentProperty(entityId, entityGeneration, componentType, propertyName, propertyType, value)
    }

    function addComponent(entityId, entityGeneration, componentType) {
        openGLView.addComponent(entityId, entityGeneration, componentType)
    }

    function removeComponent(entityId, entityGeneration, componentType) {
        openGLView.removeComponent(entityId, entityGeneration, componentType)
    }

    function removeComponentProperty(entityId, entityGeneration, componentType, propertyName) {
        openGLView.removeComponentProperty(entityId, entityGeneration, componentType, propertyName)
    }

    function setMaterialProperty(materialId, materialGeneration, propertyName, propertyType, value) {
        openGLView.setMaterialProperty(materialId, materialGeneration, propertyName, propertyType, value)
    }

    function removeMaterialProperty(materialId, materialGeneration, propertyName) {
        openGLView.removeMaterialProperty(materialId, materialGeneration, propertyName)
    }

    function createEntity(name) {
        openGLView.createEntity(name)
    }

    function destroyEntity(entityId, entityGeneration) {
        openGLView.destroyEntity(entityId, entityGeneration)
    }

    function duplicateEntity(entityId, entityGeneration, newName) {
        openGLView.duplicateEntity(entityId, entityGeneration, newName)
    }

    // "select": click to select, drag to move / resize; "pan": drag to move the view.
    property string activeTool: "select"

    // ---- The editor's view: where it looks (world units) and its zoom. The scene camera keeps
    // its own position, shown by the red border.
    property real viewX: 0
    property real viewY: 0
    property real viewZoom: 1
    readonly property real minZoom: 0.05
    readonly property real maxZoom: 20
    // Logical pixels per world unit at zoom 1 (the bridge maps 100 device pixels to one unit).
    readonly property real pixelsPerUnit: 100 / Screen.devicePixelRatio
    readonly property real unit: pixelsPerUnit * viewZoom

    function toScreen(wx, wy) {
        return Qt.point(width / 2 + (wx - viewX) * unit, height / 2 - (wy - viewY) * unit);
    }

    function toWorld(sx, sy) {
        return Qt.point(viewX + (sx - width / 2) / unit, viewY - (sy - height / 2) / unit);
    }

    // Zooms keeping the world point under (sx, sy) where it is.
    function zoomAt(factor, sx, sy) {
        const before = toWorld(sx, sy);
        viewZoom = Math.min(maxZoom, Math.max(minZoom, viewZoom * factor));
        const after = toWorld(sx, sy);
        viewX += before.x - after.x;
        viewY += before.y - after.y;
    }

    function zoomBy(factor) {
        zoomAt(factor, width / 2, height / 2);
    }

    function panBy(dx, dy) {
        viewX -= dx / unit;
        viewY += dy / unit;
    }

    // Fits a world rectangle (centre + size) in the view, with a margin.
    function frameRect(cx, cy, w, h) {
        if (!(w > 0 && h > 0) || width <= 0 || height <= 0) return;
        viewX = cx;
        viewY = cy;
        viewZoom = Math.min(maxZoom, Math.max(minZoom,
            Math.min(width * 0.85 / (w * pixelsPerUnit), height * 0.85 / (h * pixelsPerUnit))));
    }

    function frameCamera() {
        const cam = openGLView.sceneCamera;
        if (!cam || !cam.valid) return;
        const h = 2 * cam.orthographicSize / cam.zoom;
        frameRect(cam.x, cam.y, h * cam.aspectRatio, h);
    }

    function frameSelection() {
        if (!root.selectedEntity) return frameCamera();
        for (const entry of openGLView.entityLayout || []) {
            if (entry.id === root.selectedEntity.id && entry.generation === root.selectedEntity.generation) {
                return frameRect(entry.position[0], entry.position[1],
                    Math.max(1, Math.abs(entry.size[0]) * 3), Math.max(1, Math.abs(entry.size[1]) * 3));
            }
        }
        frameCamera();
    }

    readonly property bool sceneShown: root.scenePath !== "" && !!openGLView.sceneCamera.valid

    // The view is saved with the project and restored (or fitted to the camera the first time).
    ViewportViewState {
        viewport: root
        sceneShown: root.sceneShown
    }

    Shortcut {
        sequences: ["Ctrl+=", "Ctrl++"]
        enabled: root.sceneShown
        onActivated: root.zoomBy(1.25)
    }
    Shortcut {
        sequence: "Ctrl+-"
        enabled: root.sceneShown
        onActivated: root.zoomBy(0.8)
    }
    Shortcut {
        sequence: "Ctrl+0"
        enabled: root.sceneShown
        onActivated: root.frameCamera()
    }
    Shortcut {
        sequence: "F"
        enabled: root.sceneShown
        onActivated: root.frameSelection()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        clip: true

        OpenGLView {
            id: openGLView
            anchors.fill: parent
            visible: root.scenePath !== ""
            // OpenGL renders into the FBO bottom-up; QQuickFramebufferObject does not
            // correct for that by default, so the preview is displayed upside down.
            mirrorVertically: true
            scenePath: root.scenePath
            resourcesPath: CurrentProjectManager.resourcesPath()
            scriptsLibraryPath: CurrentProjectManager.scriptsLibraryPath()
            bridgeLibraryPath: CurrentProjectManager.bridgeLibraryPath()
            engineLibraryPath: CurrentProjectManager.engineLibraryPath()
            scriptsGeneration: ProjectBuilder.compileGeneration
            engineVersion: CurrentProjectManager.engineVersion
            gameWidth: CurrentProjectManager.windowWidth
            gameHeight: CurrentProjectManager.windowHeight
            editorView: [root.viewX, root.viewY, root.viewZoom]
        }

        // Pan (middle button anywhere, left button with the pan tool or on empty space) and
        // wheel zoom. Below the picking / handles, which take the presses they need.
        ViewportNavigation {
            anchors.fill: parent
            visible: root.scenePath !== ""
            viewport: root
        }

        EntityPicking {
            anchors.fill: parent
            visible: root.scenePath !== "" && !root.playing
            enabled: root.activeTool === "select" && !root.playing
            viewport: root
            layout: openGLView.entityLayout
            camera: openGLView.sceneCamera
            selectedEntity: root.selectedEntity

            onEntityPicked: (entityId, entityGeneration) => root.entityPicked(entityId, entityGeneration)
            onEntityTransformed: (entityId, entityGeneration, position, scale) => {
                openGLView.setComponentProperty(entityId, entityGeneration, "transform", "position", "vec3", position);
                if (scale) openGLView.setComponentProperty(entityId, entityGeneration, "transform", "scale", "vec3", scale);
                root.entityMoved();
            }
        }

        CameraFrameHandles {
            anchors.fill: parent
            visible: root.scenePath !== "" && !root.playing
            enabled: root.activeTool === "select" && !root.playing
            viewport: root
            camera: openGLView.sceneCamera
            layout: openGLView.entityLayout

            onResized: (orthographicSize, aspectRatio) => {
                const cam = openGLView.sceneCamera;
                openGLView.setComponentProperty(cam.id, cam.generation, "camera_2d", "orthographic_size", "float", orthographicSize);
                openGLView.setComponentProperty(cam.id, cam.generation, "camera_2d", "aspect_ratio", "float", aspectRatio);
                root.cameraEdited();
            }
            onMoved: (x, y) => {
                const cam = openGLView.sceneCamera;
                openGLView.setComponentProperty(cam.id, cam.generation, "transform", "position", "vec3", [x, y, 0]);
                root.cameraEdited();
            }
        }

        // Images dragged from the Folder Resources panel become sprites where they're dropped.
        DropArea {
            anchors.fill: parent
            enabled: root.scenePath !== "" && !root.playing
            keys: ["text/uri-list"]

            onDropped: drop => {
                if (!drop.hasUrls) return;
                const path = decodeURIComponent(drop.urls[0].toString().replace(/^file:\/\//, ""));
                if (!/\.(png|jpe?g|bmp|tga|gif)$/i.test(path)) return;
                const world = root.toWorld(drop.x, drop.y);
                root.imageDropped(path, world.x, world.y);
                drop.accept(Qt.CopyAction);
            }
        }

        ViewportToolbar {
            x: 16
            y: 16
            visible: root.scenePath !== ""
            viewport: root
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            visible: root.scenePath === ""

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 32
                color: Theme.bgSecondary
                border.color: Theme.borderColor
                border.width: 1

                MuiIcon {
                    anchors.centerIn: parent
                    name: "landscape"
                    font.pixelSize: 32
                    color: Theme.primaryColor
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No Scene Loaded")
                color: Theme.white
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Double-click a scene in the Scenes panel to open it.")
                color: Theme.darkGrey
                font.pixelSize: 11
            }
        }
    }
}
