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

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    ProjectSettingsDialog {
        id: settingsDialog
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
                    SplitView.minimumWidth: 200
                    selectedName: root.selectedEntity ? root.selectedEntity.name : ""
                    onEntitySelected: entity => root.selectedEntity = entity
                }

                ViewportPanel {
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 400
                    scenePath: root.currentScenePath
                    selectedEntity: root.selectedEntity
                }

                InspectorPanel {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 260
                    entity: root.selectedEntity
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
                        return -1;
                    }

                    SceneBrowserPanel {
                        id: scenePanel
                        onSceneOpenRequested: function(filePath) {
                            root.currentScenePath = filePath;
                        }
                    }

                    ResourcePanel {
                        id: resourcePanel
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

                Item { Layout.fillWidth: true }
            }
        }
    }
}