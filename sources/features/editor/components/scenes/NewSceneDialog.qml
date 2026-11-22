import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

AppDialog {
    id: root

    property string targetPath: ""
    signal confirmed(string sceneName)

    function openFor(path) {
        root.targetPath = path
        root.open()
    }

    function confirm() {
        const name = nameInput.text.trim().replace(/\.scene$/, "")
        if (name === "") {
            nameInput.error = qsTr("Give your scene a name.")
            return
        }
        if (/[\\/:*?"<>|]/.test(name) || name === "." || name === "..") {
            nameInput.error = qsTr("A scene name can't contain / \\ : * ? \" < > |")
            return
        }
        root.confirmed(name)
        root.accept()
    }

    title: qsTr("New scene")
    subtitle: qsTr("A scene is one screen of your game (a level, a menu...). It starts with a camera: add objects to fill it.")
    icon: "landscape"
    preferredWidth: 480

    onOpened: {
        nameInput.error = ""
        nameInput.text = "NewScene"
        nameInput.field.forceActiveFocus()
        nameInput.field.selectAll()
    }

    AppTextField {
        id: nameInput
        Layout.fillWidth: true
        label: qsTr("Scene name")
        hint: root.targetPath !== ""
            ? qsTr("Saved as %1/%2.scene").arg(root.targetPath).arg(text.trim() === "" ? qsTr("name") : text.trim())
            : ""
        onEdited: error = ""
        onAccepted: root.confirm()
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Create scene")
            icon: "add"
            primary: true
            onClicked: root.confirm()
        }
    ]
}
