import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import noi_engine_editor
import "../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

// Makes a new image available as a loaded texture resource: copies it into the project's
// resources/textures/ folder, declares it in the currently-open scene's own
// resources.textures block, and asks the viewport to reload that scene from disk so the
// bridge actually picks it up (see OpenGLView::reloadScene()). There is deliberately no
// generic "add_resource" bridge call - a texture only exists to the engine by being declared
// in a scene's resources, so that's the only place it can be added from.
Item {
    id: root

    property string resourcesPath: ""
    property string scenePath: ""

    signal imported(string textureLabel)
    signal reloadRequested()

    property string errorText: ""
    property bool busy: false

    function baseName(fileName) {
        const dot = fileName.lastIndexOf(".");
        return dot > 0 ? fileName.substring(0, dot) : fileName;
    }

    function uniqueLabel(desired, taken) {
        if (taken.indexOf(desired) === -1) return desired;
        let suffix = 2;
        while (taken.indexOf(desired + "_" + suffix) !== -1) suffix++;
        return desired + "_" + suffix;
    }

    function importImage(localFilePath) {
        if (root.scenePath === "" || root.resourcesPath === "") {
            root.errorText = qsTr("Open a scene before importing a texture.");
            return;
        }

        root.errorText = "";
        root.busy = true;

        const fileName = localFilePath.substring(Math.max(localFilePath.lastIndexOf("/"), localFilePath.lastIndexOf("\\")) + 1);
        const relativePath = "textures/" + fileName;

        if (!CurrentProjectResourcesManager.importPaths([localFilePath], root.resourcesPath + "/textures")) {
            root.errorText = qsTr("Could not copy %1 into resources/textures.").arg(fileName);
            root.busy = false;
            return;
        }

        const raw = CurrentProjectResourcesManager.readFile(root.scenePath);
        let scene;
        try {
            scene = JSON.parse(raw);
        } catch (e) {
            root.errorText = qsTr("Scene file is not valid JSON - can't declare the texture.");
            root.busy = false;
            return;
        }

        if (!scene.resources) scene.resources = {};
        if (!scene.resources.textures) scene.resources.textures = [];

        // Re-importing the same file should point at the same texture rather than piling up
        // duplicate resource entries for it.
        for (let i = 0; i < scene.resources.textures.length; i++) {
            if (scene.resources.textures[i].path === relativePath) {
                root.busy = false;
                root.imported(scene.resources.textures[i].name);
                return;
            }
        }

        const existingNames = scene.resources.textures.map(t => t.name);
        const label = root.uniqueLabel(root.baseName(fileName), existingNames);
        scene.resources.textures.push({ "name": label, "path": relativePath });

        if (!CurrentProjectResourcesManager.writeFile(root.scenePath, JSON.stringify(scene, null, 2))) {
            root.errorText = qsTr("Could not update the scene file with the new texture.");
            root.busy = false;
            return;
        }

        root.busy = false;
        root.reloadRequested();
        root.imported(label);
    }

    // Loaded on demand rather than declared inline - instantiating a FileDialog eagerly pulls in
    // the native style's dialog chrome (SideBar.qml, etc.) at editor startup, which spams the
    // console with binding-loop/null warnings before the dialog is ever shown.
    Loader {
        id: filePickerLoader
        active: false

        sourceComponent: FileDialog {
            title: qsTr("Select Image")
            fileMode: FileDialog.OpenFile
            nameFilters: [qsTr("Images (*.png *.jpg *.jpeg *.bmp *.tga *.gif)"), qsTr("All files (*)")]
            onAccepted: {
                root.importImage(UrlConverter.toLocalPath(selectedFile.toString()));
                filePickerLoader.active = false;
            }
            onRejected: filePickerLoader.active = false
            Component.onCompleted: open()
        }
    }

    function pick() {
        root.errorText = "";
        filePickerLoader.active = true;
    }
}
