import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

CustomPage {
    id: root

    title: CurrentProjectManager.name

    property var selectedEntity: null

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

            onSettingsRequested: settingsDialog.open()
            onBackRequested: {
                CurrentProjectManager.closeProject()
                Router.replace("/")
            }
        }

        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true

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

                selectedEntity: root.selectedEntity
            }

            InspectorPanel {
                SplitView.preferredWidth: 300
                SplitView.minimumWidth: 260

                entity: root.selectedEntity
            }
        }
    }
}