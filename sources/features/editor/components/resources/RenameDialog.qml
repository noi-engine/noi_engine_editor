import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Dialog {
    id: root

    property string targetPath: ""
    property string targetName: ""
    signal confirmed(string newName)

    function openFor(path, name) {
        root.targetPath = path
        root.targetName = name || ""
        root.open()
    }

    title: qsTr("Rename")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 320

    onOpened: {
        nameInput.text = root.targetName
        nameInput.selectAll()
        nameInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: qsTr("Enter new name:")
            font.pixelSize: 12
            color: Theme.darkGrey
        }

        TextField {
            id: nameInput
            Layout.fillWidth: true
            font.pixelSize: 13
            color: Theme.white
            selectByMouse: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            AppButton {
                text: qsTr("Cancel")
                onClicked: root.reject()
            }

            AppButton {
                text: qsTr("OK")
                onClicked: {
                    if (nameInput.text.trim() !== "") {
                        root.confirmed(nameInput.text.trim())
                    }
                    root.accept()
                }
            }
        }
    }
}