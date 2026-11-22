import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

CustomPage {
    id: root

    title: qsTr("HomePage")

    RecentProjectsModel {
        id: recentProjectsModel
        manager: RecentProjectsManager
    }

    SettingsDialog {
        id: settingsDialog
    }

    PrerequisitesDialog {
        id: prerequisitesDialog
    }

    CreateProjectDialog {
        id: createProjectDialog
    }

    // Development aid (screenshots): `--demo createProject|settings`.
    function demo(name) {
        if (name === "createProject") createProjectDialog.open();
        else if (name === "settings") settingsDialog.open();
        else if (name === "prerequisites") prerequisitesDialog.open();
    }

    // Background: near-black, with a faint mint glow fading down from the top.
    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.6
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.24, 0.86, 0.59, 0.07) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    ProjectOpenErrorDialog {
        id: projectOpenErrorDialog

        onProjectOpened: path => {
            RecentProjectsManager.addProject(UrlConverter.getFolderName(path), path);
            Router.push("/editor");
        }
    }

    FolderDialog {
        id: openProjectFolderDialog
        title: qsTr("Select Project Folder")

        onAccepted: {
            let localPath = UrlConverter.toLocalPath(selectedFolder);
            if (CurrentProjectManager.openProject(localPath)) {
                RecentProjectsManager.addProject(UrlConverter.getFolderName(localPath), localPath);
                Router.push("/editor");
            } else {
                projectOpenErrorDialog.openFor(localPath);
            }
        }
    }

    function openRecent(path) {
        if (CurrentProjectManager.openProject(path)) {
            Router.push("/editor");
        } else if (!CurrentProjectManager.isProjectFolder(path)) {
            // The project was moved or deleted.
            RecentProjectsManager.removeProject(path);
            Notifier.warning(qsTr("That project folder no longer exists: it was removed from the list."));
        } else {
            projectOpenErrorDialog.openFor(path);
        }
    }

    function greeting() {
        const hour = new Date().getHours();
        return hour < 5 ? qsTr("Working late?") : hour < 12 ? qsTr("Good morning") : hour < 18 ? qsTr("Good afternoon") : qsTr("Good evening");
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        HomeSidebar {
            Layout.fillHeight: true
            Layout.preferredWidth: compact ? 72 : 252
            compact: root.width < 1000
            missingCount: PrerequisitesManager.items.filter(i => !i.found).length

            onNewProjectRequested: createProjectDialog.open()
            onOpenProjectRequested: openProjectFolderDialog.open()
            onSettingsRequested: settingsDialog.open()
            onToolsRequested: prerequisitesDialog.open()
        }

        Flickable {
            id: flickable

            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: width
            contentHeight: page.implicitHeight + 2 * pagePadding
            readonly property real pagePadding: root.width >= 1300 ? 44 : 24

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: page

                x: Math.max(flickable.pagePadding, (flickable.width - width) / 2)
                y: flickable.pagePadding
                width: Math.min(flickable.width - 2 * flickable.pagePadding, 1280)
                spacing: 28

                // ---- Header: greeting + search
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.greeting()
                            font.pixelSize: 30
                            font.weight: Font.Bold
                            color: Theme.white
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Pick up where you left off, or start something new.")
                            font.pixelSize: 14
                            color: Theme.darkGrey
                            wrapMode: Text.WordWrap
                        }
                    }

                    SearchField {
                        id: searchField
                        Layout.preferredWidth: Math.min(320, page.width * 0.4)
                        Layout.preferredHeight: 42
                        placeholderText: qsTr("Search projects…")
                    }
                }

                // ---- Hero
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.width >= 1100 ? 220 : 190
                    radius: Theme.radiusLarge
                    color: Theme.bgSecondary
                    border.color: Theme.borderColor
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "/images/hero.png"
                        fillMode: Image.PreserveAspectCrop
                        horizontalAlignment: Image.AlignRight
                        mipmap: true
                        asynchronous: true
                        opacity: 0.9
                    }

                    // Fades the picture into the page colour so the text stays readable.
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.055, 0.047, 0.98) }
                            GradientStop { position: 0.45; color: Qt.rgba(0.04, 0.055, 0.047, 0.82) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.04, 0.055, 0.047, 0.1) }
                        }
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 34
                        width: Math.min(parent.width * 0.6, 520)
                        spacing: 10

                        Text {
                            text: qsTr("Make your next 2D game")
                            font.pixelSize: root.width >= 1100 ? 28 : 22
                            font.weight: Font.Bold
                            color: Theme.white
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: qsTr("Arrange objects in a scene, add behaviour with scripts, press Play. Share the result as a game anyone can run.")
                            font.pixelSize: 13
                            color: Theme.darkGrey
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.topMargin: 6
                            spacing: 10

                            AppButton {
                                primary: true
                                icon: "add_box"
                                text: qsTr("Create a project")
                                onClicked: createProjectDialog.open()
                            }

                            AppButton {
                                icon: "folder_open"
                                text: qsTr("Open existing")
                                onClicked: openProjectFolderDialog.open()
                            }
                        }
                    }
                }

                // ---- Missing tools: shown only when something is missing, with the way out.
                Banner {
                    Layout.fillWidth: true
                    visible: !PrerequisitesManager.canRelease
                    kind: PrerequisitesManager.canBuild ? "warning" : "error"
                    title: PrerequisitesManager.canBuild
                           ? qsTr("Some tools are missing for release builds")
                           : qsTr("Some tools are missing to compile your games")
                    text: qsTr("Missing: %1. You can still create and edit projects.").arg(PrerequisitesManager.missingSummary)
                    actionText: qsTr("How to install")
                    onActionTriggered: prerequisitesDialog.open()
                }

                // ---- Projects
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Your projects")
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                        color: Theme.white
                    }

                    Rectangle {
                        Layout.preferredWidth: countLabel.implicitWidth + 16
                        Layout.preferredHeight: 22
                        radius: 11
                        color: Theme.bgTertiary

                        Text {
                            id: countLabel
                            anchors.centerIn: parent
                            text: recentRepeater.count
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.darkGrey
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AppButton {
                        implicitHeight: 34
                        icon: "folder_open"
                        text: qsTr("Open…")
                        onClicked: openProjectFolderDialog.open()
                    }

                    AppButton {
                        implicitHeight: 34
                        primary: true
                        icon: "add"
                        text: qsTr("New project")
                        onClicked: createProjectDialog.open()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        id: recentRepeater
                        model: recentProjectsModel

                        delegate: ProjectRow {
                            required property string name
                            required property string path
                            required property string lastOpened

                            projectName: name
                            projectPath: path
                            projectDate: lastOpened

                            Layout.fillWidth: true

                            visible: searchField.text.trim() === "" ||
                                     name.toLowerCase().includes(searchField.text.trim().toLowerCase())

                            onClicked: root.openRecent(path)
                            onRemoveRequested: RecentProjectsManager.removeProject(path)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: recentRepeater.count === 0
                    text: qsTr("Your projects will show up here. Press “New project” to make your first game.")
                    font.pixelSize: 13
                    color: Theme.grey
                    wrapMode: Text.WordWrap
                }

                // ---- How it works
                Text {
                    Layout.topMargin: 10
                    text: qsTr("How it works")
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                    color: Theme.white
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: page.width >= 900 ? 4 : 2
                    columnSpacing: 14
                    rowSpacing: 14

                    Repeater {
                        model: [
                            { n: "1", icon: "add_circle", t: qsTr("Create"), d: qsTr("Start from a template: a small game that already runs.") },
                            { n: "2", icon: "edit", t: qsTr("Edit your scene"), d: qsTr("Add objects, drag images in, move them in the viewport.") },
                            { n: "3", icon: "play_arrow", t: qsTr("Save and Play"), d: qsTr("Ctrl+S saves. Play runs the game inside the editor.") },
                            { n: "4", icon: "inventory_2", t: qsTr("Build a release"), d: qsTr("Packs your game as an archive anyone can unzip and run.") }
                        ]

                        delegate: Card {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: stepColumn.implicitHeight + 30

                            ColumnLayout {
                                id: stepColumn
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                RowLayout {
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        radius: 10
                                        color: Theme.primaryLightB

                                        MuiIcon {
                                            anchors.centerIn: parent
                                            name: modelData.icon
                                            font.pixelSize: 18
                                            color: Theme.primaryColor
                                        }
                                    }

                                    Text {
                                        text: modelData.n
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Theme.lightGrey
                                    }
                                }

                                Text {
                                    text: modelData.t
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: Theme.white
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.d
                                    font.pixelSize: 12
                                    color: Theme.darkGrey
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 10 }
            }
        }
    }
}
