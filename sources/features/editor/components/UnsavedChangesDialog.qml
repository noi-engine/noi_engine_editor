import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Leaving a scene with unsaved changes (opening another one, going back home): save them,
// drop them, or stay.
AppDialog {
    id: root

    property string sceneName: ""
    property string actionText: ""

    signal saveRequested()
    signal discardRequested()

    function ask(sceneName, actionText) {
        root.sceneName = sceneName;
        root.actionText = actionText;
        root.open();
    }

    title: qsTr("Save your changes?")
    subtitle: qsTr("%1 has changes that are not saved yet.").arg(root.sceneName)
    icon: "save"
    preferredWidth: 460
    showClose: false

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.pixelSize: 13
        color: Theme.white
        text: qsTr("Before %1, do you want to save %2? If you don't save, the changes you made since the last save are lost.")
            .arg(root.actionText).arg(root.sceneName)
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Don't save")
            onClicked: {
                root.discardRequested();
                root.accept();
            }
        },
        AppButton {
            text: qsTr("Save")
            icon: "save"
            primary: true
            onClicked: {
                root.saveRequested();
                root.accept();
            }
        }
    ]
}
