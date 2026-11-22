import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Shown when "Build release" succeeds: where the game is and what to do with it.
AppDialog {
    id: root

    property string outputPath: ""
    readonly property bool packaged: outputPath.endsWith("/packages")

    function show(path) {
        outputPath = path;
        open();
    }

    title: qsTr("Your game is ready")
    subtitle: packaged ? qsTr("The game was packed into an archive you can share.")
                       : qsTr("The game was built, but not packed into an archive.")
    icon: "inventory_2"
    preferredWidth: 560

    Banner {
        Layout.fillWidth: true
        kind: "success"
        title: root.packaged ? qsTr("Archive created") : qsTr("Release folder created")
        text: root.outputPath
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.darkGrey
        font.pixelSize: 12
        text: root.packaged
              ? qsTr("To play: unpack the archive anywhere and run the game inside. To share it, send the archive: nothing else needs to be installed.")
              : qsTr("This project doesn't have the packaging setup yet. Create a new project from the latest template to get a ready-to-share archive.")
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Close")
            onClicked: root.close()
        },
        AppButton {
            primary: true
            icon: "folder_open"
            text: qsTr("Show in folder")
            onClicked: {
                Qt.openUrlExternally("file://" + root.outputPath);
                root.close();
            }
        }
    ]
}
