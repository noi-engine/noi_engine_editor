import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// "Sprite" is a convenience over transform + mesh_renderer + mesh_renderer_properties (see
// InspectorPanel.allComponentTypes for why those three aren't offered as separate raw entries).
// This step just lets the user pick which already-loaded texture the sprite should show -
// picking one switches the mesh_renderer onto the builtin texture material and points its
// u_texture at that resource; leaving it on "(none)" keeps today's plain-color-quad behavior.
// textureLabels is expected to be a live binding (not a one-time snapshot) so it picks up a
// texture just brought in via "Import Texture..." once the scene reload finishes.
AppDialog {
    id: root

    property var textureLabels: []
    property string resourcesPath: ""
    property string scenePath: ""
    signal confirmed(string textureLabel)
    signal reloadRequested()

    readonly property var comboItems: [qsTr("(none - plain color)")].concat(root.textureLabels)
    property string pendingSelectLabel: ""

    onTextureLabelsChanged: {
        if (root.pendingSelectLabel === "") return;
        const idx = root.textureLabels.indexOf(root.pendingSelectLabel);
        if (idx !== -1) {
            textureCombo.currentIndex = idx + 1; // +1 for the "(none)" entry at index 0
            root.pendingSelectLabel = "";
        }
    }

    title: qsTr("Add a sprite")
    subtitle: qsTr("A sprite is an object that shows a picture (or a plain color) in your scene.")
    icon: "image"
    preferredWidth: 480

    onOpened: {
        textureCombo.currentIndex = 0;
        root.pendingSelectLabel = "";
        importTexture.errorText = "";
    }

    ImportTextureDialog {
        id: importTexture
        resourcesPath: root.resourcesPath
        scenePath: root.scenePath
        onReloadRequested: root.reloadRequested()
        onImported: (label) => {
            root.pendingSelectLabel = label;
            // Already loaded (re-imported the same file) - onTextureLabelsChanged won't fire
            // again since the list didn't actually change, so select it directly.
            const idx = root.textureLabels.indexOf(label);
            if (idx !== -1) {
                textureCombo.currentIndex = idx + 1;
                root.pendingSelectLabel = "";
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: qsTr("Picture")
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Theme.darkGrey
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        ComboBox {
            id: textureCombo
            Layout.fillWidth: true
            model: root.comboItems
        }

        AppButton {
            text: importTexture.busy ? qsTr("Importing...") : qsTr("Import an image...")
            icon: "upload"
            enabled: !importTexture.busy
            onClicked: importTexture.pick()
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.textureLabels.length === 0 && importTexture.errorText === ""
        text: qsTr("No picture is loaded in this scene yet. Import an image, or add a plain-color sprite and change its color later.")
        color: Theme.darkGrey
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Banner {
        Layout.fillWidth: true
        kind: "error"
        visible: importTexture.errorText !== ""
        title: qsTr("The image couldn't be imported")
        text: importTexture.errorText
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Add sprite")
            icon: "add"
            primary: true
            onClicked: {
                root.confirmed(textureCombo.currentIndex === 0 ? "" : textureCombo.currentText)
                root.accept()
            }
        }
    ]
}
