import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import noi_engine_editor
import "../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

CustomPage {
    id: root

    title: qsTr("Create Project")

    property var selectedTemplate: null

    LocalTemplateManager {
        id: localTemplateManager
    }

    ProjectCreator {
        id: projectCreator

        onProjectCreated: (name, path) => {
            RecentProjectsManager.addProject(name, path);
            if (CurrentProjectManager.openProject(path)) {
                Router.push("/editor");
            }
        }

        onProjectCreationFailed: reason => {
            errorLabel.text = reason;
            errorLabel.visible = true;
        }
    }

    FolderDialog {
        id: folderDialog

        onAccepted: {
            locationField.text = UrlConverter.toLocalPath(selectedFolder);
        }
    }

    TemplateMarketplaceDialog {
        id: marketplaceDialog
        localTemplateManager: localTemplateManager

        onTemplateDownloaded: {
            localTemplateManager.loadLocalTemplates();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 560)
        spacing: 20

        ColumnLayout {
            spacing: 4

            Text {
                text: qsTr("Create a new project")
                font.pixelSize: 26
                font.weight: Font.Bold
                color: Theme.white
            }

            Text {
                text: qsTr("Choose a name, location and template for your project.")
                font.pixelSize: 13
                color: Theme.darkGrey
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Project name")
                font.pixelSize: 13
                color: Theme.darkGrey
            }

            TextField {
                id: nameField

                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: "NewProject"
                color: Theme.white
                font.pixelSize: 14

                background: Rectangle {
                    radius: 10
                    color: Theme.bgSecondary
                    border.color: Theme.borderColor
                    border.width: 1
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Location")
                font.pixelSize: 13
                color: Theme.darkGrey
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TextField {
                    id: locationField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    text: SettingsManager.defaultProjectsPath
                    color: Theme.white
                    font.pixelSize: 13

                    background: Rectangle {
                        radius: 10
                        color: Theme.bgSecondary
                        border.color: Theme.borderColor
                        border.width: 1
                    }
                }

                AppButton {
                    text: qsTr("Browse")
                    icon: "folder_open"
                    onClicked: folderDialog.open()
                }
            }

            CheckBox {
                id: defaultFolderCheckBox
                text: qsTr("Set as default projects folder")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: qsTr("Select Template *")
                    font.pixelSize: 13
                    color: Theme.darkGrey
                }

                Item {
                    Layout.fillWidth: true
                }

                AppButton {
                    text: qsTr("Marketplace")
                    icon: "shopping_cart"
                    onClicked: marketplaceDialog.open()
                }
            }

            ListView {
                id: templateListView

                Layout.fillWidth: true
                Layout.preferredHeight: 120
                model: localTemplateManager.templates
                clip: true
                spacing: 8

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedTemplate && root.selectedTemplate.id === modelData.id

                    width: templateListView.width
                    height: 52
                    radius: 8
                    color: isSelected ? Theme.bgSecondary : "transparent"
                    border.color: isSelected ? Theme.primaryColor : "transparent"
                    border.width: isSelected ? 2 : 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name
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
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selectedTemplate = modelData;
                            errorLabel.visible = false;
                        }
                    }
                }

                ItemDelegate {
                    visible: templateListView.count === 0
                    width: templateListView.width
                    height: 50
                    text: qsTr("No template installed. Open Marketplace to download one.")
                    enabled: false
                }
            }
        }

        Text {
            id: errorLabel

            visible: false
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Theme.error
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 12

            Item {
                Layout.fillWidth: true
            }

            AppButton {
                text: qsTr("Cancel")
                onClicked: Router.replace("/")
            }

            AppButton {
                text: qsTr("Create Project")
                primary: true

                onClicked: {
                    if (nameField.text.trim() === "") {
                        errorLabel.text = qsTr("Project name cannot be empty");
                        errorLabel.visible = true;
                        return;
                    }

                    if (!root.selectedTemplate) {
                        errorLabel.text = qsTr("Please select a template to continue");
                        errorLabel.visible = true;
                        return;
                    }

                    if (defaultFolderCheckBox.checked) {
                        SettingsManager.defaultProjectsPath = locationField.text;
                    }

                    projectCreator.createProject(nameField.text.trim(), locationField.text, root.selectedTemplate.id);
                }
            }
        }
    }
}
