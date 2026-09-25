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

    function openScene(filePath) {
        if (viewportPanel.playing) {
            return;
        }
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

    Component.onCompleted: ProjectBuilder.compile(CurrentProjectManager.path)

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    ProjectSettingsDialog {
        id: settingsDialog
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
            onBackRequested: {
                CurrentProjectManager.closeProject()
                Router.replace("/")
            }
            onPlayRequested: viewportPanel.setPlaying(true)
            onStopRequested: viewportPanel.setPlaying(false)
            onSaveRequested: root.saveCurrentScene()
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

                    onEntityCreateRequested: (name) => {
                        viewportPanel.createEntity(name)
                        root.sceneDirty = true;
                    }

                    onEntityRenameRequested: (entity, newName) => {
                        viewportPanel.setComponentProperty(entity.id, entity.generation,
                            "name_component", "name", "string", newName)
                        root.sceneDirty = true;
                    }

                    onEntityDuplicateRequested: (entity, newName) => {
                        viewportPanel.duplicateEntity(entity.id, entity.generation, newName)
                        root.sceneDirty = true;
                    }

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

                    onSceneSaved: (success) => {
                        if (success) {
                            root.sceneDirty = false;
                            console.log("Scene saved: " + root.currentScenePath);
                        } else {
                            console.warn("Failed to save scene: " + root.currentScenePath);
                        }
                    }

                    onEntityCreated: (id, gen) => {
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

                    onSceneReloadRequested: viewportPanel.reloadScene()

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