import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// One required tool in the "create project" dialog: name + version, and either "Ready" or a
// Download button.
RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property bool ready: false
    property bool installing: false

    signal downloadRequested()

    Layout.fillWidth: true
    spacing: 8

    MuiIcon {
        name: root.icon
        font.pixelSize: 15
        color: Theme.darkGrey
    }

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.white
        font.pixelSize: 12
    }

    Text {
        visible: root.ready
        text: qsTr("Ready")
        color: Theme.success
        font.pixelSize: 12
        font.bold: true
    }

    BusyIndicator {
        visible: root.installing
        running: root.installing
        implicitWidth: 20
        implicitHeight: 20
    }

    AppButton {
        visible: !root.ready
        text: root.installing ? qsTr("Downloading...") : qsTr("Download")
        icon: "download"
        enabled: !root.installing
        onClicked: root.downloadRequested()
    }
}
