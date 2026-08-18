import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: rootItem

    signal sceneOpenRequested(string filePath)

    function toFolderUrl(pathStr) {
        if (!pathStr) return "";
        let str = pathStr.toString();
        return str.startsWith("file://") ? str : "file://" + str;
    }

    readonly property string rawRootFolder: CurrentProjectManager.resourcesPath()
    property string pendingScenePath: ""
    property string pendingSceneName: ""

    ListModel { id: scenesModel }

    function refreshScenes() {
        scenesModel.clear();
        let scenePaths = CurrentProjectResourcesManager.getAllScenesRecursively(rawRootFolder);
        for (let i = 0; i < scenePaths.length; i++) {
            let path = scenePaths[i];
            scenesModel.append({
                "filePath": rootItem.toFolderUrl(path),
                "fileName": path.substring(path.lastIndexOf("/") + 1),
                "displayPath": path.replace(rawRootFolder + "/", "")
            });
        }
    }

    Component.onCompleted: refreshScenes()

    Dialog {
        id: confirmDialog
        title: qsTr("Open Scene")
        modal: true
        anchors.centerIn: parent
        width: 320
        standardButtons: Dialog.Yes | Dialog.No

        background: Rectangle {
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            radius: 6
        }

        contentItem: Text {
            text: qsTr("Open '%1'? Unsaved changes will be lost.").arg(rootItem.pendingSceneName)
            color: Theme.darkGrey
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        onAccepted: if (rootItem.pendingScenePath) rootItem.sceneOpenRequested(rootItem.pendingScenePath)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: Theme.bgTertiary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    Text {
                        text: qsTr("SCENES (%1)").arg(scenesModel.count)
                        color: Theme.darkGrey
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        flat: true
                        implicitHeight: 24
                        text: qsTr("Refresh")
                        onClicked: rootItem.refreshScenes()
                    }
                }
            }

            GridView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8
                cellWidth: 220
                cellHeight: 60
                clip: true
                model: scenesModel

                delegate: Rectangle {
                    width: GridView.view.cellWidth - 8
                    height: GridView.view.cellHeight - 8
                    radius: 6
                    color: itemArea.containsMouse ? Theme.bgTertiary : Theme.bgPrimary
                    border.color: itemArea.containsMouse ? Theme.primaryColor : Theme.borderColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 4
                            color: itemArea.containsMouse ? Theme.primaryLightB : Theme.bgSecondary

                            Text {
                                anchors.centerIn: parent
                                text: "▶"
                                color: itemArea.containsMouse ? Theme.primaryColor : Theme.darkGrey
                                font.pixelSize: 10
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: model.fileName
                                color: Theme.white
                                font.bold: true
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.displayPath
                                color: Theme.darkGrey
                                font.pixelSize: 9
                                elide: Text.ElideLeft
                            }
                        }
                    }

                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: {
                            rootItem.pendingScenePath = model.filePath;
                            rootItem.pendingSceneName = model.fileName;
                            confirmDialog.open();
                        }
                    }
                }
            }
        }
    }
}