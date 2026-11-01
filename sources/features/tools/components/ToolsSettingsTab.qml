import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

ColumnLayout {
    id: root

    spacing: 20

    Connections {
        target: ToolsManager

        function onInstallFinished() {
            noiEngineSection.model = ToolsManager.installedNoiEngineVersions()
            resourceCompilerSection.model = ToolsManager.installedResourceCompilerVersions()
            editorBridgeSection.model = ToolsManager.installedEditorBridgeVersions()
        }
    }

    component ToolSection: ColumnLayout {
        id: section

        property string icon: ""
        property string label: ""
        property alias model: listView.model

        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            IconBadge {
                icon: section.icon
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: section.label
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    text: listView.count === 1
                        ? qsTr("1 version installed")
                        : qsTr("%1 versions installed").arg(listView.count)
                    color: Theme.darkGrey
                    font.pixelSize: 11
                }
            }
        }

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(1, count) * 46 + Math.max(0, count - 1) * 8
            Layout.maximumHeight: 140
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                required property var modelData

                width: ListView.view ? ListView.view.width : 0
                height: 38
                radius: 10
                color: Theme.bgTertiary
                border.color: Theme.borderColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    MuiIcon {
                        name: "check_circle"
                        font.pixelSize: 14
                        color: Theme.success
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("v%1").arg(modelData)
                        color: Theme.white
                        font.pixelSize: 12
                    }

                    AppButton {
                        text: qsTr("Remove")
                        icon: "delete"
                        onClicked: section.removeRequested(modelData)
                    }
                }
            }

            ItemDelegate {
                anchors.centerIn: parent
                visible: listView.count === 0
                width: listView.width
                height: 38
                text: qsTr("No version installed yet")
                enabled: false
            }
        }

        signal removeRequested(string version)
    }

    ToolSection {
        id: noiEngineSection

        icon: "build"
        label: qsTr("Noi Engine")
        model: ToolsManager.installedNoiEngineVersions()

        onRemoveRequested: version => {
            ToolsManager.removeNoiEngineVersion(version)
            model = ToolsManager.installedNoiEngineVersions()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.borderColor
        opacity: 0.5
    }

    ToolSection {
        id: resourceCompilerSection

        icon: "terminal"
        label: qsTr("Resource Compiler")
        model: ToolsManager.installedResourceCompilerVersions()

        onRemoveRequested: version => {
            ToolsManager.removeResourceCompilerVersion(version)
            model = ToolsManager.installedResourceCompilerVersions()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.borderColor
        opacity: 0.5
    }

    ToolSection {
        id: editorBridgeSection

        icon: "cable"
        label: qsTr("Editor Bridge")
        model: ToolsManager.installedEditorBridgeVersions()

        onRemoveRequested: version => {
            ToolsManager.removeEditorBridgeVersion(version)
            model = ToolsManager.installedEditorBridgeVersions()
        }
    }

    Item { Layout.fillHeight: true }
}
