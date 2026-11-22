import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

AppDialog {
    id: root

    property string targetPath: ""
    property string defaultFolderName: "NewFolder"
    signal confirmed(string folderName)

    function openFor(path, defaultName) {
        root.targetPath = path
        root.defaultFolderName = defaultName || "NewFolder"
        root.open()
    }

    function confirm() {
        const name = nameInput.text.trim()
        if (name === "") {
            nameInput.error = qsTr("Type a name for the folder.")
            return
        }
        if (/[\\/:*?"<>|]/.test(name) || name === "." || name === "..") {
            nameInput.error = qsTr("A folder name can't contain / \\ : * ? \" < > |")
            return
        }
        root.confirmed(name)
        root.accept()
    }

    title: qsTr("New folder")
    subtitle: qsTr("Folders keep the images and files of your game organized.")
    icon: "create_new_folder"
    preferredWidth: 440

    onOpened: {
        nameInput.error = ""
        nameInput.text = root.defaultFolderName
        nameInput.field.forceActiveFocus()
        nameInput.field.selectAll()
    }

    AppTextField {
        id: nameInput
        Layout.fillWidth: true
        label: qsTr("Folder name")
        hint: root.targetPath !== "" ? qsTr("Created in %1").arg(root.targetPath) : ""
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
            text: qsTr("Create folder")
            icon: "create_new_folder"
            primary: true
            onClicked: root.confirm()
        }
    ]
}
