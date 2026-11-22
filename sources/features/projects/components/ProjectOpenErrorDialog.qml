import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// Shown when CurrentProjectManager.openProject() refuses a project. When the only problem is a
// missing editor bridge, offers to download it and opens the project once it's installed.
AppDialog {
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
    subtitle: root.projectPath
    icon: "error"
    preferredWidth: 480

    Connections {
        target: ToolsManager

        function onInstallFinished(tool, version, success) {
            if (!root.visible || tool !== "editor_bridge" || version !== root.bridgeVersion) {
                return;
            }
            if (!success) {
                root.failure = qsTr("Couldn't download the editor bridge v%1. Check your internet connection, then try again.").arg(version);
                return;
            }
            if (CurrentProjectManager.openProject(root.projectPath)) {
                root.accept();
                root.projectOpened(root.projectPath);
            } else {
                root.failure = CurrentProjectManager.lastOpenError;
            }
        }
    }

    Banner {
        Layout.fillWidth: true
        kind: "error"
        title: qsTr("This project can't be opened")
        text: CurrentProjectManager.lastOpenError
    }

    Text {
        Layout.fillWidth: true
        visible: root.bridgeVersion !== ""
        text: qsTr("The editor bridge is the small program that shows your scene inside the editor. This project needs version %1: download it, and the project opens right after.").arg(root.bridgeVersion)
        font.pixelSize: 12
        color: Theme.darkGrey
        wrapMode: Text.WordWrap
    }

    Banner {
        Layout.fillWidth: true
        kind: "error"
        visible: root.failure !== ""
        text: root.failure
    }

    RowLayout {
        Layout.fillWidth: true
        visible: ToolsManager.isInstallingEditorBridge
        spacing: 10

        BusyIndicator {
            running: ToolsManager.isInstallingEditorBridge
            implicitWidth: 24
            implicitHeight: 24
        }

        Text {
            text: qsTr("Downloading the editor bridge...")
            color: Theme.white
            font.pixelSize: 12
        }
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Close")
            onClicked: root.reject()
        },
        AppButton {
            visible: root.bridgeVersion !== ""
            primary: true
            icon: "download"
            enabled: !ToolsManager.isInstallingEditorBridge
            text: ToolsManager.isInstallingEditorBridge
                ? qsTr("Downloading...")
                : root.failure !== "" ? qsTr("Try again") : qsTr("Download editor bridge v%1").arg(root.bridgeVersion)
            onClicked: {
                root.failure = "";
                ToolsManager.installEditorBridge(root.bridgeVersion);
            }
        }
    ]
}
