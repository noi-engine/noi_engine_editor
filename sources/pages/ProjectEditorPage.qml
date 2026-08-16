import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

CustomPage {
    id: root

    title: CurrentProjectManager.name

    property var selectedEntity: null
    property bool isResourcePanelOpen: false

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

                    selectedEntity: root.selectedEntity
                }

                InspectorPanel {
                    SplitView.preferredWidth: 300
                    SplitView.minimumWidth: 260

                    entity: root.selectedEntity
                }
            }

            ResourcePanel {
                id: resourcePanel
                SplitView.preferredHeight: 220
                SplitView.minimumHeight: 120
                visible: root.isResourcePanelOpen
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

                MouseArea {
                    Layout.fillHeight: true
                    implicitWidth: toggleRow.implicitWidth
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.isResourcePanelOpen = !root.isResourcePanelOpen

                    RowLayout {
                        id: toggleRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        IconBadge {
                            icon: root.isResourcePanelOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
                        }

                        Text {
                            text: qsTr("Folder Resources")
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.white
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}