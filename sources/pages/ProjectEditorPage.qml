import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

CustomPage {
    id: root

    title: CurrentProjectManager.name

    property var selectedEntity: null
    property var selectedMaterial: null
    property string activeBottomPanel: ""
    property string currentScenePath: ""
    property string pendingScenePath: ""
    property bool compileFailureDismissed: false
    property bool sceneDirty: false
    // What to do with each queued entity create/duplicate, in order ({folder, preset}; folder
    // null = leave as is), applied when the bridge reports the new entity.
    property var pendingCreates: []

    // ---- Images from the resources folder as sprites / backgrounds.
    // Waiting for the image's texture to be loaded (after the scene reload that declares it).
    property var pendingImageSprite: null

    function imageName(path) {
        const file = path.substring(path.lastIndexOf("/") + 1);
        const dot = file.lastIndexOf(".");
        return dot > 0 ? file.substring(0, dot) : file;
    }

    // Puts an image of the resources folder in the open scene: at its own size (100 pixels per
    // world unit) at (x, y), or as a background covering the camera behind everything else.
    function createImageSprite(path, background, x, y) {
        if (root.currentScenePath === "" || viewportPanel.playing) return;
        imageProbe.source = "file://" + path;
        const width = imageProbe.sourceSize.width > 0 ? imageProbe.sourceSize.width : 100;
        const height = imageProbe.sourceSize.height > 0 ? imageProbe.sourceSize.height : 100;

        const label = textureDeclarer.declareImage(path);
        if (label === "") {
            console.warn("Can't use " + path + ": " + textureDeclarer.errorText);
            return;
        }

        let w = width / 100, h = height / 100;
        const cam = viewportPanel.sceneCamera;
        if (background && cam && cam.valid) {
            const camHeight = 2 * cam.orthographicSize / cam.zoom;
            const factor = Math.max(camHeight * cam.aspectRatio / w, camHeight / h);
            w *= factor;
            h *= factor;
            x = cam.x;
            y = cam.y;
        }
        root.pendingImageSprite = {
            label: label, background: background, position: [x, y, 0], scale: [w, h, 1],
            name: background ? "background" : root.imageName(path)
        };
        root.createPendingImageSprite();
    }

    function createPendingImageSprite() {
        const pending = root.pendingImageSprite;
        if (!pending) return;
        if (!(viewportPanel.loadedResources || []).some(r => r.type === "texture" && r.label === pending.label)) return;
        root.pendingImageSprite = null;
        root.pendingCreates = root.pendingCreates.concat([{folder: null, preset: "image", image: pending}]);
        viewportPanel.createEntity(pending.name);
        root.sceneDirty = true;
    }

    Image {
        id: imageProbe
        visible: false
        asynchronous: false
    }

    ImportTextureDialog {
        id: textureDeclarer
        resourcesPath: CurrentProjectManager.resourcesPath()
        scenePath: root.currentScenePath
        onReloadRequested: root.reloadSceneKeepingEdits()
    }

    Connections {
        target: viewportPanel
        function onLoadedResourcesChanged() { root.createPendingImageSprite(); }
        // Keep the selection's data (name, folder, groups, components) up to date.
        function onLoadedEntitiesChanged() {
            if (!root.selectedEntity) return;
            for (const entity of viewportPanel.loadedEntities || []) {
                if (entity.id === root.selectedEntity.id && entity.generation === root.selectedEntity.generation) {
                    root.selectedEntity = entity;
                    return;
                }
            }
            // A scene reload (scripts recompiled, Play stopped) can renumber entities: same name.
            const sameName = (viewportPanel.loadedEntities || []).filter(e => e.name !== "" && e.name === root.selectedEntity.name);
            root.selectedEntity = sameName.length === 1 ? sameName[0] : null; // else it was deleted
        }
    }

    // Components of the Hierarchy's entity presets (see EntityPresetMenu). Adds are applied
    // before property edits, so everything lands in the same frame.
    function applyEntityPreset(entity, preset, image) {
        if (preset === "" || preset === "empty") return;
        if (preset === "image") {
            const id = entity.id, gen = entity.generation;
            viewportPanel.addComponent(id, gen, "transform");
            viewportPanel.addComponent(id, gen, "render_layer");
            viewportPanel.addComponent(id, gen, "mesh_renderer");
            viewportPanel.addComponent(id, gen, "mesh_renderer_properties");
            viewportPanel.setComponentProperty(id, gen, "transform", "position", "vec3", image.position);
            viewportPanel.setComponentProperty(id, gen, "transform", "scale", "vec3", image.scale);
            if (image.background) {
                viewportPanel.setComponentProperty(id, gen, "render_layer", "order", "float", -100);
                viewportPanel.addComponent(id, gen, "fill_screen"); // always the size of the window
            }
            viewportPanel.setComponentProperty(id, gen, "mesh_renderer", "material", "resourceRef", "materials:texture");
            viewportPanel.setComponentProperty(id, gen, "mesh_renderer_properties", "texture:u_texture", "resourceRef", image.label);
            root.setEntityGroups(entity, ["sprite"]);
            return;
        }
        const id = entity.id, gen = entity.generation;
        viewportPanel.addComponent(id, gen, "transform");
        viewportPanel.addComponent(id, gen, "render_layer");
        viewportPanel.addComponent(id, gen, "mesh_renderer");
        viewportPanel.addComponent(id, gen, "mesh_renderer_properties");
        if (preset === "background") {
            viewportPanel.addComponent(id, gen, "fill_screen");
            viewportPanel.setComponentProperty(id, gen, "render_layer", "order", "float", -100);
            viewportPanel.setComponentProperty(id, gen, "mesh_renderer_properties", "color:u_color", "vec4", [0.53, 0.81, 0.92, 1]);
            root.setEntityGroups(entity, ["sprite"]);
            return;
        }
        viewportPanel.setComponentProperty(id, gen, "mesh_renderer_properties", "color:u_color", "vec4", [0.85, 0.85, 0.85, 1]);
        root.setEntityGroups(entity, ["sprite"]);
        if (preset === "static_platform" || preset === "physics_body") {
            viewportPanel.addComponent(id, gen, "box_collider");
        }
        if (preset === "static_platform") {
            viewportPanel.setComponentProperty(id, gen, "box_collider", "is_static", "bool", true);
        }
        if (preset === "physics_body") {
            viewportPanel.addComponent(id, gen, "gravity");
        }
    }

    // The start scene's camera (red border) and the game window share one size, in pixels
    // (100 pixels per world unit at zoom 1).
    function normalizedPath(path) {
        return (path || "").replace(/\\/g, "/").replace(/\/+/g, "/");
    }

    function isStartSceneOpen() {
        const start = root.normalizedPath(CurrentProjectManager.startScene).replace(/^\//, "");
        return start !== "" && root.normalizedPath(root.currentScenePath).endsWith("/" + start);
    }

    // A resolution set in the Settings while the start scene wasn't open: applied to its
    // camera as soon as it opens.
    property var pendingCameraSize: null

    function syncWindowToCamera() {
        const cam = viewportPanel.sceneCamera;
        if (!root.isStartSceneOpen() || !cam || !cam.valid) return;
        CurrentProjectManager.windowWidth = Math.round(2 * cam.orthographicSize * cam.aspectRatio * 100);
        CurrentProjectManager.windowHeight = Math.round(2 * cam.orthographicSize * 100);
        CurrentProjectManager.saveProject();
    }

    function setCameraSize(width, height) {
        const cam = viewportPanel.sceneCamera;
        if (!root.isStartSceneOpen() || !cam || !cam.valid) {
            root.pendingCameraSize = {width: width, height: height};
            return;
        }
        root.pendingCameraSize = null;
        viewportPanel.setComponentProperty(cam.id, cam.generation, "camera_2d", "orthographic_size", "float", height / 200);
        viewportPanel.setComponentProperty(cam.id, cam.generation, "camera_2d", "aspect_ratio", "float", width / height);
        root.sceneDirty = true;
    }

    function setEntityGroups(entity, groups) {
        if (groups.length === 0) {
            viewportPanel.removeComponent(entity.id, entity.generation, "groups")
        } else {
            viewportPanel.addComponent(entity.id, entity.generation, "groups")
            viewportPanel.setComponentProperty(entity.id, entity.generation, "groups", "names", "string", groups.join(","))
        }
        root.sceneDirty = true;
    }

    // Reloading the scene from disk (after an image import wrote it into the scene's resources)
    // would lose unsaved edits: save first, then reload once the save is done.
    property bool reloadAfterSave: false

    function reloadSceneKeepingEdits() {
        if (root.sceneDirty) {
            root.reloadAfterSave = true;
            viewportPanel.saveScene();
        } else {
            viewportPanel.reloadScene();
        }
    }

    function setEntityFolder(entity, folder) {
        if (folder === "") {
            viewportPanel.removeComponent(entity.id, entity.generation, "folder")
        } else {
            // Adds are applied before property edits, so both land in the same frame.
            viewportPanel.addComponent(entity.id, entity.generation, "folder")
            viewportPanel.setComponentProperty(entity.id, entity.generation, "folder", "path", "string", folder)
        }
        root.sceneDirty = true;
    }

    // ---- Leaving the open scene: unsaved changes are saved (and the save confirmed by the
    // bridge) or explicitly dropped first.
    property var afterSave: null // what to do once the pending save succeeded

    function sceneName(path) {
        return (path || "").substring((path || "").lastIndexOf("/") + 1);
    }

    function leaveScene(actionText, action) {
        if (!root.sceneDirty || root.currentScenePath === "") {
            action();
            return;
        }
        unsavedDialog.pendingAction = action;
        unsavedDialog.ask(root.sceneName(root.currentScenePath), actionText);
    }

    function openScene(filePath) {
        if (viewportPanel.playing || filePath === root.currentScenePath) {
            return;
        }
        root.leaveScene(qsTr("opening %1").arg(root.sceneName(filePath)), () => root.switchScene(filePath));
    }

    function switchScene(filePath) {
        root.selectedEntity = null;
        root.selectedMaterial = null;
        if (ProjectBuilder.isCompiling || ProjectBuilder.lastCompileFailed) {
            root.pendingScenePath = filePath;
        } else {
            root.currentScenePath = filePath;
            root.sceneDirty = false;
        }
    }

    function saveCurrentScene() {
        if (root.currentScenePath === "" || viewportPanel.playing) {
            return;
        }
        viewportPanel.saveScene();
    }

    Shortcut {
        sequence: StandardKey.Save
        onActivated: root.saveCurrentScene()
    }

    Shortcut {
        sequences: ["Ctrl+K", "Ctrl+P"]
        enabled: !viewportPanel.playing
        onActivated: globalSearch.open()
    }

    GlobalSearchPopup {
        id: globalSearch
        parent: Overlay.overlay
        entities: viewportPanel.loadedEntities
        resources: viewportPanel.loadedResources
        resourcesRoot: CurrentProjectManager.resourcesPath()

        onAboutToShow: scenePaths = CurrentProjectResourcesManager.getAllScenesRecursively(CurrentProjectManager.resourcesPath())

        onEntityChosen: (entity) => {
            root.selectedMaterial = null;
            root.selectedEntity = entity;
        }
        onSceneChosen: (filePath) => root.openScene(filePath)
        onResourceChosen: (resource) => {
            if (resource.type === "material") {
                root.selectedEntity = null;
                root.selectedMaterial = resource;
            }
            root.activeBottomPanel = "loadedResources";
        }
    }

    Component.onCompleted: {
        ProjectBuilder.compile(CurrentProjectManager.path);
        // Open the project's start scene (it waits for the first compile to finish).
        if (CurrentProjectManager.startScene !== "") {
            root.openScene(CurrentProjectManager.resourcesPath() + "/" + CurrentProjectManager.startScene);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    UnsavedChangesDialog {
        id: unsavedDialog
        property var pendingAction: null

        onSaveRequested: {
            root.afterSave = pendingAction;
            viewportPanel.saveScene();
        }
        onDiscardRequested: {
            root.sceneDirty = false;
            if (pendingAction) pendingAction();
        }
    }

    ProjectSettingsDialog {
        id: settingsDialog
        onResolutionChanged: (width, height) => root.setCameraSize(width, height)
    }

    Connections {
        target: ProjectBuilder
        function onIsCompilingChanged() {
            if (ProjectBuilder.isCompiling) {
                root.activeBottomPanel = "output";
                root.compileFailureDismissed = false;
            }
        }
        function onCompileFinished(success) {
            if (root.pendingScenePath !== "") {
                if (success) {
                    root.currentScenePath = root.pendingScenePath;
                } else {
                    root.activeBottomPanel = "output";
                }
                root.pendingScenePath = "";
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        EditorToolbar {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            currentScenePath: root.currentScenePath
            isPlaying: viewportPanel.playing
            sceneDirty: root.sceneDirty

            onSettingsRequested: settingsDialog.open()
            onBackRequested: root.leaveScene(qsTr("closing the project"), () => {
                CurrentProjectManager.closeProject()
                Router.replace("/")
            })
            onPlayRequested: viewportPanel.setPlaying(true)
            onStopRequested: viewportPanel.setPlaying(false)
            onSaveRequested: root.saveCurrentScene()
            onSearchRequested: globalSearch.open()
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            orientation: Qt.Vertical

            SplitView {
                SplitView.fillWidth: true
                SplitView.fillHeight: true

                orientation: Qt.Horizontal

                SceneHierarchyPanel {
                    SplitView.preferredWidth: 260
                    SplitView.minimumWidth: 220
                    enabled: !viewportPanel.playing
                    entities: viewportPanel.loadedEntities
                    selectedEntity: root.selectedEntity
                    onEntitySelected: entity => {
                        root.selectedMaterial = null
                        root.selectedEntity = entity
                    }

                    onEntityCreateRequested: (name, folder, preset) => {
                        root.pendingCreates = root.pendingCreates.concat([{folder: folder === "" ? null : folder, preset: preset}]);
                        viewportPanel.createEntity(name)
                        root.sceneDirty = true;
                    }

                    onEntityRenameRequested: (entity, newName) => {
                        viewportPanel.setComponentProperty(entity.id, entity.generation,
                            "name_component", "name", "string", newName)
                        root.sceneDirty = true;
                    }

                    onEntityDuplicateRequested: (entity, newName, folder) => {
                        root.pendingCreates = root.pendingCreates.concat([{folder: folder, preset: ""}]);
                        viewportPanel.duplicateEntity(entity.id, entity.generation, newName)
                        root.sceneDirty = true;
                    }

                    onEntityFolderChangeRequested: (entity, folder) => root.setEntityFolder(entity, folder)

                    onEntityDeleteRequested: (entity) => {
                        if (root.selectedEntity && root.selectedEntity.id === entity.id
                            && root.selectedEntity.generation === entity.generation) {
                            root.selectedEntity = null;
                        }
                        viewportPanel.destroyEntity(entity.id, entity.generation)
                        root.sceneDirty = true;
                    }
                }

                ViewportPanel {
                    id: viewportPanel
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 400
                    scenePath: root.currentScenePath
                    selectedEntity: root.selectedEntity
                    hasInspectedEntity: root.selectedEntity !== null
                    inspectedEntityId: root.selectedEntity ? root.selectedEntity.id : 0
                    inspectedEntityGeneration: root.selectedEntity ? root.selectedEntity.generation : 0
                    hasInspectedMaterial: root.selectedMaterial !== null
                    inspectedMaterialId: root.selectedMaterial ? root.selectedMaterial.id : 0
                    inspectedMaterialGeneration: root.selectedMaterial ? root.selectedMaterial.generation : 0

                    onCameraEdited: root.sceneDirty = true
                    onImageDropped: (filePath, x, y) => root.createImageSprite(filePath, false, x, y)
                    onSceneCameraChanged: {
                        if (root.pendingCameraSize && root.isStartSceneOpen() && sceneCamera.valid) {
                            root.setCameraSize(root.pendingCameraSize.width, root.pendingCameraSize.height);
                        }
                    }
                    onEntityMoved: root.sceneDirty = true
                    onEntityPicked: (entityId, entityGeneration) => {
                        for (const entity of viewportPanel.loadedEntities || []) {
                            if (entity.id === entityId && entity.generation === entityGeneration) {
                                root.selectedMaterial = null;
                                root.selectedEntity = entity;
                                return;
                            }
                        }
                    }

                    onSceneSaved: (success) => {
                        if (success) {
                            root.sceneDirty = false;
                            root.syncWindowToCamera();
                            if (root.reloadAfterSave) {
                                root.reloadAfterSave = false;
                                viewportPanel.reloadScene();
                            }
                            if (root.afterSave) {
                                const action = root.afterSave;
                                root.afterSave = null;
                                action();
                            }
                            console.log("Scene saved: " + root.currentScenePath);
                        } else {
                            console.warn("Failed to save scene: " + root.currentScenePath);
                            root.afterSave = null; // stay on the scene: its changes aren't saved
                        }
                    }

                    onEntityCreated: (id, gen) => {
                        const pending = root.pendingCreates.length > 0 ? root.pendingCreates[0] : {folder: null, preset: ""};
                        root.pendingCreates = root.pendingCreates.slice(1);
                        if (pending.folder !== null && pending.folder !== undefined) {
                            root.setEntityFolder({id: id, generation: gen}, pending.folder);
                        }
                        root.applyEntityPreset({id: id, generation: gen}, pending.preset, pending.image);
                        const items = viewportPanel.loadedEntities || [];
                        for (let i = 0; i < items.length; i++) {
                            if (items[i].id === id && items[i].generation === gen) {
                                root.selectedMaterial = null;
                                root.selectedEntity = items[i];
                                break;
                            }
                        }
                    }
                }

                InspectorPanel {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 260
                    enabled: !viewportPanel.playing
                    entity: root.selectedEntity
                    componentsData: viewportPanel.inspectedComponents
                    loadedResources: viewportPanel.loadedResources
                    material: root.selectedMaterial
                    materialProperties: viewportPanel.inspectedMaterialProperties
                    resourcesPath: CurrentProjectManager.resourcesPath()
                    currentScenePath: root.currentScenePath

                    onSceneReloadRequested: root.reloadSceneKeepingEdits()

                    onGroupsChanged: (groups) => {
                        if (root.selectedEntity) root.setEntityGroups(root.selectedEntity, groups)
                    }

                    onPropertyEdited: (componentType, propertyName, propertyType, value) => {
                        if (root.selectedMaterial) {
                            viewportPanel.setMaterialProperty(root.selectedMaterial.id, root.selectedMaterial.generation,
                                propertyName, propertyType, value)
                        } else if (root.selectedEntity) {
                            viewportPanel.setComponentProperty(root.selectedEntity.id, root.selectedEntity.generation,
                                componentType, propertyName, propertyType, value)
                        }
                        root.sceneDirty = true;
                    }

                    onComponentAddRequested: (componentType) => {
                        viewportPanel.addComponent(root.selectedEntity.id, root.selectedEntity.generation, componentType)
                        root.sceneDirty = true;
                    }

                    onComponentRemoved: (componentType) => {
                        if (root.selectedEntity) {
                            viewportPanel.removeComponent(root.selectedEntity.id, root.selectedEntity.generation, componentType)
                            root.sceneDirty = true;
                        }
                    }

                    onPropertyRemoved: (componentType, propertyName) => {
                        if (root.selectedMaterial) {
                            viewportPanel.removeMaterialProperty(root.selectedMaterial.id, root.selectedMaterial.generation, propertyName)
                            root.sceneDirty = true;
                        } else if (root.selectedEntity) {
                            viewportPanel.removeComponentProperty(root.selectedEntity.id, root.selectedEntity.generation,
                                componentType, propertyName)
                            root.sceneDirty = true;
                        }
                    }
                }
            }

            Item {
                SplitView.preferredHeight: 220
                SplitView.minimumHeight: 120
                visible: root.activeBottomPanel !== ""

                StackLayout {
                    anchors.fill: parent
                    currentIndex: {
                        if (root.activeBottomPanel === "scenes") return 0;
                        if (root.activeBottomPanel === "resources") return 1;
                        if (root.activeBottomPanel === "output") return 2;
                        if (root.activeBottomPanel === "logs") return 3;
                        if (root.activeBottomPanel === "loadedResources") return 4;
                        return -1;
                    }

                    SceneBrowserPanel {
                        id: scenePanel
                        sceneDirty: root.sceneDirty
                        currentScenePath: root.currentScenePath
                        onSceneOpenRequested: function(filePath) {
                            root.openScene(filePath);
                        }
                        onSceneRenamed: function(oldPath, newPath) {
                            if (root.currentScenePath === oldPath) {
                                root.currentScenePath = newPath;
                            }
                        }
                    }

                    ResourcePanel {
                        id: resourcePanel
                        onImageSpriteRequested: (filePath, background) =>
                            root.createImageSprite(filePath, background, viewportPanel.viewX, viewportPanel.viewY)
                    }

                    CompilerOutputPanel {
                        id: outputPanel
                    }

                    EditorLogsPanel {
                        id: logsPanel
                    }

                    LoadedResourcesPanel {
                        id: loadedResourcesPanel
                        resources: viewportPanel.loadedResources
                        selectedResource: root.selectedMaterial

                        onResourceSelected: (resource) => {
                            if (resource.type !== "material") {
                                return;
                            }
                            root.selectedEntity = null
                            root.selectedMaterial = resource
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: Theme.bgSecondary

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.borderColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 16

                BottomTabButton {
                    text: qsTr("Scenes")
                    isOpen: root.activeBottomPanel === "scenes"
                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === "scenes") ? "" : "scenes"
                }

                BottomTabButton {
                    text: qsTr("Folder Resources")
                    isOpen: root.activeBottomPanel === "resources"
                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === "resources") ? "" : "resources"
                }

                BottomTabButton {
                    text: qsTr("Output")
                    isOpen: root.activeBottomPanel === "output"
                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === "output") ? "" : "output"
                }

                BottomTabButton {
                    text: qsTr("Editor Logs")
                    isOpen: root.activeBottomPanel === "logs"
                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === "logs") ? "" : "logs"
                }

                BottomTabButton {
                    text: qsTr("Loaded Resources")
                    isOpen: root.activeBottomPanel === "loadedResources"
                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === "loadedResources") ? "" : "loadedResources"
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: ProjectBuilder.isCompiling && !ProjectBuilder.hasCompiledOnce
        color: Qt.rgba(0, 0, 0, 0.75)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Building project…")
                color: Theme.white
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("This only happens once per project.")
                color: Theme.darkGrey
                font.pixelSize: 12
            }
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 64
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 44
        radius: 6
        color: "#3a1414"
        border.color: "#8a2b2b"
        visible: ProjectBuilder.lastCompileFailed && !ProjectBuilder.isCompiling && !root.compileFailureDismissed

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            MuiIcon {
                name: "error"
                font.pixelSize: 18
                color: "#ff6b6b"
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Project failed to compile — fix the errors, then recompile. See the Output panel for details.")
                color: Theme.white
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            AppButton {
                text: qsTr("View Output")
                onClicked: root.activeBottomPanel = "output"
            }

            MuiIcon {
                name: "close"
                font.pixelSize: 16
                color: Theme.grey

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.compileFailureDismissed = true
                }
            }
        }
    }
}