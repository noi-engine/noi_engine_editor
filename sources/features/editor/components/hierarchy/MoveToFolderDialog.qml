import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Picks an existing folder or types a new one ("Level/Platforms" for a sub-folder).
Dialog {
    id: root

    property var folders: []
    property var targetEntity: null

    signal confirmed(var entity, string folder)

    function openFor(entity, currentFolder) {
        root.targetEntity = entity;
        folderCombo.editText = currentFolder || "";
        root.open();
    }

    title: qsTr("Move to Folder")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 340

    onOpened: folderCombo.forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: qsTr("Folder (use / for sub-folders):")
            font.pixelSize: 12
            color: Theme.darkGrey
        }

        ComboBox {
            id: folderCombo
            Layout.fillWidth: true
            editable: true
            model: root.folders
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
                text: qsTr("Move")
                primary: true
                enabled: folderCombo.editText.trim() !== ""
                onClicked: {
                    const folder = folderCombo.editText.trim().split("/").map(p => p.trim()).filter(p => p !== "").join("/");
                    root.confirmed(root.targetEntity, folder);
                    root.accept();
                }
            }
        }
    }
}
