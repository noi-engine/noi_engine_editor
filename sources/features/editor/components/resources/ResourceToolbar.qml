import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

RowLayout {
    id: root

    property string currentFolder: ""
    property string rootFolder: ""
    property string parentFolder: ""
    property real gridScale: 1.0

    signal navigateBack()
    signal importRequested()
    signal newFolderRequested()

    Layout.fillWidth: true
    Layout.preferredHeight: 36
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    spacing: 8

    AppButton {
        icon: "arrow_back"
        enabled: root.currentFolder !== root.rootFolder && root.parentFolder !== ""
        onClicked: root.navigateBack()
    }

    Text {
        Layout.fillWidth: true
        text: root.currentFolder
        font.pixelSize: 11
        color: Theme.grey
        elide: Text.ElideLeft
    }

    Slider {
        implicitWidth: 100
        from: 0.75
        to: 1.5
        value: root.gridScale
        onValueChanged: root.gridScale = value
    }

    AppButton {
        icon: "file_upload"
        text: qsTr("Import")
        onClicked: root.importRequested()
    }

    AppButton {
        icon: "create_new_folder"
        text: qsTr("New Folder")
        onClicked: root.newFolderRequested()
    }
}