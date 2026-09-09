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

        onFetchFailed: error => {
            errorLabel.text = qsTr("Failed to load templates: %1").arg(error)
            errorLabel.visible = true
        }
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
    }

    onOpened: {
        errorLabel.visible = false
        remoteTemplateManager.fetchTemplates()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: remoteTemplateManager.isPending
            visible: remoteTemplateManager.isPending
        }

        RowLayout {
            Layout.fillWidth: true
            visible: errorLabel.visible
            spacing: 10

            Text {
                id: errorLabel

                Layout.fillWidth: true
                visible: false
                wrapMode: Text.WordWrap
                color: Theme.error
                font.pixelSize: 12
            }

            AppButton {
                text: qsTr("Retry")
                icon: "refresh"
                onClicked: {
                    errorLabel.visible = false
                    remoteTemplateManager.fetchTemplates()
                }
            }
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
                id: delegateRoot
                required property var modelData

                property bool showOldVersions: false
                property var installedVersionsList: root.localTemplateManager
                    ? root.localTemplateManager.installedVersions(modelData.id)
                    : []

                readonly property string latestInstalledVersion: installedVersionsList.length > 0
                    ? installedVersionsList[0]
                    : ""

                readonly property bool installed: latestInstalledVersion === modelData.version
                readonly property bool hasOlderVersion: installedVersionsList.length > 0 && !installed

                readonly property bool downloading: root.localTemplateManager
                    ? (root.localTemplateManager.isDownloading && root.localTemplateManager.downloadingTemplateId === modelData.id)
                    : false

                readonly property bool otherDownloading: root.localTemplateManager
                    ? (root.localTemplateManager.isDownloading && root.localTemplateManager.downloadingTemplateId !== modelData.id)
                    : false

                function refreshInstalledVersions() {
                    installedVersionsList = root.localTemplateManager
                        ? root.localTemplateManager.installedVersions(modelData.id)
                        : []
                }

                Connections {
                    target: root.localTemplateManager
                    function onTemplatesChanged() {
                        delegateRoot.refreshInstalledVersions()
                    }
                }

                width: ListView.view ? ListView.view.width : 0
                height: mainColumn.implicitHeight + 20
                radius: 8
                color: Theme.bgSecondary
                border.color: Theme.borderColor

                ColumnLayout {
                    id: mainColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
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
                                Layout.fillWidth: true
                                text: modelData.description
                                color: Theme.darkGrey
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        BusyIndicator {
                            visible: downloading
                            running: downloading
                            implicitWidth: 20
                            implicitHeight: 20
                        }

                        AppButton {
                            visible: delegateRoot.installedVersionsList.length > 0
                            text: delegateRoot.showOldVersions ? qsTr("Hide versions") : qsTr("Old versions")
                            icon: "history"
                            onClicked: delegateRoot.showOldVersions = !delegateRoot.showOldVersions
                        }

                        AppButton {
                            text: delegateRoot.installed
                                ? qsTr("Installed")
                                : (downloading
                                    ? qsTr("Downloading...")
                                    : (delegateRoot.hasOlderVersion ? qsTr("Update") : qsTr("Download")))
                            icon: delegateRoot.installed ? "check" : (downloading ? "sync" : "download")
                            enabled: !delegateRoot.installed && !downloading && !otherDownloading && root.localTemplateManager !== null

                            onClicked: {
                                if (!delegateRoot.installed && root.localTemplateManager) {
                                    errorLabel.visible = false;
                                    root.localTemplateManager.downloadTemplate(modelData.id, modelData.version, modelData.repositoryUrl)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: delegateRoot.showOldVersions
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.borderColor
                            opacity: 0.5
                        }

                        Repeater {
                            model: delegateRoot.installedVersionsList

                            delegate: RowLayout {
                                required property string modelData

                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("v%1").arg(modelData)
                                    color: Theme.white
                                    font.pixelSize: 12
                                }

                                AppButton {
                                    text: qsTr("Remove")
                                    icon: "delete"
                                    onClicked: {
                                        root.localTemplateManager.removeTemplateVersion(delegateRoot.modelData.id, modelData)
                                        delegateRoot.refreshInstalledVersions()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
