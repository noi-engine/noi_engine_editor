import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

CustomPage {
    id: root

    title: CurrentProjectManager.name

    property var selectedEntity: null
    property var selectedMaterial: null
    property string activeBottomPanel: "resources"
    property string lastBottomPanel: "resources"
    onActiveBottomPanelChanged: if (activeBottomPanel !== "") lastBottomPanel = activeBottomPanel
    property string currentScenePath: ""
    property string pendingScenePath: ""
    property bool compileFailureDismissed: false
    // The first build after opening the project is silent; later ones announce their result.
    property bool compileWasManual: false
    property bool sceneDirty: false
    // What to do with each queued entity create/duplicate, in order ({folder, preset}; folder
    // null = leave as is), applied when the bridge reports the new entity.
    property var pendingCreates: []

    // ---- Images from the resources folder as sprites / backgrounds.
    // Waiting for the image's texture to be loaded (after the scene reload that declares it).
    property var pendingImageSprite: null

    // ---- Undo / redo.
    // Before an edit, the scene is written to a hidden file next to the scene file ("snapshot");
    // undo puts such a file back. Edits that follow each other closely (dragging, typing in a
    // field) are one step. The files are deleted when the scene is left or the editor closed.
    property var undoStack: []
    property var redoStack: []
    property bool editBatchOpen: false
    property bool restoring: false
    property int snapshotCounter: 0
    readonly property bool canUndo: undoStack.length > 0 && !viewportPanel.playing && !restoring
    readonly property bool canRedo: redoStack.length > 0 && !viewportPanel.playing && !restoring
    readonly property int maxUndoSteps: 50

    function snapshotPath() {
        const scene = root.currentScenePath;
        const slash = scene.lastIndexOf("/");
        root.snapshotCounter += 1;
        return scene.substring(0, slash + 1) + "." + scene.substring(slash + 1) + ".undo" + root.snapshotCounter;
    }

    function removeSnapshots(paths) {
        for (const path of paths) CurrentProjectResourcesManager.deleteItem(path);
    }

    function clearUndoHistory() {
        root.removeSnapshots(root.undoStack);
        root.removeSnapshots(root.redoStack);
        root.undoStack = [];
        root.redoStack = [];
        root.editBatchOpen = false;
    }

    // Every scene edit goes through here: marks the scene as changed and opens an undo step.
    function touch() {
        root.sceneDirty = true;
        if (viewportPanel.playing || root.restoring || root.currentScenePath === "") return;
        if (!root.editBatchOpen) {
            root.editBatchOpen = true;
            const path = root.snapshotPath();
            root.undoStack = root.undoStack.concat([path]);
            root.removeSnapshots(root.redoStack);
            root.redoStack = [];
            viewportPanel.snapshotScene(path);
            if (root.undoStack.length > root.maxUndoSteps) {
                root.removeSnapshots([root.undoStack[0]]);
                root.undoStack = root.undoStack.slice(1);
            }
        }
        editBatchTimer.restart();
    }

    function undo() {
        if (!root.canUndo) return;
        const target = root.undoStack[root.undoStack.length - 1];
        root.undoStack = root.undoStack.slice(0, -1);
        const current = root.snapshotPath();
        root.redoStack = root.redoStack.concat([current]);
        root.restoring = true;
        viewportPanel.snapshotScene(current); // the state we leave, for redo
        viewportPanel.restoreScene(target);
        root.pendingRestoreFile = target;
    }

    function redo() {
        if (!root.canRedo) return;
        const target = root.redoStack[root.redoStack.length - 1];
        root.redoStack = root.redoStack.slice(0, -1);
        const current = root.snapshotPath();
        root.undoStack = root.undoStack.concat([current]);
        root.restoring = true;
        viewportPanel.snapshotScene(current);
        viewportPanel.restoreScene(target);
        root.pendingRestoreFile = target;
    }

    property string pendingRestoreFile: ""

    Timer {
        id: editBatchTimer
        interval: 700
        onTriggered: root.editBatchOpen = false
    }

    Component.onDestruction: root.clearUndoHistory()

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
        root.touch();
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
        if (preset === "trigger_zone") {
            // Invisible area that only reports who enters it (coins, doors, damage zones...).
            viewportPanel.addComponent(id, gen, "transform");
            viewportPanel.addComponent(id, gen, "box_collider");
            viewportPanel.setComponentProperty(id, gen, "box_collider", "is_static", "bool", true);
            viewportPanel.setComponentProperty(id, gen, "box_collider", "is_trigger", "bool", true);
            return;
        }
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
        root.touch();
    }

    function setEntityGroups(entity, groups) {
        if (groups.length === 0) {
            viewportPanel.removeComponent(entity.id, entity.generation, "groups")
        } else {
            viewportPanel.addComponent(entity.id, entity.generation, "groups")
            viewportPanel.setComponentProperty(entity.id, entity.generation, "groups", "names", "string", groups.join(","))
        }
        root.touch();
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
        root.touch();
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
        root.clearUndoHistory();
        root.selectedEntity = null;
        root.selectedMaterial = null;
        if (ProjectBuilder.isCompiling || ProjectBuilder.lastCompileFailed) {
            root.pendingScenePath = filePath;
        } else {
            root.currentScenePath = filePath;
            root.sceneDirty = false;
        }
    }

    // Play saves the scene first (like "save before running" in other editors), so what runs is
    // exactly what is on disk and nothing is lost if the game misbehaves.
    function startPlay() {
        if (root.currentScenePath === "" || viewportPanel.playing) return;
        if (root.sceneDirty) {
            root.afterSave = () => viewportPanel.setPlaying(true);
            viewportPanel.saveScene();
        } else {
            viewportPanel.setPlaying(true);
        }
    }

    function togglePlay() {
        if (viewportPanel.playing) viewportPanel.setPlaying(false);
        else root.startPlay();
    }

    function deleteSelectedEntity() {
        const entity = root.selectedEntity;
        if (!entity || entity.name === "main_camera" || viewportPanel.playing) return;
        root.selectedEntity = null;
        viewportPanel.destroyEntity(entity.id, entity.generation);
        root.touch();
    }

    function duplicateSelectedEntity() {
        const entity = root.selectedEntity;
        if (!entity || viewportPanel.playing) return;
        root.pendingCreates = root.pendingCreates.concat([{folder: null, preset: ""}]);
        viewportPanel.duplicateEntity(entity.id, entity.generation, (entity.name || "Entity") + " copy");
        root.touch();
    }

    function saveCurrentScene() {
        if (root.currentScenePath === "" || viewportPanel.playing) {
            return;
        }
        viewportPanel.saveScene();
    }

    // Ctrl+Z / Ctrl+Shift+Z, except while typing in a text field (which has its own undo).
    readonly property bool typingInField: !!Window.activeFocusItem && Window.activeFocusItem.hasOwnProperty("cursorPosition")

    Shortcut {
        sequence: StandardKey.Undo
        enabled: root.canUndo && !root.typingInField
        onActivated: root.undo()
    }

    Shortcut {
        sequences: [StandardKey.Redo, "Ctrl+Y"]
        enabled: root.canRedo && !root.typingInField
        onActivated: root.redo()
    }

    Shortcut {
        sequence: "F5"
        enabled: root.currentScenePath !== "" && !ProjectBuilder.isCompiling
        onActivated: root.togglePlay()
    }

    Shortcut {
        sequence: StandardKey.Delete
        enabled: root.selectedEntity !== null && !root.typingInField && !viewportPanel.playing
        onActivated: root.deleteSelectedEntity()
    }

    Shortcut {
        sequence: "Ctrl+D"
        enabled: root.selectedEntity !== null && !root.typingInField && !viewportPanel.playing
        onActivated: root.duplicateSelectedEntity()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.selectedEntity !== null && !root.typingInField
        onActivated: root.selectedEntity = null
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
        // Development aid (screenshots): `--panel scenes|resources|output|logs`.
        const panelIndex = Qt.application.arguments.indexOf("--panel");
        if (panelIndex >= 0) root.activeBottomPanel = Qt.application.arguments[panelIndex + 1];
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

    PrerequisitesDialog { id: prerequisitesDialog }

    ProjectSettingsDialog {
        id: settingsDialog
        onResolutionChanged: (width, height) => root.setCameraSize(width, height)
    }

    ReleaseDoneDialog { id: releaseDoneDialog }

    Connections {
        target: ProjectBuilder
        function onReleaseFinished(success, outputPath) {
            if (success) {
                releaseDoneDialog.show(outputPath);
            } else {
                root.activeBottomPanel = "output";
                Notifier.error(PrerequisitesManager.canRelease
                    ? qsTr("The release build failed. Open “Console” to see why.")
                    : qsTr("The release build couldn't run: some tools are missing."));
            }
        }
    }

    Connections {
        target: ProjectBuilder
        function onIsCompilingChanged() {
            if (ProjectBuilder.isCompiling) {
                root.compileFailureDismissed = false;
            }
        }
        function onCompileFinished(success) {
            if (success) {
                if (root.compileWasManual) Notifier.success(qsTr("Build finished: your scripts are up to date"));
            } else {
                root.activeBottomPanel = "output"; // show why it failed
                Notifier.error(PrerequisitesManager.canBuild
                    ? qsTr("The build failed. Open “Console” to see why.")
                    : qsTr("The build couldn't run: some tools are missing."));
            }
            root.compileWasManual = true;
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
            onPlayRequested: root.startPlay()
            onStopRequested: viewportPanel.setPlaying(false)
            onSaveRequested: root.saveCurrentScene()
            onSearchRequested: globalSearch.open()
            onScenesRequested: root.activeBottomPanel = "resources"
            onBuildHelpRequested: prerequisitesDialog.open()
            canUndo: root.canUndo
            canRedo: root.canRedo
            onUndoRequested: root.undo()
            onRedoRequested: root.redo()
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            Layout.topMargin: 8
            Layout.bottomMargin: 4

            orientation: Qt.Vertical

            handle: Item {
                implicitWidth: 8
                implicitHeight: 8

                Rectangle {
                    anchors.centerIn: parent
                    width: SplitHandle.pressed || SplitHandle.hovered ? 36 : 0
                    height: 3
                    radius: 2
                    color: SplitHandle.pressed ? Theme.primaryColor : Theme.borderStrong
                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }

            SplitView {
                SplitView.fillWidth: true
                SplitView.fillHeight: true

                orientation: Qt.Horizontal

                handle: Item {
                    implicitWidth: 8
                    implicitHeight: 8

                    Rectangle {
                        anchors.centerIn: parent
                        width: 3
                        height: SplitHandle.pressed || SplitHandle.hovered ? 36 : 0
                        radius: 2
                        color: SplitHandle.pressed ? Theme.primaryColor : Theme.borderStrong
                        Behavior on height { NumberAnimation { duration: 120 } }
                    }
                }

                PanelCard {
                    SplitView.preferredWidth: 260
                    SplitView.minimumWidth: 220
                    SceneHierarchyPanel {
                        anchors.fill: parent
                        enabled: !viewportPanel.playing
                        entities: viewportPanel.loadedEntities
                        onImageDropped: filePath => root.createImageSprite(filePath, false, viewportPanel.viewX, viewportPanel.viewY)
                        sceneName: root.sceneName(root.currentScenePath)
                        sceneDirty: root.sceneDirty
                        selectedEntity: root.selectedEntity
                        onEntitySelected: entity => {
                            root.selectedMaterial = null
                            root.selectedEntity = entity
                        }

                        onEntityCreateRequested: (name, folder, preset) => {
                            root.pendingCreates = root.pendingCreates.concat([{folder: folder === "" ? null : folder, preset: preset}]);
                            viewportPanel.createEntity(name)
                            root.touch();
                        }

                        onEntityRenameRequested: (entity, newName) => {
                            viewportPanel.setComponentProperty(entity.id, entity.generation,
                                "name_component", "name", "string", newName)
                            root.touch();
                        }

                        onEntityDuplicateRequested: (entity, newName, folder) => {
                            root.pendingCreates = root.pendingCreates.concat([{folder: folder, preset: ""}]);
                            viewportPanel.duplicateEntity(entity.id, entity.generation, newName)
                            root.touch();
                        }

                        onEntityFolderChangeRequested: (entity, folder) => root.setEntityFolder(entity, folder)

                        onEntityDeleteRequested: (entity) => {
                            if (root.selectedEntity && root.selectedEntity.id === entity.id
                                && root.selectedEntity.generation === entity.generation) {
                                root.selectedEntity = null;
                            }
                            viewportPanel.destroyEntity(entity.id, entity.generation)
                            root.touch();
                        }
                    }
                }

                PanelCard {
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 400
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        SceneTabs {
                            Layout.fillWidth: true
                            currentScenePath: root.currentScenePath
                            sceneDirty: root.sceneDirty
                            onSceneChosen: filePath => root.openScene(filePath)
                            onNewSceneRequested: scenePanel.openNewSceneDialog()
                        }

                        ViewportPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            id: viewportPanel
                            scenePath: root.currentScenePath
                            selectedEntity: root.selectedEntity
                            hasInspectedEntity: root.selectedEntity !== null
                            inspectedEntityId: root.selectedEntity ? root.selectedEntity.id : 0
                            inspectedEntityGeneration: root.selectedEntity ? root.selectedEntity.generation : 0
                            hasInspectedMaterial: root.selectedMaterial !== null
                            inspectedMaterialId: root.selectedMaterial ? root.selectedMaterial.id : 0
                            inspectedMaterialGeneration: root.selectedMaterial ? root.selectedMaterial.generation : 0

                            onScenesRequested: root.activeBottomPanel = "resources"
                            onSnapshotTaken: (path, success) => {
                                if (success) return;
                                // No file to go back to: forget that step.
                                root.undoStack = root.undoStack.filter(p => p !== path);
                                root.redoStack = root.redoStack.filter(p => p !== path);
                            }
                            onSceneRestored: (path, success) => {
                                root.restoring = false;
                                if (root.pendingRestoreFile !== "") {
                                    root.removeSnapshots([root.pendingRestoreFile]);
                                    root.pendingRestoreFile = "";
                                }
                                if (success) root.sceneDirty = true;
                            }
                            onCameraEdited: root.touch()
                            onImageDropped: (filePath, x, y) => root.createImageSprite(filePath, false, x, y)
                            onSceneCameraChanged: {
                                if (root.pendingCameraSize && root.isStartSceneOpen() && sceneCamera.valid) {
                                    root.setCameraSize(root.pendingCameraSize.width, root.pendingCameraSize.height);
                                }
                            }
                            onEntityMoved: root.touch()
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
                                    Notifier.success(qsTr("Scene saved"));
                                } else {
                                    console.warn("Failed to save scene: " + root.currentScenePath);
                                    Notifier.error(qsTr("Couldn't save the scene. Check that the file isn't read-only, then press Save again."));
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
                    }
                }

                PanelCard {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 260
                    InspectorPanel {
                        anchors.fill: parent
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
                            root.touch();
                        }

                        onComponentAddRequested: (componentType) => {
                            viewportPanel.addComponent(root.selectedEntity.id, root.selectedEntity.generation, componentType)
                            root.touch();
                        }

                        onComponentRemoved: (componentType) => {
                            if (root.selectedEntity) {
                                viewportPanel.removeComponent(root.selectedEntity.id, root.selectedEntity.generation, componentType)
                                root.touch();
                            }
                        }

                        onPropertyRemoved: (componentType, propertyName) => {
                            if (root.selectedMaterial) {
                                viewportPanel.removeMaterialProperty(root.selectedMaterial.id, root.selectedMaterial.generation, propertyName)
                                root.touch();
                            } else if (root.selectedEntity) {
                                viewportPanel.removeComponentProperty(root.selectedEntity.id, root.selectedEntity.generation,
                                    componentType, propertyName)
                                root.touch();
                            }
                        }
                    }
                }
            }

            // Bottom dock (Unity's Project / Console): always there, tabs on top, collapsible.
            PanelCard {
                id: dock
                readonly property bool collapsed: root.activeBottomPanel === ""
                SplitView.preferredHeight: collapsed ? 40 : 270
                SplitView.minimumHeight: collapsed ? 40 : 140
                SplitView.maximumHeight: collapsed ? 40 : 100000

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: Theme.bgSecondary

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 2

                            Repeater {
                                model: [
                                    { id: "resources", label: qsTr("Project"), icon: "folder" },
                                    { id: "output", label: qsTr("Console"), icon: "terminal" },
                                    { id: "logs", label: qsTr("Logs"), icon: "receipt_long" },
                                    { id: "loadedResources", label: qsTr("In memory"), icon: "memory" }
                                ]

                                delegate: DockTab {
                                    required property var modelData
                                    text: modelData.label
                                    icon: modelData.icon
                                    isOpen: root.activeBottomPanel === modelData.id
                                    attention: modelData.id === "output" && ProjectBuilder.lastCompileFailed
                                    onClicked: root.activeBottomPanel = (root.activeBottomPanel === modelData.id) ? "" : modelData.id
                                }
                            }

                            Item { Layout.fillWidth: true }

                            AppButton {
                                compact: true
                                implicitHeight: 28
                                icon: dock.collapsed ? "keyboard_arrow_up" : "keyboard_arrow_down"
                                text: dock.collapsed ? qsTr("Show panel") : qsTr("Hide panel")
                                onClicked: root.activeBottomPanel = dock.collapsed ? root.lastBottomPanel : ""
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.borderColor
                            visible: !dock.collapsed
                        }
                    }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !dock.collapsed
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
                        // No tab of its own any more (the Project panel lists the scenes); it
                        // still owns the New scene dialog behind the "+" of the scene tabs.
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
                        onSceneOpenRequested: filePath => root.openScene(filePath)
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

                Item { Layout.fillWidth: true }

                // What the editor is doing / what needs attention, always visible.
                Text {
                    id: statusText
                    readonly property string message: {
                        if (viewportPanel.playing) return qsTr("Playing — press Stop to edit again")
                        if (ProjectBuilder.isCompiling) return qsTr("Building…")
                        if (ProjectBuilder.lastCompileFailed) return qsTr("Build failed — open “Console”")
                        if (!PrerequisitesManager.canBuild) return qsTr("Tools missing — you can't build yet")
                        if (root.currentScenePath === "") return qsTr("No scene open — double-click a scene in Project")
                        if (root.sceneDirty) return qsTr("Unsaved changes — Ctrl+S to save")
                        return qsTr("All changes saved")
                    }
                    text: message
                    font.pixelSize: 11
                    color: ProjectBuilder.lastCompileFailed || !PrerequisitesManager.canBuild ? Theme.error
                         : (root.sceneDirty || ProjectBuilder.isCompiling) ? Theme.warning : Theme.darkGrey
                }
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

    // The build failed (or can't even start): say why in plain words and where to look.
    Banner {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 64
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        z: 5
        visible: ProjectBuilder.lastCompileFailed && !ProjectBuilder.isCompiling && !root.compileFailureDismissed
        kind: "error"
        closable: true
        title: PrerequisitesManager.canBuild ? qsTr("Your project didn't build")
                                              : qsTr("Your project can't build: some tools are missing")
        text: PrerequisitesManager.canBuild
              ? qsTr("Read the red lines in “Console” to find what to fix, then press Build ▸ Compile scripts.")
              : qsTr("Missing: %1. Install them, then press Build ▸ Compile scripts.").arg(PrerequisitesManager.missingSummary)
        actionText: PrerequisitesManager.canBuild ? qsTr("Show build output") : qsTr("How to install")
        onActionTriggered: PrerequisitesManager.canBuild ? root.activeBottomPanel = "output" : prerequisitesDialog.open()
        onClosed: root.compileFailureDismissed = true
    }
}