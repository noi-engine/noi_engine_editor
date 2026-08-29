import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Dialog {
    id: root

    title: qsTr("Tools Manager")
    modal: true
    anchors.centerIn: parent
    width: 560
    height: 560
    standardButtons: Dialog.Close

    onOpened: ToolsManager.fetchLatestVersions()

    Connections {
        target: ToolsManager

        function onInstallFinished() {
            noiEngineListView.model = ToolsManager.installedNoiEngineVersions()
            resourceCompilerListView.model = ToolsManager.installedResourceCompilerVersions()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: ToolsManager.isFetchingVersions
            visible: ToolsManager.isFetchingVersions
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: !ToolsManager.isFetchingVersions

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Noi Engine")
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    text: ToolsManager.latestNoiEngineVersion ? qsTr("Latest v%1").arg(ToolsManager.latestNoiEngineVersion) : qsTr("Unavailable")
                    color: Theme.darkGrey
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                AppButton {
                    readonly property bool upToDate: ToolsManager.latestNoiEngineVersion.length > 0 && ToolsManager.isNoiEngineInstalled(ToolsManager.latestNoiEngineVersion)

                    text: upToDate ? qsTr("Up to date") : (ToolsManager.isInstalling ? qsTr("Installing...") : qsTr("Download latest"))
                    icon: upToDate ? "check" : "download"
                    enabled: ToolsManager.latestNoiEngineVersion.length > 0 && !ToolsManager.isInstalling && !upToDate

                    onClicked: ToolsManager.installNoiEngine(ToolsManager.latestNoiEngineVersion)
                }
            }

            ListView {
                id: noiEngineListView

                Layout.fillWidth: true
                Layout.preferredHeight: 110
                model: ToolsManager.installedNoiEngineVersions()
                clip: true
                spacing: 6

                delegate: Rectangle {
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    height: 40
                    radius: 8
                    color: Theme.bgSecondary
                    border.color: Theme.borderColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
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
                                ToolsManager.removeNoiEngineVersion(modelData)
                                noiEngineListView.model = ToolsManager.installedNoiEngineVersions()
                            }
                        }
                    }
                }

                ItemDelegate {
                    visible: noiEngineListView.count === 0
                    width: noiEngineListView.width
                    height: 40
                    text: qsTr("No version installed")
                    enabled: false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: Theme.borderColor
                opacity: 0.5
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Resource Compiler")
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 15
                }

                Text {
                    text: ToolsManager.latestResourceCompilerVersion ? qsTr("Latest v%1").arg(ToolsManager.latestResourceCompilerVersion) : qsTr("Unavailable")
                    color: Theme.darkGrey
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                AppButton {
                    readonly property bool upToDate: ToolsManager.latestResourceCompilerVersion.length > 0 && ToolsManager.isResourceCompilerInstalled(ToolsManager.latestResourceCompilerVersion)

                    text: upToDate ? qsTr("Up to date") : (ToolsManager.isInstalling ? qsTr("Installing...") : qsTr("Download latest"))
                    icon: upToDate ? "check" : "download"
                    enabled: ToolsManager.latestResourceCompilerVersion.length > 0 && !ToolsManager.isInstalling && !upToDate

                    onClicked: ToolsManager.installResourceCompiler(ToolsManager.latestResourceCompilerVersion)
                }
            }

            ListView {
                id: resourceCompilerListView

                Layout.fillWidth: true
                Layout.preferredHeight: 110
                model: ToolsManager.installedResourceCompilerVersions()
                clip: true
                spacing: 6

                delegate: Rectangle {
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    height: 40
                    radius: 8
                    color: Theme.bgSecondary
                    border.color: Theme.borderColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
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
                                ToolsManager.removeResourceCompilerVersion(modelData)
                                resourceCompilerListView.model = ToolsManager.installedResourceCompilerVersions()
                            }
                        }
                    }
                }

                ItemDelegate {
                    visible: resourceCompilerListView.count === 0
                    width: resourceCompilerListView.width
                    height: 40
                    text: qsTr("No version installed")
                    enabled: false
                }
            }
        }
    }
}
