import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

CustomPage {
    id: root

    title: CurrentProjectManager.name

    property var selectedEntity: null
    property string activeBottomPanel: ""
    property string currentScenePath: ""
    property string pendingScenePath: ""
    property bool compileFailureDismissed: false

    function openScene(filePath) {
        if (ProjectBuilder.isCompiling || ProjectBuilder.lastCompileFailed) {
            root.pendingScenePath = filePath;
        } else {
            root.currentScenePath = filePath;
        }
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

            onSettingsRequested: settingsDialog.open()
            onBackRequested: {
                CurrentProjectManager.closeProject()
                Router.replace("/")
            }
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
                    entities: viewportPanel.loadedEntities
                    selectedEntity: root.selectedEntity
                    onEntitySelected: entity => root.selectedEntity = entity
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
                }

                InspectorPanel {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 260
                    entity: root.selectedEntity
                    componentsData: viewportPanel.inspectedComponents

                    onPropertyEdited: (componentType, propertyName, propertyType, value) => {
                        viewportPanel.setComponentProperty(root.selectedEntity.id, root.selectedEntity.generation,
                            componentType, propertyName, propertyType, value)
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
                        onSceneOpenRequested: function(filePath) {
                            root.openScene(filePath);
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