import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// "How to install" window, opened where a build can't run. The same list lives in Settings.
AppDialog {
    id: root

    title: qsTr("Tools needed to build your game")
    subtitle: qsTr("The editor runs these programs for you. Install the missing ones, then press “Check again”.")
    icon: "build_circle"
    preferredWidth: 640

    onAboutToShow: PrerequisitesManager.refresh()

    PrerequisitesList {
        Layout.fillWidth: true
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Close")
            onClicked: root.close()
        },
        AppButton {
            primary: true
            text: qsTr("Check again")
            icon: "refresh"
            onClicked: PrerequisitesManager.refresh()
        }
    ]
}
