import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Tab strip above the viewport (like the scene tabs of other editors): the open scene, a menu to
// switch to any other scene of the project, and "+" to create one.
Rectangle {
    id: root

    property string currentScenePath: ""
    property bool sceneDirty: false

    signal sceneChosen(string filePath)
    signal newSceneRequested()

    readonly property string currentName: currentScenePath === "" ? "" : currentScenePath.substring(currentScenePath.lastIndexOf("/") + 1)

    implicitHeight: 40
    color: Theme.bgSecondary

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderColor
    }

    function scenesOfProject() {
        return CurrentProjectResourcesManager.getAllScenesRecursively(CurrentProjectManager.resourcesPath());
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        // The open scene
        Rectangle {
            visible: root.currentScenePath !== ""
            Layout.preferredHeight: 28
            implicitWidth: tabRow.implicitWidth + 24
            radius: 8
            color: Theme.bgElevated
            border.color: Theme.borderStrong

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 16
                height: 2
                radius: 1
                color: Theme.primaryColor
            }

            RowLayout {
                id: tabRow
                anchors.centerIn: parent
                spacing: 7

                MuiIcon {
                    name: "landscape"
                    font.pixelSize: 15
                    color: Theme.primaryColor
                }

                Text {
                    text: root.currentName
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.white
                }

                Rectangle {
                    visible: root.sceneDirty
                    Layout.preferredWidth: 7
                    Layout.preferredHeight: 7
                    radius: 4
                    color: Theme.warning
                }
            }
        }

        Text {
            visible: root.currentScenePath === ""
            text: qsTr("No scene open")
            font.pixelSize: 12
            color: Theme.grey
        }

        // Other scenes of the project
        AppButton {
            id: switchButton
            compact: true
            implicitHeight: 28
            icon: "unfold_more"
            text: qsTr("Switch scene")
            tooltip: qsTr("Open another scene of this project")
            onClicked: {
                sceneMenuModel.clear();
                for (const path of root.scenesOfProject()) {
                    sceneMenuModel.append({ path: path, name: path.substring(path.lastIndexOf("/") + 1) });
                }
                sceneMenu.popup(switchButton, 0, switchButton.height + 4);
            }

            Menu {
                id: sceneMenu

                Instantiator {
                    model: ListModel { id: sceneMenuModel }
                    delegate: MenuItem {
                        required property string path
                        required property string name
                        text: name + (path === root.currentScenePath ? "  ✓" : "")
                        onTriggered: root.sceneChosen(path)
                    }
                    onObjectAdded: (index, object) => sceneMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => sceneMenu.removeItem(object)
                }
            }
        }

        AppButton {
            compact: true
            implicitHeight: 28
            icon: "add"
            text: qsTr("New scene")
            tooltip: qsTr("Create a new scene")
            onClicked: root.newSceneRequested()
        }

        Item { Layout.fillWidth: true }
    }
}
