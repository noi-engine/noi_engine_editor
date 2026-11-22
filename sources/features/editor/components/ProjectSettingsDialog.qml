import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

AppDialog {
    id: root

    title: qsTr("Project settings")
    subtitle: qsTr("The name of your game and the size of its window.")
    icon: "tune"
    preferredWidth: 520

    // The game window size is also the start scene camera's size (its red border).
    signal resolutionChanged(int width, int height)

    property string errorText: ""

    onAboutToShow: {
        errorText = "";
        nameInput.text = CurrentProjectManager.name;
        sceneInput.text = CurrentProjectManager.startScene;
        widthInput.text = CurrentProjectManager.windowWidth.toString();
        heightInput.text = CurrentProjectManager.windowHeight.toString();
        nameInput.error = "";
    }

    function save() {
        errorText = "";
        if (nameInput.text.trim() === "") {
            nameInput.error = qsTr("Give your game a name.");
            return;
        }
        nameInput.error = "";

        const width = parseInt(widthInput.text) || 1280
        const height = parseInt(heightInput.text) || 720
        const resolutionEdited = width !== CurrentProjectManager.windowWidth || height !== CurrentProjectManager.windowHeight

        CurrentProjectManager.name = nameInput.text.trim()
        CurrentProjectManager.startScene = sceneInput.text.trim()
        CurrentProjectManager.windowWidth = width
        CurrentProjectManager.windowHeight = height

        if (!CurrentProjectManager.saveProject()) {
            errorText = qsTr("The settings couldn't be written to noi_engine.proj.json. Check that the project folder is writable, then try again.");
            return;
        }
        if (resolutionEdited) root.resolutionChanged(width, height)
        Notifier.success(qsTr("Project settings saved"));
        root.accept();
    }

    AppTextField {
        id: nameInput
        Layout.fillWidth: true
        label: qsTr("Game name")
        hint: qsTr("Shown in the game window's title bar.")
        onEdited: error = ""
        onAccepted: root.save()
    }

    AppTextField {
        Layout.fillWidth: true
        label: qsTr("Project folder")
        text: CurrentProjectManager.path
        readOnly: true
    }

    AppTextField {
        id: sceneInput
        Layout.fillWidth: true
        label: qsTr("Start scene")
        hint: qsTr("The scene the game opens first, relative to the resources folder (for example scenes/main.scene).")
    }

    Text {
        Layout.fillWidth: true
        text: qsTr("Game window size, in pixels. It is also the start scene's camera (the red border in the viewport): resizing one resizes the other.")
        font.pixelSize: 12
        color: Theme.darkGrey
        wrapMode: Text.WordWrap
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing

        AppTextField {
            id: widthInput
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: qsTr("Width")
            field.validator: IntValidator { bottom: 100; top: 7680 }
            hint: qsTr("100 to 7680")
        }

        AppTextField {
            id: heightInput
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: qsTr("Height")
            field.validator: IntValidator { bottom: 100; top: 4320 }
            hint: qsTr("100 to 4320")
        }
    }

    Banner {
        Layout.fillWidth: true
        kind: "error"
        visible: root.errorText !== ""
        text: root.errorText
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Save")
            icon: "save"
            primary: true
            onClicked: root.save()
        }
    ]
}
