import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Pick a picture of the project (all of them, not only the ones the open scene already uses):
// thumbnails with a search field. Using one in a scene registers it there automatically.
AppDialog {
    id: root

    property string resourcesPath: ""
    property string currentPath: ""

    signal imagePicked(string filePath)
    signal importRequested()

    title: qsTr("Choose an image")
    subtitle: qsTr("Every picture of your project. Pick one, or import a new one from your computer.")
    icon: "image"
    preferredWidth: 640

    property var files: []
    property string query: ""
    readonly property var shown: files.filter(f => query.trim() === "" || f.toLowerCase().indexOf(query.trim().toLowerCase()) >= 0)

    onAboutToShow: {
        files = CurrentProjectResourcesManager.imageFiles(resourcesPath);
        query = "";
        search.text = "";
    }
    onOpened: search.field.forceActiveFocus()

    AppTextField {
        id: search
        Layout.fillWidth: true
        placeholderText: qsTr("Search images…")
        onEdited: root.query = text
    }

    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(2, Math.floor((root.width - 80) / 120))
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: root.shown

            delegate: Rectangle {
                id: cell
                required property string modelData
                readonly property bool current: modelData === root.currentPath

                Layout.preferredWidth: 110
                Layout.preferredHeight: 128
                radius: Theme.radius
                color: area.containsMouse ? Theme.bgElevated : Theme.bgTertiary
                border.color: current ? Theme.primaryColor : Theme.borderColor
                border.width: current ? 2 : 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: Theme.bgPrimary
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: "file://" + cell.modelData
                            sourceSize.width: 160
                            sourceSize.height: 160
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: cell.modelData.substring(cell.modelData.lastIndexOf("/") + 1)
                        font.pixelSize: 11
                        color: Theme.white
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.imagePicked(cell.modelData); root.close(); }
                }
            }
        }
    }

    Text {
        visible: root.shown.length === 0
        Layout.fillWidth: true
        text: root.files.length === 0 ? qsTr("The project has no image yet. Import one from your computer.")
                                       : qsTr("No image matches “%1”.").arg(root.query)
        color: Theme.grey
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }

    footerContent: [
        AppButton {
            icon: "upload"
            text: qsTr("Import from my computer…")
            onClicked: { root.close(); root.importRequested(); }
        },
        Item { Layout.fillWidth: true },
        AppButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        }
    ]
}
