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
    property real itemScale: 1.0
    property bool sceneDirty: false
    property string currentScenePath: ""

    ListModel { id: scenesModel }

    property string searchText: ""
    onSearchTextChanged: refreshScenes()

    function refreshScenes() {
        scenesModel.clear();
        const query = rootItem.searchText.trim().toLowerCase();
        let scenePaths = CurrentProjectResourcesManager.getAllScenesRecursively(rawRootFolder);
        for (let i = 0; i < scenePaths.length; i++) {
            let path = scenePaths[i];
            if (query !== "" && path.replace(rawRootFolder + "/", "").toLowerCase().indexOf(query) === -1) {
                continue;
            }
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
            Notifier.success(qsTr("Scene “%1” created and opened. Add objects from the Hierarchy.").arg(sceneName));
            rootItem.sceneOpenRequested(parentFolderPath + "/" + fileName);
        } else {
            Notifier.error(qsTr("Couldn't create “%1”: a scene with that name already exists or the folder can't be written.").arg(fileName));
        }
    }

    function relativeScenePath(filePath) {
        return filePath.replace(rawRootFolder + "/", "");
    }

    function isStartScene(filePath) {
        return CurrentProjectManager.startScene !== "" && relativeScenePath(filePath) === CurrentProjectManager.startScene;
    }

    function setStartScene(filePath) {
        CurrentProjectManager.startScene = relativeScenePath(filePath);
        if (CurrentProjectManager.saveProject()) {
            Notifier.success(qsTr("The game will now start on “%1”.").arg(filePath.substring(filePath.lastIndexOf("/") + 1)));
        } else {
            Notifier.error(qsTr("Couldn't save the project file."));
        }
        refreshScenes();
    }

    Connections {
        target: ProjectBuilder

        function onCompileFinished(success) {
            if (success) {
                rootItem.refreshScenes();
            }
        }
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
            } else {
                Notifier.error(qsTr("Couldn't rename the scene to \"%1\": a scene with that name probably already exists.").arg(newName));
            }

        }
    }

    DeleteConfirmDialog {
        id: deleteSceneDialog
        title: qsTr("Delete Scene")
        onConfirmed: {
            if (deleteSceneDialog.targetPath === rootItem.currentScenePath) {
                Notifier.warning(qsTr("This scene is open. Open another scene first, then delete it."));
            } else if (rootItem.isStartScene(deleteSceneDialog.targetPath)) {
                Notifier.warning(qsTr("This is the scene your game starts on. Choose another start scene first."));
            } else if (CurrentProjectResourcesManager.deleteItem(deleteSceneDialog.targetPath)) {
                rootItem.refreshScenes();
                Notifier.info(qsTr("Scene deleted"));
            } else {
                Notifier.error(qsTr("Couldn't delete the scene file."));
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
                        text: qsTr("Scenes (%1)").arg(scenesModel.count)
                        color: Theme.white
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        visible: rootItem.scenesAvailable && scenesModel.count > 0
                        text: qsTr("A scene is one screen of your game (a level, a menu…). Double-click one to open it.")
                        color: Theme.grey
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.maximumWidth: 460
                    }

                    Text {
                        visible: !rootItem.scenesAvailable
                        text: ProjectBuilder.isCompiling ? qsTr("Compiling…") : qsTr("Build failed — fix errors to open scenes")
                        color: ProjectBuilder.isCompiling ? Theme.darkGrey : "#ff6b6b"
                        font.pixelSize: 10
                        font.italic: true
                    }

                    Item { Layout.fillWidth: true }

                    PanelSearchField {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 24
                        placeholderText: qsTr("Search scenes...")
                        onTextChanged: rootItem.searchText = text
                    }

                    AppButton {
                        visible: rootItem.scenesAvailable
                        implicitHeight: 26
                        icon: "add"
                        text: qsTr("New scene")
                        primary: true
                        onClicked: newSceneDialog.openFor(rootItem.rawRootFolder + "/scenes")
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

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: scenesModel.count === 0 && rootItem.scenesAvailable
                spacing: 10

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: rootItem.searchText.trim() !== "" ? qsTr("No scene matches your search") : qsTr("This project has no scene yet")
                    color: Theme.white
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 420
                    visible: rootItem.searchText.trim() === ""
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("A scene holds the objects of one screen of your game. Create one to start placing objects.")
                    color: Theme.darkGrey
                    font.pixelSize: 12
                }

                AppButton {
                    Layout.alignment: Qt.AlignHCenter
                    visible: rootItem.searchText.trim() === ""
                    primary: true
                    icon: "add"
                    text: qsTr("Create the first scene")
                    onClicked: newSceneDialog.openFor(rootItem.rawRootFolder + "/scenes")
                }

                Item { Layout.fillHeight: true }
            }

            GridView {
                id: gridView
                visible: scenesModel.count > 0
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
                            visible: rootItem.isStartScene(model.filePath)
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 6
                            width: startLabel.implicitWidth + 12
                            height: 18
                            radius: 9
                            color: Theme.primaryLightB
                            Text {
                                id: startLabel
                                anchors.centerIn: parent
                                text: qsTr("Game starts here")
                                font.pixelSize: 9
                                color: Theme.primaryLightA
                            }
                        }

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
                                // ProjectEditorPage asks about unsaved changes (save / don't save / cancel).
                                rootItem.sceneOpenRequested(model.filePath);
                            }

                            Menu {
                                id: sceneMenu
                                MenuItem {
                                    text: qsTr("Open")
                                    enabled: model.filePath !== rootItem.currentScenePath
                                    onTriggered: rootItem.sceneOpenRequested(model.filePath)
                                }
                                MenuItem {
                                    text: qsTr("Start the game on this scene")
                                    enabled: !rootItem.isStartScene(model.filePath)
                                    onTriggered: rootItem.setStartScene(model.filePath)
                                }
                                MenuSeparator {}
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