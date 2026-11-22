import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

AppDialog {
    id: root

    property string targetPath: ""
    property string targetName: ""
    signal confirmed(string newName)

    function openFor(path, name) {
        root.targetPath = path
        root.targetName = name || ""
        root.open()
    }

    function confirm() {
        const name = nameInput.text.trim()
        if (name === "") {
            nameInput.error = qsTr("Type a name.")
            return
        }
        if (/[\\/]/.test(name)) {
            nameInput.error = qsTr("A name can't contain / or \\")
            return
        }
        if (name === root.targetName) {
            root.reject()
            return
        }
        root.confirmed(name)
        root.accept()
    }

    title: qsTr("Rename")
    subtitle: qsTr("Choose a new name for %1.").arg(root.targetName)
    icon: "edit"
    preferredWidth: 440

    onOpened: {
        nameInput.error = ""
        nameInput.text = root.targetName
        nameInput.field.forceActiveFocus()
        nameInput.field.selectAll()
    }

    AppTextField {
        id: nameInput
        Layout.fillWidth: true
        label: qsTr("New name")
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
            text: qsTr("Rename")
            icon: "edit"
            primary: true
            onClicked: root.confirm()
        }
    ]
}
