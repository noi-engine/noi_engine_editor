import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Picks an existing folder or types a new one ("Level/Platforms" for a sub-folder).
AppDialog {
    id: root

    property var folders: []
    property var targetEntity: null

    signal confirmed(var entity, string folder)

    function openFor(entity, currentFolder) {
        root.targetEntity = entity;
        folderCombo.editText = currentFolder || "";
        root.open();
    }

    function confirm() {
        const folder = folderCombo.editText.trim().split("/").map(p => p.trim()).filter(p => p !== "").join("/");
        if (folder === "") return;
        root.confirmed(root.targetEntity, folder);
        root.accept();
    }

    title: qsTr("Move to a folder")
    subtitle: root.targetEntity && root.targetEntity.name
        ? qsTr("Folders only organize the Hierarchy list: %1 behaves the same in the game.").arg(root.targetEntity.name)
        : qsTr("Folders only organize the Hierarchy list: they don't change how the game behaves.")
    icon: "drive_file_move"
    preferredWidth: 440

    onOpened: folderCombo.forceActiveFocus()

    Text {
        Layout.fillWidth: true
        text: qsTr("Folder")
        font.pixelSize: 12
        font.weight: Font.Medium
        color: Theme.darkGrey
    }

    ComboBox {
        id: folderCombo
        Layout.fillWidth: true
        editable: true
        model: root.folders
        onAccepted: root.confirm()
    }

    Text {
        Layout.fillWidth: true
        text: root.folders.length > 0
            ? qsTr("Pick an existing folder, or type a new name. Use / for a sub-folder (for example Level/Platforms).")
            : qsTr("Type a name to create a folder. Use / for a sub-folder (for example Level/Platforms).")
        font.pixelSize: 11
        color: Theme.grey
        wrapMode: Text.WordWrap
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Move")
            icon: "drive_file_move"
            primary: true
            enabled: folderCombo.editText.trim() !== ""
            onClicked: root.confirm()
        }
    ]
}
