import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

// Application settings, as a page of its own (not a dialog): categories on the left, the chosen
// one on the right.
CustomPage {
    id: root

    title: qsTr("Settings")

    property string category: "general"

    readonly property var categories: [
        { id: "general", label: qsTr("General"), icon: "tune" },
        { id: "build", label: qsTr("Build tools"), icon: "build_circle" },
        { id: "engine", label: qsTr("Engine and tools"), icon: "download" },
        { id: "about", label: qsTr("About"), icon: "info" }
    ]

    // Development aid (screenshots): `--category general|build|engine|about`.
    Component.onCompleted: {
        const index = Qt.application.arguments.indexOf("--category");
        if (index >= 0) root.category = Qt.application.arguments[index + 1];
        PrerequisitesManager.refresh();
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Router.pop()
    }

    FolderDialog {
        id: folderDialog
        onAccepted: SettingsManager.defaultProjectsPath = UrlConverter.toLocalPath(selectedFolder)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Categories
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.width < 900 ? 72 : 252
            color: Theme.bgSecondary

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.borderColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.width < 900 ? 10 : 18
                spacing: 6

                AppButton {
                    Layout.fillWidth: true
                    icon: "arrow_back"
                    compact: root.width < 900
                    text: qsTr("Back")
                    onClicked: Router.pop()
                }

                Item { Layout.preferredHeight: 12 }

                Repeater {
                    model: root.categories

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: root.category === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: Theme.radius
                        color: active ? Theme.primaryLightB : (area.containsMouse ? Theme.bgTertiary : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.width < 900 ? 0 : 14
                            spacing: 12

                            Item { visible: root.width < 900; Layout.fillWidth: true }

                            MuiIcon {
                                name: modelData.icon
                                font.pixelSize: 20
                                color: active ? Theme.primaryColor : Theme.darkGrey
                            }

                            Text {
                                visible: root.width >= 900
                                Layout.fillWidth: true
                                text: modelData.label
                                font.pixelSize: 13
                                font.weight: active ? Font.DemiBold : Font.Medium
                                color: active ? Theme.white : Theme.darkGrey
                            }

                            Item { visible: root.width < 900; Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.category = modelData.id
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Content
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: content.implicitHeight + 80
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: content
                x: Math.max(28, (flickable.width - width) / 2)
                y: 36
                width: Math.min(flickable.width - 56, 820)
                spacing: 18

                Text {
                    text: {
                        const found = root.categories.find(c => c.id === root.category);
                        return found ? found.label : "";
                    }
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    color: Theme.white
                }

                // ---- General
                ColumnLayout {
                    visible: root.category === "general"
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Where new projects are created, unless you pick another folder in the New project window.")
                        font.pixelSize: 13
                        color: Theme.darkGrey
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        AppTextField {
                            Layout.fillWidth: true
                            label: qsTr("Default projects folder")
                            text: SettingsManager.defaultProjectsPath
                            onEdited: SettingsManager.defaultProjectsPath = text
                        }

                        AppButton {
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 20
                            icon: "folder_open"
                            text: qsTr("Browse")
                            onClicked: folderDialog.open()
                        }
                    }
                }

                ColumnLayout {
                    visible: root.category === "general"
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("The editor you write your scripts in. “Open code” in the toolbar and the script buttons use it.")
                        font.pixelSize: 13
                        color: Theme.darkGrey
                        wrapMode: Text.WordWrap
                    }

                    AppTextField {
                        Layout.fillWidth: true
                        label: qsTr("Code editor command")
                        placeholderText: qsTr("empty = automatic")
                        text: SettingsManager.codeEditorCommand
                        hint: SettingsManager.codeEditorCommand === ""
                              ? (CodeEditorLauncher.detectedEditor() !== ""
                                 ? qsTr("Found on this computer: %1").arg(CodeEditorLauncher.detectedEditor())
                                 : qsTr("No known editor found: your system's default app opens the files. You can type a command, for example: code"))
                              : qsTr("Started with the project folder (and the script file) as arguments.")
                        onEdited: SettingsManager.codeEditorCommand = text
                    }
                }

                // ---- Build tools
                ColumnLayout {
                    visible: root.category === "build"
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("The editor runs these programs to compile your scripts and pack your game. Install the missing ones, then check again.")
                        font.pixelSize: 13
                        color: Theme.darkGrey
                        wrapMode: Text.WordWrap
                    }

                    PrerequisitesList { Layout.fillWidth: true }

                    AppButton {
                        icon: "refresh"
                        text: qsTr("Check again")
                        onClicked: PrerequisitesManager.refresh()
                    }
                }

                // ---- Engine and tools
                ToolsSettingsTab {
                    visible: root.category === "engine"
                    Layout.fillWidth: true
                }

                // ---- About
                ColumnLayout {
                    visible: root.category === "about"
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Noi Engine is a small 2D game engine with a visual editor. Your projects are plain folders: scenes are JSON files, scripts are C++.")
                        font.pixelSize: 13
                        color: Theme.darkGrey
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: [
                            { label: qsTr("Engine"), url: "https://github.com/noi-engine/noi_engine" },
                            { label: qsTr("Editor"), url: "https://github.com/noi-engine/noi_engine_editor" },
                            { label: qsTr("2D template"), url: "https://github.com/noi-engine/template-basic-2d" }
                        ]

                        delegate: AppButton {
                            required property var modelData
                            Layout.alignment: Qt.AlignLeft
                            icon: "open_in_new"
                            text: modelData.label + " — " + modelData.url.replace("https://", "")
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }
        }
    }
}
