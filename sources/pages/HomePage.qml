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

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    FolderDialog {
        id: openProjectFolderDialog
        title: qsTr("Select Project Folder")

        onAccepted: {
            let localPath = UrlConverter.toLocalPath(selectedFolder);
            if (CurrentProjectManager.openProject(localPath)) {
                RecentProjectsManager.addProject(UrlConverter.getFolderName(localPath), localPath);
                Router.push("/editor");
            }
        }
    }

    Flickable {
        id: flickable

        anchors.fill: parent

        anchors.leftMargin: root.width >= 1200 ? 48 : 24
        anchors.rightMargin: root.width >= 1200 ? 48 : 24
        anchors.topMargin: root.height >= 700 ? 40 : 24
        anchors.bottomMargin: root.height >= 700 ? 40 : 24

        contentWidth: flickable.width
        contentHeight: contentColumn.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn

            width: Math.min(flickable.width, 1500)
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 30

            HeroHeader {
                Layout.fillWidth: true
            }

            QuickActionsRow {
                Layout.fillWidth: true
                onCreateProjectRequested: Router.push("/create")
                onOpenProjectRequested: openProjectFolderDialog.open()
            }

            RecentProjectsSection {
                Layout.fillWidth: true
                model: recentProjectsModel
                onProjectClicked: path => {
                    if (CurrentProjectManager.openProject(path)) {
                        Router.push("/editor");
                    }else{
                        RecentProjectsManager.removeProject(path);
                    }
                }
            }

            Item {
                Layout.preferredHeight: 20
                Layout.fillWidth: true
            }
        }
    }
}
