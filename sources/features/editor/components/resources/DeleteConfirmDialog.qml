import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Dialog {
    id: root

    property string targetPath: ""
    property string targetName: ""
    signal confirmed()

    function openFor(path, name) {
        root.targetPath = path
        root.targetName = name || ""
        root.open()
    }

    title: qsTr("Delete Resource")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 340

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: qsTr("Are you sure you want to delete '%1'?").arg(root.targetName)
            font.pixelSize: 12
            color: Theme.white
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            AppButton {
                text: qsTr("No")
                onClicked: root.reject()
            }

            AppButton {
                text: qsTr("Yes")
                onClicked: {
                    root.confirmed()
                    root.accept()
                }
            }
        }
    }
}