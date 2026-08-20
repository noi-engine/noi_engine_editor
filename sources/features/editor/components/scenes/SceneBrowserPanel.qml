import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: rootItem

    signal sceneOpenRequested(string filePath)

    readonly property string rawRootFolder: CurrentProjectManager.resourcesPath()
    property string pendingScenePath: ""
    property string pendingSceneName: ""
    property real itemScale: 1.0

    ListModel { id: scenesModel }

    function refreshScenes() {
        scenesModel.clear();
        let scenePaths = CurrentProjectResourcesManager.getAllScenesRecursively(rawRootFolder);
        for (let i = 0; i < scenePaths.length; i++) {
            let path = scenePaths[i];
            scenesModel.append({
                "filePath": path,
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
                Layout.preferredHeight: 36
                color: Theme.bgTertiary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: qsTr("SCENES (%1)").arg(scenesModel.count)
                        color: Theme.white
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    MuiIcon {
                        name: "photo_size_select_actual"
                        font.pixelSize: 16
                        color: Theme.darkGrey
                    }

                    Slider {
                        id: sizeSlider
                        implicitWidth: 100
                        from: 0.8
                        to: 1.8
                        value: 1.0
                        onValueChanged: rootItem.itemScale = value
                    }

                    Rectangle {
                        width: 1
                        height: 16
                        color: Theme.borderColor
                    }

                    MuiIcon {
                        name: "refresh"
                        font.pixelSize: 18
                        color: refreshArea.containsMouse ? Theme.white : Theme.darkGrey

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootItem.refreshScenes()
                        }
                    }
                }
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                cellWidth: 160 * rootItem.itemScale
                cellHeight: 120 * rootItem.itemScale
                clip: true
                model: scenesModel

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: itemArea.containsMouse ? Theme.bgTertiary : Theme.bgPrimary
                        border.color: itemArea.containsMouse ? Theme.primaryColor : Theme.borderColor
                        border.width: itemArea.containsMouse ? 1.5 : 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: Theme.bgSecondary

                                MuiIcon {
                                    anchors.centerIn: parent
                                    name: "landscape"
                                    font.pixelSize: 28 * rootItem.itemScale
                                    color: itemArea.containsMouse ? Theme.primaryColor : Theme.darkGrey
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.fileName
                                color: Theme.white
                                font.bold: true
                                font.pixelSize: Math.max(9, 11 * (rootItem.itemScale * 0.85))
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.displayPath
                                color: Theme.darkGrey
                                font.pixelSize: Math.max(8, 9 * (rootItem.itemScale * 0.85))
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
}