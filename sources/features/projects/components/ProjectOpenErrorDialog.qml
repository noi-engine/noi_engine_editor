import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// Shown when CurrentProjectManager.openProject() refuses a project. When the only problem is a
// missing editor bridge, offers to download it and opens the project once it's installed.
Dialog {
    id: root

    property string projectPath: ""
    property string failure: ""

    signal projectOpened(string path)

    function openFor(path) {
        root.projectPath = path;
        root.failure = "";
        root.open();
    }

    readonly property string bridgeVersion: CurrentProjectManager.missingEditorBridgeVersion

    title: qsTr("Can't open this project")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 420

    Connections {
        target: ToolsManager

        function onInstallFinished(tool, version, success) {
            if (!root.visible || tool !== "editor_bridge" || version !== root.bridgeVersion) {
                return;
            }
            if (!success) {
                root.failure = qsTr("Failed to download the editor bridge v%1. Check your connection and try again.").arg(version);
                return;
            }
            if (CurrentProjectManager.openProject(root.projectPath)) {
                root.accept();
                root.projectOpened(root.projectPath);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: CurrentProjectManager.lastOpenError
            font.pixelSize: 12
            color: Theme.white
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.failure !== ""
            text: root.failure
            font.pixelSize: 12
            color: Theme.error
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            BusyIndicator {
                visible: ToolsManager.isInstallingEditorBridge
                running: ToolsManager.isInstallingEditorBridge
                implicitWidth: 20
                implicitHeight: 20
            }

            AppButton {
                text: qsTr("Close")
                onClicked: root.reject()
            }

            AppButton {
                visible: root.bridgeVersion !== ""
                primary: true
                icon: "download"
                enabled: !ToolsManager.isInstallingEditorBridge
                text: ToolsManager.isInstallingEditorBridge
                    ? qsTr("Downloading...")
                    : qsTr("Download editor bridge v%1").arg(root.bridgeVersion)
                onClicked: {
                    root.failure = "";
                    ToolsManager.installEditorBridge(root.bridgeVersion);
                }
            }
        }
    }
}
