import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Dialog {
    id: root

    property string targetPath: ""
    signal confirmed(string sceneName)

    function openFor(path) {
        root.targetPath = path
        root.open()
    }

    title: qsTr("New Scene")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 320

    onOpened: {
        nameInput.text = "NewScene"
        nameInput.selectAll()
        nameInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: qsTr("Scene name:")
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
                text: qsTr("Create")
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
