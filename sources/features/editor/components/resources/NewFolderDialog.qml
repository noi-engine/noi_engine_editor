import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Dialog {
    id: root

    property string targetPath: ""
    property string defaultFolderName: "NewFolder"
    signal confirmed(string folderName)

    function openFor(path, defaultName) {
        root.targetPath = path
        root.defaultFolderName = defaultName || "NewFolder"
        root.open()
    }

    title: qsTr("New Folder")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 320

    onOpened: {
        folderNameInput.text = root.defaultFolderName
        folderNameInput.selectAll()
        folderNameInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: qsTr("Folder name:")
            font.pixelSize: 12
            color: Theme.darkGrey
        }

        TextField {
            id: folderNameInput
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
                text: qsTr("Create")
                onClicked: {
                    if (folderNameInput.text.trim() !== "") {
                        root.confirmed(folderNameInput.text.trim())
                    }
                    root.accept()
                }
            }
        }
    }
}