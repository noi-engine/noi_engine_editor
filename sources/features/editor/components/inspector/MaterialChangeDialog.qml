import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Changing the material of a Mesh Renderer that has Material Overrides: those values were set
// for the previous material and usually mean nothing (or the wrong thing) for the new one.
// Explains it and lets the user remove them, keep them, or cancel.
Dialog {
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

    title: qsTr("Change material")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 420

    onRejected: if (root.onCancel) root.onCancel()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            color: Theme.white
            text: qsTr("This entity has Material Overrides set for %1: %2.")
                .arg(root.fromMaterial).arg(root.overrides.map(n => n.substring(n.indexOf(":") + 1)).join(", "))
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 11
            color: Theme.grey
            text: qsTr("%1 may not use them: they would stay in the scene without any effect, or change something you don't expect. Removing them is usually what you want.").arg(root.toMaterial)
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
                text: qsTr("Keep them")
                onClicked: {
                    root.keepAndChange();
                    root.accept();
                }
            }

            AppButton {
                text: qsTr("Remove them")
                primary: true
                onClicked: {
                    root.removeAndChange();
                    root.accept();
                }
            }
        }
    }
}
