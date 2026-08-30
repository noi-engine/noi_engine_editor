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

                    property int refreshTick: 0

                    readonly property bool engineReady: {
                        let _ = toolsStatusCard.refreshTick;
                        return engineVersion.length > 0 && ToolsManager.isNoiEngineInstalled(engineVersion);
                    }

                    readonly property bool compilerReady: {
                        let _ = toolsStatusCard.refreshTick;
                        return compilerVersion.length > 0 && ToolsManager.isResourceCompilerInstalled(compilerVersion);
                    }

                    Connections {
                        target: ToolsManager

                        function onInstallFinished(tool, version, success) {
                            toolsStatusCard.refreshTick++;

                            if (!success) {
                                const toolLabel = tool === "noi_engine" ? qsTr("Noi Engine") : qsTr("Resource Compiler");
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MuiIcon {
                                    name: "build"
                                    font.pixelSize: 15
                                    color: Theme.darkGrey
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Noi Engine v%1").arg(toolsStatusCard.engineVersion)
                                    color: Theme.white
                                    font.pixelSize: 12
                                }

                                Text {
                                    visible: toolsStatusCard.engineReady
                                    text: qsTr("Ready")
                                    color: Theme.success
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                BusyIndicator {
                                    visible: ToolsManager.isInstallingNoiEngine
                                    running: ToolsManager.isInstallingNoiEngine
                                    implicitWidth: 20
                                    implicitHeight: 20
                                }

                                AppButton {
                                    visible: !toolsStatusCard.engineReady
                                    text: ToolsManager.isInstallingNoiEngine ? qsTr("Downloading...") : qsTr("Download")
                                    icon: "download"
                                    enabled: !ToolsManager.isInstallingNoiEngine
                                    onClicked: {
                                        errorLabel.visible = false;
                                        ToolsManager.installNoiEngine(toolsStatusCard.engineVersion);
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                MuiIcon {
                                    name: "terminal"
                                    font.pixelSize: 15
                                    color: Theme.darkGrey
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Resource Compiler v%1").arg(toolsStatusCard.compilerVersion)
                                    color: Theme.white
                                    font.pixelSize: 12
                                }

                                Text {
                                    visible: toolsStatusCard.compilerReady
                                    text: qsTr("Ready")
                                    color: Theme.success
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                BusyIndicator {
                                    visible: ToolsManager.isInstallingResourceCompiler
                                    running: ToolsManager.isInstallingResourceCompiler
                                    implicitWidth: 20
                                    implicitHeight: 20
                                }

                                AppButton {
                                    visible: !toolsStatusCard.compilerReady
                                    text: ToolsManager.isInstallingResourceCompiler ? qsTr("Downloading...") : qsTr("Download")
                                    icon: "download"
                                    enabled: !ToolsManager.isInstallingResourceCompiler
                                    onClicked: {
                                        errorLabel.visible = false;
                                        ToolsManager.installResourceCompiler(toolsStatusCard.compilerVersion);
                                    }
                                }
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

                        if (!toolsStatusCard.engineReady || !toolsStatusCard.compilerReady) {
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
                            root.selectedTemplate.engineVersion,
                            root.selectedTemplate.resourceCompilerVersion
                        );
                    }
                }
            }
        }
    }
}