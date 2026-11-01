import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import noi_engine_editor
import "../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

// Makes an image available as a loaded texture resource: copies it into the project's
// resources/textures/ folder if needed (importImage), declares it in the currently-open scene's
// own resources.textures block (declareImage), and asks the viewport to reload that scene from disk so the
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

    // Copies an image from anywhere into resources/textures/, then declares it.
    function importImage(localFilePath) {
        if (root.scenePath === "" || root.resourcesPath === "") {
            root.errorText = qsTr("Open a scene before importing a texture.");
            return;
        }

        const fileName = localFilePath.substring(Math.max(localFilePath.lastIndexOf("/"), localFilePath.lastIndexOf("\\")) + 1);
        if (!CurrentProjectResourcesManager.importPaths([localFilePath], root.resourcesPath + "/textures")) {
            root.errorText = qsTr("Could not copy %1 into resources/textures.").arg(fileName);
            return;
        }
        const label = root.declareImage(root.resourcesPath + "/textures/" + fileName);
        if (label !== "") root.imported(label);
    }

    // Declares an image that is already inside the project's resources folder in the open
    // scene's resources.textures block (asking for a reload when it's new). Returns its
    // texture label, or "" on error.
    function declareImage(absolutePath) {
        root.errorText = "";
        if (root.scenePath === "" || root.resourcesPath === "") {
            root.errorText = qsTr("Open a scene first.");
            return "";
        }
        const prefix = root.resourcesPath + "/";
        if (!absolutePath.startsWith(prefix)) {
            root.errorText = qsTr("The image must be inside the project's resources folder.");
            return "";
        }
        const relativePath = absolutePath.substring(prefix.length);
        const fileName = relativePath.substring(relativePath.lastIndexOf("/") + 1);

        let scene;
        try {
            scene = JSON.parse(CurrentProjectResourcesManager.readFile(root.scenePath));
        } catch (e) {
            root.errorText = qsTr("Scene file is not valid JSON - can't declare the texture.");
            return "";
        }

        if (!scene.resources) scene.resources = {};
        if (!scene.resources.textures) scene.resources.textures = [];

        // Already declared: reuse it rather than piling up duplicate entries.
        for (const texture of scene.resources.textures) {
            if (texture.path === relativePath) return texture.name;
        }

        const label = root.uniqueLabel(root.baseName(fileName), scene.resources.textures.map(t => t.name));
        scene.resources.textures.push({ "name": label, "path": relativePath });

        if (!CurrentProjectResourcesManager.writeFile(root.scenePath, JSON.stringify(scene, null, 2))) {
            root.errorText = qsTr("Could not update the scene file with the new texture.");
            return "";
        }

        root.reloadRequested();
        return label;
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
