import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Dialog {
    id: root

    title: qsTr("Template Marketplace")
    modal: true
    anchors.centerIn: parent
    width: 500
    height: 400
    standardButtons: Dialog.Close

    signal templateDownloaded()

    TemplateManager {
        id: remoteTemplateManager
    }

    onOpened: remoteTemplateManager.fetchTemplates()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: remoteTemplateManager.isPending
            visible: remoteTemplateManager.isPending
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !remoteTemplateManager.isPending
            model: remoteTemplateManager.templates
            clip: true
            spacing: 8

            delegate: Rectangle {
                required property var modelData

                width: ListView.view.width
                height: 64
                radius: 8
                color: Theme.bgSecondary
                border.color: Theme.borderColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name + " (v" + modelData.version + ")"
                            color: Theme.white
                            font.bold: true
                            font.pixelSize: 13
                        }

                        Text {
                            text: modelData.description
                            color: Theme.darkGrey
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    AppButton {
                        text: qsTr("Download")
                        icon: "download"

                        onClicked: {
                            console.log("Downloading template:", modelData.id);
                            root.templateDownloaded();
                            root.close();
                        }
                    }
                }
            }
        }
    }
}