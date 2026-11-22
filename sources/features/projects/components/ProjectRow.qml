import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// One project of the list, laid out like the project manager of other engines: icon, name and
// path on the left, when it was last opened on the right. The icon is the project's own
// icon.png when it has one.
Item {
    id: root

    required property string projectName
    required property string projectPath
    required property string projectDate

    signal clicked()
    signal removeRequested()

    implicitHeight: 68

    readonly property bool hasIcon: CurrentProjectResourcesManager.fileExists(projectPath + "/icon.png")
    readonly property bool hovered: area.containsMouse || removeArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.hovered ? Theme.bgTertiary : Theme.bgSecondary
        border.width: 1
        border.color: root.hovered ? Theme.borderStrong : Theme.borderColor
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 14

        // Project icon: icon.png / icon.svg of the project folder, else a plain placeholder.
        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: 8
            color: Theme.bgPrimary
            border.color: Theme.borderColor
            clip: true

            Image {
                id: projectIcon
                anchors.fill: parent
                anchors.margins: 2
                source: root.hasIcon ? "file://" + root.projectPath + "/icon.png" : ""
                sourceSize.width: 96
                sourceSize.height: 96
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            MuiIcon {
                anchors.centerIn: parent
                visible: projectIcon.status !== Image.Ready
                name: "sports_esports"
                font.pixelSize: 24
                color: Theme.grey
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.projectName
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.white
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.projectPath
                font.pixelSize: 12
                color: Theme.grey
                elide: Text.ElideMiddle
            }
        }

        ColumnLayout {
            spacing: 0
            visible: parent.width > 520

            Text {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Last opened")
                font.pixelSize: 10
                color: Theme.lightGrey
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.projectDate !== "" ? root.projectDate : qsTr("never")
                font.pixelSize: 12
                color: Theme.darkGrey
            }
        }

        MuiIcon {
            visible: root.hovered
            name: "close"
            font.pixelSize: 18
            color: removeArea.containsMouse ? Theme.error : Theme.grey

            MouseArea {
                id: removeArea
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeRequested()
            }

            ToolTip { visible: removeArea.containsMouse; delay: 400; text: qsTr("Remove from this list (keeps the files)") }
        }

        MuiIcon {
            visible: !root.hovered
            name: "chevron_right"
            font.pixelSize: 20
            color: Theme.lightGrey
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: root.clicked()
    }
}
