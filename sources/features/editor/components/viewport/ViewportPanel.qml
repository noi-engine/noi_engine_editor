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
    // The scene camera was resized with the handles on its red border.
    signal cameraEdited()
    // Clicked / dragged in the viewport.
    signal entityPicked(int entityId, int entityGeneration)
    signal entityMoved()

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

    property string activeTool: "select"
    property real cameraZoom: 1.0
    property alias gridVisible: openGLView.gridVisible

    property real worldWidth: CurrentProjectManager.windowWidth
    property real worldHeight: CurrentProjectManager.windowHeight

    // Zoom, world size and scroll are saved with the project and restored.
    ViewportViewState {
        viewport: root
        flickable: viewportFlickable
        sceneShown: !!openGLView.sceneCamera.valid
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        clip: true

        Flickable {
            id: viewportFlickable
            anchors.fill: parent
            visible: root.scenePath !== ""
            clip: true

            boundsBehavior: Flickable.StopAtBounds
            // In the select tool, a press on an entity is taken by EntityPicking; anywhere else pans.
            interactive: true

            contentWidth: Math.max(viewportFlickable.width, container.width * root.cameraZoom)
            contentHeight: Math.max(viewportFlickable.height, container.height * root.cameraZoom)

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: viewportFlickable.moving || viewportFlickable.flicking || viewportFlickable.activeFocus
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: viewportFlickable.moving || viewportFlickable.flicking || viewportFlickable.activeFocus
            }

            Item {
                id: container
                // Large enough to show the whole camera border and its handles. Only grows, so
                // the view doesn't jump when the camera is made smaller.
                property real fitWidth: 0
                property real fitHeight: 0
                readonly property real cameraFitWidth: cameraHandles.cameraWidth + 160
                readonly property real cameraFitHeight: cameraHandles.cameraHeight + 160
                onCameraFitWidthChanged: fitWidth = Math.max(fitWidth, cameraFitWidth)
                onCameraFitHeightChanged: fitHeight = Math.max(fitHeight, cameraFitHeight)

                width: Math.max(root.worldWidth, fitWidth)
                height: Math.max(root.worldHeight, fitHeight)

                transform: Scale {
                    xScale: root.cameraZoom
                    yScale: root.cameraZoom
                    origin.x: 0
                    origin.y: 0
                }

                OpenGLView {
                    id: openGLView
                    anchors.fill: parent
                    // OpenGL renders into the FBO bottom-up; QQuickFramebufferObject does not
                    // correct for that by default, so the preview is displayed upside down.
                    // Invisible on symmetric content (grid, border), but it inverts the
                    // perceived direction of any vertical movement - see mirrorVertically's docs.
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
                }

                // Cursor only: presses go to EntityPicking / the Flickable.
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: {
                        if (root.activeTool === "move") {
                            return pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        }
                        return Qt.ArrowCursor
                    }

                }

                EntityPicking {
                    anchors.fill: parent
                    visible: !root.playing
                    enabled: root.activeTool === "select" && !root.playing
                    layout: openGLView.entityLayout
                    camera: openGLView.sceneCamera
                    pixelsPerUnit: 100 / Screen.devicePixelRatio
                    zoom: root.cameraZoom
                    selectedEntity: root.selectedEntity

                    onEntityPicked: (entityId, entityGeneration) => root.entityPicked(entityId, entityGeneration)
                    onEntityMoved: (entityId, entityGeneration, position) => {
                        openGLView.setComponentProperty(entityId, entityGeneration, "transform", "position", "vec3", position);
                        root.entityMoved();
                    }
                }

                CameraFrameHandles {
                    id: cameraHandles
                    // The bridge maps PIXELS_PER_UNIT (100) device pixels to one world unit.
                    camera: openGLView.sceneCamera
                    pixelsPerUnit: 100 / Screen.devicePixelRatio
                    zoom: root.cameraZoom
                    enabled: !root.playing
                    opacity: root.playing ? 0 : 1

                    onResized: (orthographicSize, aspectRatio) => {
                        const cam = openGLView.sceneCamera;
                        openGLView.setComponentProperty(cam.id, cam.generation, "camera_2d", "orthographic_size", "float", orthographicSize);
                        openGLView.setComponentProperty(cam.id, cam.generation, "camera_2d", "aspect_ratio", "float", aspectRatio);
                        root.cameraEdited();
                    }
                }
            }
        }

        ViewportToolbar {
            x: 20
            y: 20
            visible: root.scenePath !== ""
            activeTool: root.activeTool
            zoomValue: root.cameraZoom
            gridVisible: root.gridVisible

            onToolChanged: (tool) => root.activeTool = tool
            onGridVisibleToggled: (visible) => root.gridVisible = visible
            onZoomInRequested: root.cameraZoom += 0.25
            onZoomOutRequested: root.cameraZoom = Math.max(0.1, root.cameraZoom - 0.25)
            onZoomResetRequested: root.cameraZoom = 1.0
            onSetZoomRequested: (zoom) => root.cameraZoom = zoom
            onResetAllRequested: {
                root.cameraZoom = 1.0
                viewportFlickable.contentX = 0
                viewportFlickable.contentY = 0
            }

            onModifyWorldSizeRequested: (factor) => {
                if (factor === 0.0) {
                    root.worldWidth = CurrentProjectManager.windowWidth
                    root.worldHeight = CurrentProjectManager.windowHeight
                } else {
                    root.worldWidth = Math.max(CurrentProjectManager.windowWidth, root.worldWidth * factor)
                    root.worldHeight = Math.max(CurrentProjectManager.windowHeight, root.worldHeight * factor)
                }
            }
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