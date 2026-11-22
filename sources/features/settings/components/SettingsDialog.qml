import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

AppDialog {
    id: root

    title: qsTr("Settings")
    subtitle: qsTr("The tools Noi Engine downloads to run and build your games.")
    icon: "settings"
    preferredWidth: 640

    ToolsSettingsTab {
        Layout.fillWidth: true
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Close")
            primary: true
            onClicked: root.close()
        }
    ]
}
