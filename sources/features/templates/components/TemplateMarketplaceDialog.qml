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
                errorLabel.visible = false;
                root.templateDownloaded()
            } else {
                errorLabel.text = qsTr("Failed to download the template. Check your connection and try again.")
                errorLabel.visible = true;
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

        Text {
            id: errorLabel

            Layout.fillWidth: true
            visible: false
            wrapMode: Text.WordWrap
            color: Theme.error
            font.pixelSize: 12
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

                readonly property bool downloading: root.localTemplateManager
                    ? (root.localTemplateManager.isDownloading && root.localTemplateManager.downloadingTemplateId === modelData.id)
                    : false

                readonly property bool otherDownloading: root.localTemplateManager
                    ? (root.localTemplateManager.isDownloading && root.localTemplateManager.downloadingTemplateId !== modelData.id)
                    : false

                width: ListView.view ? ListView.view.width : 0
                height: 64
                radius: 8
                color: Theme.bgSecondary
                border.color: Theme.borderColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
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

                        Item { Layout.fillWidth: true }

                        BusyIndicator {
                            visible: downloading
                            running: downloading
                            implicitWidth: 20
                            implicitHeight: 20
                        }

                        AppButton {
                            text: installed
                                ? qsTr("Installed")
                                : (downloading ? qsTr("Downloading...") : qsTr("Download"))
                            icon: installed ? "check" : (downloading ? "sync" : "download")
                            enabled: !installed && !downloading && !otherDownloading && root.localTemplateManager !== null

                            onClicked: {
                                if (!installed && root.localTemplateManager) {
                                    errorLabel.visible = false;
                                    root.localTemplateManager.downloadTemplate(modelData.id, modelData.repositoryUrl)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
