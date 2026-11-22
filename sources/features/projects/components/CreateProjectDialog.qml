import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

// One window, one button: pick a name and a template, press Create. Whatever is missing (the
// template, the engine, the resources compiler, the editor bridge) is downloaded on the way,
// with a visible progress, and any failure is explained with a way to retry.
AppDialog {
    id: root

    title: qsTr("New project")
    subtitle: qsTr("Pick a name and a template. Everything the project needs is downloaded for you.")
    icon: "add_circle"
    preferredWidth: 600
    closePolicy: busy ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)
    showClose: !busy

    property var selectedTemplate: null
    property var templateItems: []
    property bool busy: false
    property string stepText: ""
    property string errorText: ""
    property bool loadingTemplates: false
    property string templatesError: ""

    onAboutToShow: {
        errorText = "";
        busy = false;
        PrerequisitesManager.refresh();
        localTemplateManager.loadLocalTemplates();
        rebuildTemplates();
        loadOnlineTemplates();
        nameField.text = qsTr("MyGame");
    }

    onOpened: {
        nameField.field.forceActiveFocus();
        nameField.field.selectAll();
    }

    // ---- Templates: the online catalog merged with what's already on disk (so the dialog still
    // works offline once a template has been downloaded).
    function loadOnlineTemplates() {
        loadingTemplates = true;
        templatesError = "";
        onlineTemplateManager.fetchTemplates();
    }

    function rebuildTemplates() {
        const byId = {};
        for (const local of localTemplateManager.templates) {
            byId[local.id] = {
                id: local.id, name: local.name, description: local.description, version: local.version,
                engineVersion: local.engineVersion, compilerVersion: local.resourceCompilerVersion,
                bridgeVersion: local.editorBridgeVersion, repositoryUrl: "", installed: true
            };
        }
        for (const online of onlineTemplateManager.templates) {
            byId[online.id] = {
                id: online.id, name: online.name, description: online.description, version: online.version,
                engineVersion: online.noi_engine_version, compilerVersion: online.resources_compiler_version,
                bridgeVersion: online.editor_bridge_version, repositoryUrl: online.repositoryUrl,
                installed: localTemplateManager.installedVersions(online.id).indexOf(online.version) >= 0
            };
        }
        templateItems = Object.keys(byId).map(key => byId[key]);

        const stillThere = selectedTemplate && templateItems.some(t => t.id === selectedTemplate.id);
        if (stillThere) {
            selectedTemplate = templateItems.find(t => t.id === selectedTemplate.id);
        } else {
            selectedTemplate = templateItems.length > 0 ? templateItems[0] : null;
        }
    }

    TemplateManager {
        id: onlineTemplateManager
        onTemplatesChanged: root.rebuildTemplates()
        onIsPendingChanged: root.loadingTemplates = isPending
        onFetchFailed: error => root.templatesError = error
    }

    LocalTemplateManager {
        id: localTemplateManager
        onTemplatesChanged: root.rebuildTemplates()
        onDownloadFinished: (templateId, success) => {
            if (!root.busy) return;
            if (!success) {
                root.fail(qsTr("Couldn't download the template. Check your internet connection, then try again."));
                return;
            }
            root.rebuildTemplates();
            root.ensureTools();
        }
    }

    ProjectCreator {
        id: projectCreator

        onProjectCreated: (name, path) => {
            RecentProjectsManager.addProject(name, path);
            if (CurrentProjectManager.openProject(path)) {
                root.busy = false;
                root.close();
                Router.push("/editor");
            } else {
                root.fail(CurrentProjectManager.lastOpenError);
            }
        }

        onProjectCreationFailed: reason => root.fail(reason)
    }

    Connections {
        target: ToolsManager

        function onInstallFinished(tool, version, success) {
            if (!root.busy) return;
            if (!success) {
                const label = tool === "noi_engine" ? qsTr("the Noi Engine")
                    : tool === "editor_bridge" ? qsTr("the editor bridge") : qsTr("the resources compiler");
                root.fail(qsTr("Couldn't download %1 v%2. Check your internet connection, then try again.").arg(label).arg(version));
                return;
            }
            root.ensureTools();
        }
    }

    // ---- Create: template -> tools -> project, each step only when needed.
    function fail(message) {
        busy = false;
        stepText = "";
        errorText = message;
    }

    function validate() {
        const name = nameField.text.trim();
        if (name === "") { nameField.error = qsTr("Give your project a name."); return false; }
        if (/[\\/:*?"<>|]/.test(name) || name === "." || name === "..") {
            nameField.error = qsTr("A project name can't contain / \\ : * ? \" < > |");
            return false;
        }
        nameField.error = "";
        if (locationField.text.trim() === "") { locationField.error = qsTr("Choose where to create the project."); return false; }
        locationField.error = "";
        if (!selectedTemplate) { errorText = qsTr("Select a template first."); return false; }
        return true;
    }

    function startCreate() {
        errorText = "";
        if (!validate()) return;
        if (defaultFolderCheckBox.checked) SettingsManager.defaultProjectsPath = locationField.text;
        busy = true;
        ensureTemplate();
    }

    function ensureTemplate() {
        const t = selectedTemplate;
        if (!t.installed) {
            stepText = qsTr("Downloading the template…");
            localTemplateManager.downloadTemplate(t.id, t.version, t.repositoryUrl);
            return;
        }
        ensureTools();
    }

    function ensureTools() {
        const t = selectedTemplate;
        if (!ToolsManager.isNoiEngineInstalled(t.engineVersion)) {
            stepText = qsTr("Downloading the Noi Engine v%1…").arg(t.engineVersion);
            ToolsManager.installNoiEngine(t.engineVersion);
            return;
        }
        if (!ToolsManager.isResourceCompilerInstalled(t.compilerVersion)) {
            stepText = qsTr("Downloading the resources compiler v%1…").arg(t.compilerVersion);
            ToolsManager.installResourceCompiler(t.compilerVersion);
            return;
        }
        if (!ToolsManager.isEditorBridgeInstalled(t.bridgeVersion)) {
            stepText = qsTr("Downloading the editor bridge v%1…").arg(t.bridgeVersion);
            ToolsManager.installEditorBridge(t.bridgeVersion);
            return;
        }
        stepText = qsTr("Creating your project…");
        projectCreator.createProject(nameField.text.trim(), locationField.text.trim(), t.id, t.version,
                                     t.engineVersion, t.compilerVersion, t.bridgeVersion);
    }

    FolderDialog {
        id: folderDialog
        onAccepted: locationField.text = UrlConverter.toLocalPath(selectedFolder)
    }

    PrerequisitesDialog { id: prerequisitesDialog }

    // ---- Content
    Banner {
        Layout.fillWidth: true
        visible: !PrerequisitesManager.canBuild
        kind: "warning"
        title: qsTr("Some tools are missing on this computer")
        text: qsTr("You can create the project, but you won't be able to compile it until you install: %1.")
            .arg(PrerequisitesManager.missingSummary)
        actionText: qsTr("How to install")
        onActionTriggered: prerequisitesDialog.open()
    }

    AppTextField {
        id: nameField
        Layout.fillWidth: true
        enabled: !root.busy
        label: qsTr("Project name")
        hint: locationField.text.trim() !== "" && text.trim() !== ""
              ? qsTr("Will be created in %1/%2").arg(locationField.text.trim()).arg(text.trim()) : ""
        onEdited: error = ""
        onAccepted: root.startCreate()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        AppTextField {
            id: locationField
            Layout.fillWidth: true
            enabled: !root.busy
            label: qsTr("Location")
            text: SettingsManager.defaultProjectsPath
            onEdited: error = ""
        }

        AppButton {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 20
            enabled: !root.busy
            text: qsTr("Browse")
            icon: "folder_open"
            onClicked: folderDialog.open()
        }
    }

    CheckBox {
        id: defaultFolderCheckBox
        enabled: !root.busy
        text: qsTr("Use this folder for all my new projects")
        font.pixelSize: 13
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("Template")
                color: Theme.darkGrey
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            BusyIndicator {
                visible: root.loadingTemplates
                running: visible
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
            }
        }

        Repeater {
            model: root.templateItems

            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool isSelected: root.selectedTemplate && root.selectedTemplate.id === modelData.id

                Layout.fillWidth: true
                implicitHeight: cardRow.implicitHeight + 24
                radius: Theme.radius
                color: isSelected ? Theme.primaryLightC : Theme.bgSecondary
                border.color: isSelected ? Theme.primaryColor : Theme.borderColor
                border.width: isSelected ? 2 : 1
                opacity: root.busy ? 0.6 : 1

                RowLayout {
                    id: cardRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    IconBadge { icon: "sports_esports" }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.name + "  ·  v" + card.modelData.version
                            color: Theme.white
                            font.bold: true
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.description
                            color: Theme.darkGrey
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    Text {
                        text: card.modelData.installed ? qsTr("Ready") : qsTr("Will be downloaded")
                        color: card.modelData.installed ? Theme.success : Theme.grey
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.busy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.selectedTemplate = card.modelData; root.errorText = ""; }
                }
            }
        }

        Banner {
            Layout.fillWidth: true
            visible: root.templateItems.length === 0 && !root.loadingTemplates
            kind: "error"
            title: qsTr("No template available")
            text: root.templatesError !== ""
                  ? qsTr("The template list couldn't be loaded (%1). Check your internet connection.").arg(root.templatesError)
                  : qsTr("The template list is empty.")
            actionText: qsTr("Try again")
            onActionTriggered: root.loadOnlineTemplates()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.busy
        implicitHeight: busyRow.implicitHeight + 24
        radius: Theme.radius
        color: Theme.bgSecondary
        border.color: Theme.borderColor

        RowLayout {
            id: busyRow
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            BusyIndicator {
                running: root.busy
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
            }

            Text {
                Layout.fillWidth: true
                text: root.stepText
                color: Theme.white
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
    }

    Banner {
        Layout.fillWidth: true
        visible: root.errorText !== ""
        kind: "error"
        title: qsTr("The project couldn't be created")
        text: root.errorText
        actionText: qsTr("Try again")
        onActionTriggered: root.startCreate()
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            enabled: !root.busy
            onClicked: root.close()
        },
        AppButton {
            primary: true
            text: root.busy ? qsTr("Creating…") : qsTr("Create project")
            icon: root.busy ? "" : "rocket_launch"
            enabled: !root.busy && root.selectedTemplate !== null
            onClicked: root.startCreate()
        }
    ]
}
