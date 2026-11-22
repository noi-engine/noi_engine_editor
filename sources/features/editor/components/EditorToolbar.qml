import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// Top bar of the editor. Left: where you are (project and open scene). Right: the actions in the
// order you use them: Save, Build (compile / release), Play.
Rectangle {
    id: root

    signal settingsRequested()
    signal backRequested()
    signal playRequested()
    signal stopRequested()
    signal saveRequested()
    signal searchRequested()
    signal scenesRequested()
    signal buildHelpRequested()

    property string currentScenePath: ""
    property bool isPlaying: false
    property bool sceneDirty: false

    // Icon-only buttons on narrow windows (the labels stay in the tooltips).
    readonly property bool compact: width < 1180

    readonly property string currentSceneName: {
        if (!currentScenePath) return qsTr("No scene open")
        const parts = currentScenePath.split("/")
        return parts[parts.length - 1]
    }

    readonly property string playBlockedReason: {
        if (isPlaying) return ""
        if (currentScenePath === "") return qsTr("Open or create a scene first")
        if (ProjectBuilder.isCompiling) return qsTr("Wait for the build to finish")
        if (ProjectBuilder.lastCompileFailed) return qsTr("Fix the build errors first")
        return ""
    }

    color: Theme.bgSecondary

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        AppButton {
            icon: "arrow_back"
            compact: true
            text: qsTr("Back to projects")
            enabled: !root.isPlaying
            implicitHeight: 36
            onClicked: root.backRequested()
        }

        ColumnLayout {
            spacing: 0
            Layout.maximumWidth: root.compact ? 150 : 260

            Text {
                Layout.fillWidth: true
                text: CurrentProjectManager.name
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.white
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: CurrentProjectManager.path
                font.pixelSize: 10
                color: Theme.grey
                elide: Text.ElideMiddle
                visible: !root.compact
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 26
            color: Theme.borderColor
        }

        // The open scene. Click to see all scenes, create a new one or switch.
        Rectangle {
            id: sceneChip
            Layout.preferredHeight: 36
            implicitWidth: sceneRow.implicitWidth + 24
            Layout.maximumWidth: 260
            radius: Theme.radius
            color: chipArea.containsMouse ? Theme.bgTertiary : "transparent"
            border.color: Theme.borderColor

            RowLayout {
                id: sceneRow
                anchors.centerIn: parent
                spacing: 8

                MuiIcon {
                    name: "landscape"
                    font.pixelSize: 16
                    color: root.currentScenePath !== "" ? Theme.primaryColor : Theme.grey
                }

                Text {
                    Layout.maximumWidth: 170
                    text: root.currentSceneName
                    font.pixelSize: 13
                    font.bold: root.currentScenePath !== ""
                    color: root.currentScenePath !== "" ? Theme.white : Theme.darkGrey
                    elide: Text.ElideMiddle
                }

                Rectangle {
                    visible: root.sceneDirty
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.warning
                }

                MuiIcon {
                    name: "unfold_more"
                    font.pixelSize: 16
                    color: Theme.grey
                }
            }

            MouseArea {
                id: chipArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.scenesRequested()
            }

            ToolTip.visible: chipArea.containsMouse
            ToolTip.delay: 450
            ToolTip.text: qsTr("Scenes: switch, create or rename (a scene is one screen of your game)")
        }

        Item { Layout.fillWidth: true }

        // Opens the global search (Ctrl+K).
        Rectangle {
            Layout.preferredWidth: root.width >= 1500 ? 260 : 36
            Layout.preferredHeight: 36
            radius: Theme.radius
            color: Theme.bgPrimary
            border.color: searchArea.containsMouse ? Theme.primaryColor : Theme.borderColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                MuiIcon {
                    name: "search"
                    font.pixelSize: 16
                    color: Theme.grey
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.width >= 1500
                    text: qsTr("Search objects, scenes, files…")
                    font.pixelSize: 12
                    color: Theme.grey
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.width >= 1500
                    text: "Ctrl+K"
                    font.pixelSize: 10
                    color: Theme.darkGrey
                }
            }

            MouseArea {
                id: searchArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.searchRequested()
            }

            ToolTip.visible: searchArea.containsMouse
            ToolTip.delay: 450
            ToolTip.text: qsTr("Search everything (Ctrl+K)")
        }

        AppButton {
            id: saveButton
            icon: "save"
            text: root.sceneDirty ? qsTr("Save changes") : qsTr("Saved")
            compact: root.compact
            tooltip: root.sceneDirty ? qsTr("Save the scene (Ctrl+S)") : qsTr("All changes are saved")
            enabled: root.currentScenePath !== "" && !root.isPlaying && root.sceneDirty
            implicitHeight: 36
            primary: root.sceneDirty
            onClicked: root.saveRequested()
        }

        AppButton {
            id: buildButton
            icon: "construction"
            text: ProjectBuilder.isCompiling ? qsTr("Building…") : qsTr("Build")
            compact: root.compact
            tooltip: qsTr("Rebuild your scripts, or package your game")
            enabled: !ProjectBuilder.isCompiling && !root.isPlaying
            implicitHeight: 36
            onClicked: buildMenu.popup(buildButton, 0, buildButton.height + 4)

            Menu {
                id: buildMenu

                MenuItem {
                    text: qsTr("Compile scripts\tafter changing your code")
                    icon.source: ""
                    enabled: PrerequisitesManager.canBuild
                    onTriggered: ProjectBuilder.compile(CurrentProjectManager.path)
                }

                MenuItem {
                    text: qsTr("Build release…\tpackage the game to share it")
                    enabled: PrerequisitesManager.canRelease
                    onTriggered: ProjectBuilder.compileRelease(CurrentProjectManager.path)
                }

                MenuSeparator { visible: !PrerequisitesManager.canRelease }

                MenuItem {
                    visible: !PrerequisitesManager.canRelease
                    height: visible ? implicitHeight : 0
                    text: qsTr("Some tools are missing — see how to install them")
                    onTriggered: root.buildHelpRequested()
                }
            }
        }

        AppButton {
            icon: root.isPlaying ? "stop" : "play_arrow"
            text: root.isPlaying ? qsTr("Stop") : qsTr("Play")
            primary: !root.isPlaying
            danger: root.isPlaying
            tooltip: root.isPlaying ? qsTr("Stop the game and go back to editing")
                                    : (root.playBlockedReason !== "" ? root.playBlockedReason : qsTr("Run the game in the editor"))
            enabled: root.isPlaying || root.playBlockedReason === ""
            implicitHeight: 36
            Layout.preferredWidth: Math.max(implicitWidth, 96)
            onClicked: root.isPlaying ? root.stopRequested() : root.playRequested()
        }

        AppButton {
            icon: "settings"
            compact: true
            text: qsTr("Project settings")
            enabled: !root.isPlaying
            implicitHeight: 36
            onClicked: root.settingsRequested()
        }
    }
}
