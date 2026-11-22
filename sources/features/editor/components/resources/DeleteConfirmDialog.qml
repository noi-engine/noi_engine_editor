import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

AppDialog {
    id: root

    property string targetPath: ""
    property string targetName: ""
    signal confirmed()

    function openFor(path, name) {
        root.targetPath = path
        root.targetName = name || ""
        root.open()
    }

    title: qsTr("Delete %1?").arg(root.targetName)
    subtitle: root.targetPath
    icon: "delete"
    preferredWidth: 460
    showClose: false

    Banner {
        Layout.fillWidth: true
        kind: "warning"
        title: qsTr("This can't be undone")
        text: qsTr("%1 is removed from your project folder for good (a folder is removed with everything inside it). Scenes that use it will show an error until you pick another file.").arg(root.targetName)
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Keep it")
            onClicked: root.reject()
        },
        AppButton {
            text: qsTr("Delete")
            icon: "delete"
            primary: true
            onClicked: {
                root.confirmed()
                root.accept()
            }
        }
    ]
}
