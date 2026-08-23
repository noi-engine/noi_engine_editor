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

    property LocalTemplateManager localTemplateManager: null

    signal templateDownloaded()

    TemplateManager {
        id: remoteTemplateManager
    }

    Connections {
        target: root.localTemplateManager

        function onDownloadFinished(templateId, success) {
            if (success) {
                root.templateDownloaded()
            }
        }

        function onTemplatesChanged() {
            if (templateListView.model) {
                templateListView.model = remoteTemplateManager.templates
            }
        }
    }

    onOpened: remoteTemplateManager.fetchTemplates()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: remoteTemplateManager.isPending
            visible: remoteTemplateManager.isPending
        }

        ListView {
            id: templateListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !remoteTemplateManager.isPending
            model: remoteTemplateManager.templates
            clip: true
            spacing: 8

            delegate: Rectangle {
                required property var modelData

                readonly property bool installed: {
                    if (!root.localTemplateManager) return false
                    let dummy = root.localTemplateManager.templates
                    return root.localTemplateManager.isInstalled(modelData.id)
                }

                readonly property bool downloading: root.localTemplateManager ? root.localTemplateManager.isDownloading : false

                width: ListView.view ? ListView.view.width : 0
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
                        text: installed ? qsTr("Installed") : (downloading ? qsTr("Downloading...") : qsTr("Download"))
                        icon: installed ? "check" : (downloading ? "sync" : "download")
                        enabled: !installed && !downloading && root.localTemplateManager !== null

                        onClicked: {
                            if (!installed && root.localTemplateManager) {
                                root.localTemplateManager.downloadTemplate(modelData.id, modelData.repositoryUrl)
                            }
                        }
                    }
                }
            }
        }
    }
}