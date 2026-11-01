import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Leaving a scene with unsaved changes (opening another one, going back home): save them,
// drop them, or stay.
Dialog {
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

    title: qsTr("Unsaved changes")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 420

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            color: Theme.white
            text: qsTr("%1 has unsaved changes. Save them before %2?").arg(root.sceneName).arg(root.actionText)
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
                text: qsTr("Don't save")
                onClicked: {
                    root.discardRequested();
                    root.accept();
                }
            }

            AppButton {
                text: qsTr("Save")
                primary: true
                onClicked: {
                    root.saveRequested();
                    root.accept();
                }
            }
        }
    }
}
