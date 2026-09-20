import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: rootItem

    signal sceneOpenRequested(string filePath)
    signal sceneRenamed(string oldPath, string newPath)

    readonly property string rawRootFolder: CurrentProjectManager.resourcesPath()
    readonly property bool scenesAvailable: !ProjectBuilder.isCompiling && !ProjectBuilder.lastCompileFailed
    property string pendingScenePath: ""
    property string pendingSceneName: ""
    property real itemScale: 1.0
    property bool sceneDirty: false
    property string currentScenePath: ""

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

    function duplicateScene(filePath, fileName) {
        const dotIndex = fileName.lastIndexOf(".");
        const stem = dotIndex >= 0 ? fileName.substring(0, dotIndex) : fileName;
        const ext = dotIndex >= 0 ? fileName.substring(dotIndex) : "";
        let candidate = stem + " copy" + ext;
        let suffix = 2;
        while (CurrentProjectResourcesManager.duplicateItem(filePath, candidate) === false) {
            candidate = stem + " copy " + suffix + ext;
            suffix++;
            if (suffix > 50) return; // give up rather than loop forever on an unexpected error
        }
        rootItem.refreshScenes();
    }

    function createNewScene(parentFolderPath, sceneName) {
        const fileName = sceneName.endsWith(".scene") ? sceneName : sceneName + ".scene";
        const content = JSON.stringify({
            name: sceneName,
            resources: {},
            entities: [
                { name: "main_camera", components: [ { type: "camera_2d" } ] }
            ]
        }, null, 2);

        if (CurrentProjectResourcesManager.createFile(parentFolderPath, fileName, content)) {
            rootItem.refreshScenes();
        }
    }

    Connections {
        target: ProjectBuilder

        function onCompileFinished(success) {
            if (success) {
                rootItem.refreshScenes();
            }
        }
    }

    Dialog {
        id: confirmDialog
        title: rootItem.sceneDirty ? qsTr("Unsaved Changes") : qsTr("Open Scene")
        modal: true
        anchors.centerIn: parent
        width: 320
        standardButtons: Dialog.NoButton

        background: Rectangle {
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            radius: 6
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            Text {
                Layout.fillWidth: true
                text: rootItem.sceneDirty
                    ? qsTr("Unsaved changes will be lost. Open '%1'?").arg(rootItem.pendingSceneName)
                    : qsTr("Open '%1'?").arg(rootItem.pendingSceneName)
                color: Theme.darkGrey
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("No")
                    onClicked: confirmDialog.reject()
                }

                AppButton {
                    text: qsTr("Yes")
                    onClicked: confirmDialog.accept()
                }
            }
        }

        onAccepted: if (rootItem.pendingScenePath) rootItem.sceneOpenRequested(rootItem.pendingScenePath)
    }

    NewSceneDialog {
        id: newSceneDialog
        onConfirmed: function (sceneName) {
            rootItem.createNewScene(targetPath, sceneName);
        }
    }

    RenameDialog {
        id: renameSceneDialog
        onConfirmed: function (newName) {
            const oldPath = renameSceneDialog.targetPath;
            if (CurrentProjectResourcesManager.renameScene(oldPath, newName)) {
                const stem = newName.endsWith(".scene") ? newName.substring(0, newName.length - 6) : newName;
                const dir = oldPath.substring(0, oldPath.lastIndexOf("/"));
                rootItem.sceneRenamed(oldPath, dir + "/" + stem + ".scene");
                rootItem.refreshScenes();
            }
        }
    }

    DeleteConfirmDialog {
        id: deleteSceneDialog
        title: qsTr("Delete Scene")
        onConfirmed: {
            if (CurrentProjectResourcesManager.deleteItem(deleteSceneDialog.targetPath)) {
                rootItem.refreshScenes();
            }
        }
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

                    Text {
                        visible: !rootItem.scenesAvailable
                        text: ProjectBuilder.isCompiling ? qsTr("Compiling…") : qsTr("Build failed — fix errors to open scenes")
                        color: ProjectBuilder.isCompiling ? Theme.darkGrey : "#ff6b6b"
                        font.pixelSize: 10
                        font.italic: true
                    }

                    Item { Layout.fillWidth: true }

                    MuiIcon {
                        name: "add"
                        font.pixelSize: 18
                        color: newSceneArea.containsMouse ? Theme.white : Theme.darkGrey
                        visible: rootItem.scenesAvailable

                        MouseArea {
                            id: newSceneArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: newSceneDialog.openFor(rootItem.rawRootFolder + "/scenes")
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 16
                        color: Theme.borderColor
                    }

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
                    opacity: rootItem.scenesAvailable ? 1.0 : 0.45

                    readonly property bool isCurrentScene: model.filePath === rootItem.currentScenePath

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 8
                        color: itemArea.containsMouse ? Theme.bgTertiary : Theme.bgPrimary
                        border.color: isCurrentScene
                            ? Theme.primaryColor
                            : (itemArea.containsMouse ? Theme.primaryColor : Theme.borderColor)
                        border.width: isCurrentScene ? 2 : (itemArea.containsMouse ? 1.5 : 1)

                        Rectangle {
                            visible: isCurrentScene && rootItem.sceneDirty
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            width: 8
                            height: 8
                            radius: 4
                            color: "#ff6b6b"
                        }

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
                            enabled: rootItem.scenesAvailable
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    sceneMenu.popup();
                                }
                            }
                            onDoubleClicked: (mouse) => {
                                if (mouse.button !== Qt.LeftButton) {
                                    return;
                                }
                                if (model.filePath === rootItem.currentScenePath) {
                                    return; // already the open scene, nothing to confirm
                                }
                                rootItem.pendingScenePath = model.filePath;
                                rootItem.pendingSceneName = model.fileName;
                                confirmDialog.open();
                            }

                            Menu {
                                id: sceneMenu
                                MenuItem {
                                    text: qsTr("Rename")
                                    onTriggered: {
                                        const dot = model.fileName.lastIndexOf(".");
                                        const stem = dot >= 0 ? model.fileName.substring(0, dot) : model.fileName;
                                        renameSceneDialog.openFor(model.filePath, stem);
                                    }
                                }
                                MenuItem {
                                    text: qsTr("Duplicate")
                                    onTriggered: rootItem.duplicateScene(model.filePath, model.fileName)
                                }
                                MenuItem {
                                    text: qsTr("Delete")
                                    onTriggered: deleteSceneDialog.openFor(model.filePath, model.fileName)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}