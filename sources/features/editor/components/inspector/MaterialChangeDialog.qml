import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Changing the material of a Mesh Renderer that has Material Overrides: those values were set
// for the previous material and usually mean nothing (or the wrong thing) for the new one.
// Explains it and lets the user remove them, keep them, or cancel.
AppDialog {
    id: root

    property string fromMaterial: ""
    property string toMaterial: ""
    property var overrides: [] // full names, e.g. "texture:u_texture"
    property var onCancel: null

    signal removeAndChange()
    signal keepAndChange()

    function ask(from, to, names, cancel) {
        root.fromMaterial = from;
        root.toMaterial = to;
        root.overrides = names;
        root.onCancel = cancel;
        root.open();
    }

    title: qsTr("Change the material?")
    subtitle: qsTr("A material decides how an object is drawn (plain color, picture...).")
    icon: "palette"
    preferredWidth: 480
    showClose: false

    onRejected: if (root.onCancel) root.onCancel()

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.pixelSize: 13
        color: Theme.white
        text: qsTr("This object has custom values set for %1: %2.")
            .arg(root.fromMaterial).arg(root.overrides.map(n => n.substring(n.indexOf(":") + 1)).join(", "))
    }

    Banner {
        Layout.fillWidth: true
        kind: "warning"
        text: qsTr("%1 may not use them: they would stay in the scene without any effect, or change something you don't expect. Removing them is usually what you want.").arg(root.toMaterial)
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Keep them")
            onClicked: {
                root.keepAndChange();
                root.accept();
            }
        },
        AppButton {
            text: qsTr("Remove them")
            primary: true
            onClicked: {
                root.removeAndChange();
                root.accept();
            }
        }
    ]
}
