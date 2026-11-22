import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// What this computer needs to build and ship a game, with the command that installs each missing
// piece. Opened from the home page, the new-project window and the editor when a build can't run.
AppDialog {
    id: root

    title: qsTr("Tools needed to build your game")
    subtitle: qsTr("The editor runs these programs for you. Install the missing ones, then press “Check again”.")
    icon: "build_circle"
    preferredWidth: 640

    onAboutToShow: PrerequisitesManager.refresh()

    Banner {
        Layout.fillWidth: true
        kind: PrerequisitesManager.canRelease ? "success" : PrerequisitesManager.canBuild ? "warning" : "error"
        title: PrerequisitesManager.canRelease ? qsTr("Everything is installed")
            : PrerequisitesManager.canBuild ? qsTr("You can compile and play, but not build a release yet")
            : qsTr("You can't compile yet")
        text: PrerequisitesManager.canRelease ? qsTr("You can compile, play and build a release.")
            : qsTr("Missing: %1").arg(PrerequisitesManager.missingSummary)
    }

    Repeater {
        model: PrerequisitesManager.items

        delegate: Rectangle {
            id: row
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: rowLayout.implicitHeight + 24
            radius: Theme.radius
            color: Theme.bgSecondary
            border.color: modelData.found ? Theme.borderColor : Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.5)

            ColumnLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MuiIcon {
                        name: row.modelData.found ? "check_circle" : "cancel"
                        font.pixelSize: 20
                        color: row.modelData.found ? Theme.success : Theme.warning
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: row.modelData.label
                            color: Theme.white
                            font.bold: true
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.found ? row.modelData.path : row.modelData.purpose
                            color: Theme.darkGrey
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                        }
                    }

                    Text {
                        text: row.modelData.required === "build" ? qsTr("Needed to play") : qsTr("Needed for releases")
                        color: Theme.grey
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: !row.modelData.found
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: commandText.implicitHeight + 14
                        radius: 6
                        color: Theme.black

                        Text {
                            id: commandText
                            anchors.fill: parent
                            anchors.margins: 7
                            text: row.modelData.hint
                            color: Theme.primaryLightA
                            font.family: "monospace"
                            font.pixelSize: 11
                            wrapMode: Text.WrapAnywhere
                        }
                    }

                    AppButton {
                        text: qsTr("Copy")
                        icon: "content_copy"
                        onClicked: {
                            clipboardHelper.text = row.modelData.hint;
                            clipboardHelper.selectAll();
                            clipboardHelper.copy();
                            Notifier.info(qsTr("Command copied"));
                        }
                    }
                }
            }
        }
    }

    TextEdit { id: clipboardHelper; visible: false }

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
