import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

ColumnLayout {
    id: root

    spacing: Theme.spacingLarge

    // The last download that failed, so it can be explained and retried.
    property string failedTool: ""
    property string failedVersion: ""

    function retryFailed() {
        const tool = root.failedTool, version = root.failedVersion;
        root.failedTool = "";
        root.failedVersion = "";
        if (tool === "noi_engine") ToolsManager.installNoiEngine(version);
        else if (tool === "resource_compiler") ToolsManager.installResourceCompiler(version);
        else if (tool === "editor_bridge") ToolsManager.installEditorBridge(version);
    }

    Connections {
        target: ToolsManager

        function onInstallFinished(tool, version, success) {
            noiEngineSection.model = ToolsManager.installedNoiEngineVersions()
            resourceCompilerSection.model = ToolsManager.installedResourceCompilerVersions()
            editorBridgeSection.model = ToolsManager.installedEditorBridgeVersions()
            if (success) {
                if (root.failedTool === tool) root.failedTool = "";
            } else {
                root.failedTool = tool;
                root.failedVersion = version;
            }
        }
    }

    PrerequisitesDialog { id: prerequisitesDialog }

    Banner {
        Layout.fillWidth: true
        visible: root.failedTool !== ""
        kind: "error"
        title: qsTr("A download failed")
        text: qsTr("Couldn't download %1 v%2. Check your internet connection, then try again.")
            .arg(root.failedTool === "noi_engine" ? qsTr("the Noi Engine")
                 : root.failedTool === "editor_bridge" ? qsTr("the editor bridge") : qsTr("the resources compiler"))
            .arg(root.failedVersion)
        actionText: qsTr("Retry")
        closable: true
        onActionTriggered: root.retryFailed()
        onClosed: root.failedTool = ""
    }

    Banner {
        Layout.fillWidth: true
        kind: "info"
        text: qsTr("These are downloaded automatically when you create or open a project. Removing a version only frees disk space: it is downloaded again when a project needs it.")
    }

    component ToolSection: ColumnLayout {
        id: section

        property string icon: ""
        property string label: ""
        property string description: ""
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
                    Layout.fillWidth: true
                    visible: section.description !== ""
                    text: section.description
                    color: Theme.darkGrey
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
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
        description: qsTr("The engine that runs your game.")
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
        label: qsTr("Resources compiler")
        description: qsTr("Packs your images and scenes when you build a release.")
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
        label: qsTr("Editor bridge")
        description: qsTr("Shows your scene live inside the editor.")
        model: ToolsManager.installedEditorBridgeVersions()

        onRemoveRequested: version => {
            ToolsManager.removeEditorBridgeVersion(version)
            model = ToolsManager.installedEditorBridgeVersions()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Theme.borderColor
        opacity: 0.5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: qsTr("Programs installed on your computer")
                color: Theme.white
                font.bold: true
                font.pixelSize: 15
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("CMake, Ninja, a C++ compiler, Python and flatc build your game. See which ones are missing.")
                color: Theme.darkGrey
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }

        AppButton {
            text: qsTr("Check")
            icon: "build_circle"
            onClicked: prerequisitesDialog.open()
        }
    }
}
