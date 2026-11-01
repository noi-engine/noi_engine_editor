import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// "Add Property" for sections holding dynamic param:/color:/texture: entries
// (mesh_renderer_properties and materials).
Popup {
    id: addPropertyPopup

    property var inspector

    property string componentType: ""
    property var existingNames: []

    // Textures have no default/builtin fallback the way meshes and materials do (there is
    // no "always exists" texture) - a new texture *property* is only useful once it points
    // at a real, already-loaded texture resource, so unlike Parameter/Color it can't ship
    // with a safe placeholder default. Populated fresh each time the popup opens.
    readonly property var availableTextures: addPropertyPopup.inspector.resourceLabelsFor("texture").filter(l => l !== "")
    readonly property bool isTextureKind: addPropertyPopup.kinds[kindCombo.currentIndex]
        ? addPropertyPopup.kinds[kindCombo.currentIndex].prefix === "texture"
        : false

    // A freshly-imported texture only shows up in availableTextures once the scene reload
    // triggered by ImportTextureDialog actually completes (a few render frames later, not
    // synchronously with its imported() signal) - remember which label to select and apply
    // it once the list catches up.
    property string pendingTextureSelect: ""
    onAvailableTexturesChanged: {
        if (addPropertyPopup.pendingTextureSelect === "") return;
        const idx = addPropertyPopup.availableTextures.indexOf(addPropertyPopup.pendingTextureSelect);
        if (idx !== -1) {
            textureCombo.currentIndex = idx;
            addPropertyPopup.pendingTextureSelect = "";
        }
    }

    readonly property var kinds: [
        { label: qsTr("Parameter"), prefix: "param", propertyType: "float", defaultValue: 0.0 },
        { label: qsTr("Color"), prefix: "color", propertyType: "vec4", defaultValue: [1, 1, 1, 1] },
        { label: qsTr("Texture"), prefix: "texture", propertyType: "resourceRef" }
    ]

    function fullName(kindIndex, name) {
        return addPropertyPopup.kinds[kindIndex].prefix + ":" + name;
    }

    function nameTaken(kindIndex, name) {
        const candidate = addPropertyPopup.fullName(kindIndex, name);
        return addPropertyPopup.existingNames.indexOf(candidate) !== -1;
    }

    modal: true
    anchors.centerIn: Overlay.overlay
    width: 300

    onOpened: {
        kindCombo.currentIndex = 0
        nameInput.text = ""
        nameInput.forceActiveFocus()
        addPropertyPopup.pendingTextureSelect = ""
        popupImportTexture.errorText = ""
    }

    background: Rectangle {
        color: Theme.bgTertiary
        border.color: Theme.borderColor
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: qsTr("Add Property")
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Theme.white
        }

        ComboBox {
            id: kindCombo
            Layout.fillWidth: true
            model: addPropertyPopup.kinds.map(k => k.label)
        }

        TextField {
            id: nameInput
            Layout.fillWidth: true
            placeholderText: qsTr("name")
            selectByMouse: true
            color: Theme.white
        }

        // A texture property is only meaningful pointing at a real, already-loaded texture -
        // there's no safe placeholder to fall back to (unlike Parameter's 0.0 or Color's
        // white), so require picking one instead of silently defaulting to an empty/unknown
        // reference (that used to crash the renderer on an invalid handle - see
        // resource_manager::get() and material::apply() in noi_engine).
        ColumnLayout {
            Layout.fillWidth: true
            visible: addPropertyPopup.isTextureKind
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ComboBox {
                    id: textureCombo
                    Layout.fillWidth: true
                    visible: addPropertyPopup.availableTextures.length > 0
                    model: addPropertyPopup.availableTextures
                }

                AppButton {
                    text: qsTr("Import...")
                    enabled: !popupImportTexture.busy
                    onClicked: popupImportTexture.pick()
                }
            }

            Text {
                visible: addPropertyPopup.availableTextures.length === 0 && popupImportTexture.errorText === ""
                text: qsTr("No textures loaded yet - import an image to make one available.")
                color: Theme.grey
                font.pixelSize: 10
                font.italic: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                visible: popupImportTexture.errorText !== ""
                text: popupImportTexture.errorText
                color: Theme.error
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        ImportTextureDialog {
            id: popupImportTexture
            resourcesPath: addPropertyPopup.inspector.resourcesPath
            scenePath: addPropertyPopup.inspector.currentScenePath
            onReloadRequested: addPropertyPopup.inspector.sceneReloadRequested()
            onImported: (label) => {
                const idx = addPropertyPopup.availableTextures.indexOf(label);
                if (idx !== -1) {
                    textureCombo.currentIndex = idx;
                } else {
                    addPropertyPopup.pendingTextureSelect = label;
                }
            }
        }

        Text {
            readonly property bool empty: nameInput.text.trim() === ""
            readonly property bool taken: !empty && addPropertyPopup.nameTaken(kindCombo.currentIndex, nameInput.text.trim())
            visible: taken
            text: qsTr("A property with that name already exists.")
            color: Theme.error
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            AppButton {
                text: qsTr("Cancel")
                onClicked: addPropertyPopup.close()
            }

            AppButton {
                text: qsTr("Add")
                enabled: nameInput.text.trim() !== ""
                    && !addPropertyPopup.nameTaken(kindCombo.currentIndex, nameInput.text.trim())
                    && (!addPropertyPopup.isTextureKind || addPropertyPopup.availableTextures.length > 0)
                onClicked: {
                    const kind = addPropertyPopup.kinds[kindCombo.currentIndex]
                    const name = nameInput.text.trim()
                    const value = addPropertyPopup.isTextureKind ? textureCombo.currentText : kind.defaultValue
                    addPropertyPopup.inspector.propertyEdited(addPropertyPopup.componentType, addPropertyPopup.fullName(kindCombo.currentIndex, name),
                        kind.propertyType, value)
                    addPropertyPopup.close()
                }
            }
        }
    }
}
