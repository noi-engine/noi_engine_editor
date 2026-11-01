import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

Dialog {
    id: root

    modal: true
    anchors.centerIn: parent
    width: 640
    height: 720
    padding: 0
    standardButtons: Dialog.NoButton

    property var selectedTemplate: null

    background: Rectangle {
        radius: 16
        color: Theme.bgPrimary
        border.color: Theme.borderColor
        border.width: 1
    }

    LocalTemplateManager {
        id: localTemplateManager
    }

    ProjectCreator {
        id: projectCreator

        onProjectCreated: (name, path) => {
            RecentProjectsManager.addProject(name, path);
            if (CurrentProjectManager.openProject(path)) {
                root.close();
                Router.push("/editor");
            }
        }

        onProjectCreationFailed: reason => {
            errorLabel.text = reason;
            errorLabel.visible = true;
        }
    }

    FolderDialog {
        id: folderDialog

        onAccepted: {
            locationField.text = UrlConverter.toLocalPath(selectedFolder);
        }
    }

    TemplateMarketplaceDialog {
        id: marketplaceDialog
        localTemplateManager: localTemplateManager

        onTemplateDownloaded: {
            localTemplateManager.loadLocalTemplates();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 14

            IconBadge {
                icon: "add_circle"
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: qsTr("Create a new project")
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 20
                }

                Text {
                    text: qsTr("Choose a name, location and template for your project.")
                    color: Theme.darkGrey
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            AppButton {
                icon: "close"
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderColor
            opacity: 0.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Project name")
                    font.pixelSize: 13
                    color: Theme.darkGrey
                }

                TextField {
                    id: nameField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    text: "NewProject"
                    color: Theme.white
                    font.pixelSize: 14

                    background: Rectangle {
                        radius: 10
                        color: Theme.bgSecondary
                        border.color: Theme.borderColor
                        border.width: 1
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: qsTr("Location")
                    font.pixelSize: 13
                    color: Theme.darkGrey
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: locationField

                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        text: SettingsManager.defaultProjectsPath
                        color: Theme.white
                        font.pixelSize: 13

                        background: Rectangle {
                            radius: 10
                            color: Theme.bgSecondary
                            border.color: Theme.borderColor
                            border.width: 1
                        }
                    }

                    AppButton {
                        text: qsTr("Browse")
                        icon: "folder_open"
                        onClicked: folderDialog.open()
                    }
                }

                CheckBox {
                    id: defaultFolderCheckBox
                    text: qsTr("Set as default projects folder")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Select Template *")
                        font.pixelSize: 13
                        color: Theme.darkGrey
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    AppButton {
                        text: qsTr("Marketplace")
                        icon: "shopping_cart"
                        onClicked: marketplaceDialog.open()
                    }
                }

                ListView {
                    id: templateListView

                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    model: localTemplateManager.templates
                    clip: true
                    spacing: 8

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedTemplate && root.selectedTemplate.id === modelData.id

                        width: templateListView.width
                        height: 52
                        radius: 8
                        color: isSelected ? Theme.bgSecondary : "transparent"
                        border.color: isSelected ? Theme.primaryColor : "transparent"
                        border.width: isSelected ? 2 : 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: Theme.white
                                    font.bold: true
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: modelData.description
                                    color: Theme.darkGrey
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedTemplate = modelData;
                                errorLabel.visible = false;
                            }
                        }
                    }

                    ItemDelegate {
                        visible: templateListView.count === 0
                        width: templateListView.width
                        height: 50
                        text: qsTr("No template installed. Open Marketplace to download one.")
                        enabled: false
                    }
                }

                Rectangle {
                    id: toolsStatusCard

                    Layout.fillWidth: true
                    Layout.preferredHeight: toolsStatusColumn.implicitHeight + 20
                    visible: root.selectedTemplate !== null
                    radius: 8
                    color: Theme.bgSecondary
                    border.color: Theme.borderColor

                    readonly property string engineVersion: root.selectedTemplate ? root.selectedTemplate.engineVersion : ""
                    readonly property string compilerVersion: root.selectedTemplate ? root.selectedTemplate.resourceCompilerVersion : ""
                    readonly property string bridgeVersion: root.selectedTemplate ? root.selectedTemplate.editorBridgeVersion : ""

                    property bool engineReady: false
                    property bool compilerReady: false
                    property bool bridgeReady: false

                    function updateStatus() {
                        if (!root.selectedTemplate) return;
                        engineReady = ToolsManager.isNoiEngineInstalled(engineVersion);
                        compilerReady = ToolsManager.isResourceCompilerInstalled(compilerVersion);
                        bridgeReady = ToolsManager.isEditorBridgeInstalled(bridgeVersion);
                    }

                    onEngineVersionChanged: updateStatus()
                    onCompilerVersionChanged: updateStatus()
                    onBridgeVersionChanged: updateStatus()

                    Connections {
                        target: ToolsManager

                        function onInstallFinished(tool, version, success) {
                            toolsStatusCard.updateStatus();

                            if (!success) {
                                const toolLabel = tool === "noi_engine" ? qsTr("Noi Engine")
                                    : tool === "editor_bridge" ? qsTr("Editor Bridge")
                                    : qsTr("Resource Compiler");
                                errorLabel.text = qsTr("Failed to download %1 v%2. Check your connection and try again.").arg(toolLabel).arg(version);
                                errorLabel.visible = true;
                            }
                        }
                    }

                    ColumnLayout {
                        id: toolsStatusColumn

                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        ToolStatusRow {
                            icon: "build"
                            label: qsTr("Noi Engine v%1").arg(toolsStatusCard.engineVersion)
                            ready: toolsStatusCard.engineReady
                            installing: ToolsManager.isInstallingNoiEngine
                            onDownloadRequested: {
                                errorLabel.visible = false;
                                ToolsManager.installNoiEngine(toolsStatusCard.engineVersion);
                            }
                        }

                        ToolStatusRow {
                            icon: "terminal"
                            label: qsTr("Resource Compiler v%1").arg(toolsStatusCard.compilerVersion)
                            ready: toolsStatusCard.compilerReady
                            installing: ToolsManager.isInstallingResourceCompiler
                            onDownloadRequested: {
                                errorLabel.visible = false;
                                ToolsManager.installResourceCompiler(toolsStatusCard.compilerVersion);
                            }
                        }

                        ToolStatusRow {
                            icon: "cable"
                            label: qsTr("Editor Bridge v%1").arg(toolsStatusCard.bridgeVersion)
                            ready: toolsStatusCard.bridgeReady
                            installing: ToolsManager.isInstallingEditorBridge
                            onDownloadRequested: {
                                errorLabel.visible = false;
                                ToolsManager.installEditorBridge(toolsStatusCard.bridgeVersion);
                            }
                        }
                    }
                }
            }

            Text {
                id: errorLabel

                visible: false
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Theme.error
                font.pixelSize: 12
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item {
                    Layout.fillWidth: true
                }

                AppButton {
                    text: qsTr("Cancel")
                    onClicked: root.close()
                }

                AppButton {
                    text: qsTr("Create Project")
                    primary: true

                    onClicked: {
                        if (nameField.text.trim() === "") {
                            errorLabel.text = qsTr("Project name cannot be empty");
                            errorLabel.visible = true;
                            return;
                        }

                        if (!root.selectedTemplate) {
                            errorLabel.text = qsTr("Please select a template to continue");
                            errorLabel.visible = true;
                            return;
                        }

                        if (!toolsStatusCard.engineReady || !toolsStatusCard.compilerReady || !toolsStatusCard.bridgeReady) {
                            errorLabel.text = qsTr("Please download the required tools before creating the project");
                            errorLabel.visible = true;
                            return;
                        }

                        if (defaultFolderCheckBox.checked) {
                            SettingsManager.defaultProjectsPath = locationField.text;
                        }

                        errorLabel.visible = false;
                        projectCreator.createProject(
                            nameField.text.trim(),
                            locationField.text,
                            root.selectedTemplate.id,
                            root.selectedTemplate.version,
                            root.selectedTemplate.engineVersion,
                            root.selectedTemplate.resourceCompilerVersion,
                            root.selectedTemplate.editorBridgeVersion
                        );
                    }
                }
            }
        }
    }
}