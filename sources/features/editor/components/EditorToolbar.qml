import QtQuick
import QtQuick.Layouts
import noi_engine_editor

Rectangle {
    id: root

    signal settingsRequested()
    signal backRequested()

    property string currentScenePath: ""

    readonly property string currentSceneName: {
        if (!currentScenePath) return qsTr("(No scene opened)")
        let parts = currentScenePath.split("/")
        return parts[parts.length - 1]
    }

    color: Theme.bgSecondary

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.borderColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 16

        MuiIcon {
            name: "arrow_back"
            font.pixelSize: 20
            color: Theme.grey

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.backRequested()
            }
        }

        ColumnLayout {
            spacing: 1

            Text {
                text: CurrentProjectManager.name
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.white
            }

            Text {
                text: CurrentProjectManager.path
                font.pixelSize: 10
                color: Theme.grey
                elide: Text.ElideMiddle
                Layout.maximumWidth: 220
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 26
            color: Theme.borderColor
        }

        RowLayout {
            spacing: 8

            MuiIcon {
                name: "landscape"
                font.pixelSize: 16
                color: root.currentScenePath !== "" ? Theme.primaryColor : Theme.grey
            }

            Text {
                text: root.currentSceneName
                font.pixelSize: 13
                font.bold: root.currentScenePath !== ""
                color: root.currentScenePath !== "" ? Theme.white : Theme.darkGrey
            }
        }

        Item { Layout.fillWidth: true }

        AppButton {
            icon: "build"
            text: ProjectBuilder.isCompiling ? qsTr("Compiling...") : qsTr("Compile")
            enabled: !ProjectBuilder.isCompiling
            onClicked: ProjectBuilder.compile(CurrentProjectManager.path)
        }

        AppButton {
            icon: "play_arrow"
            text: qsTr("Play")
            enabled: false
        }

        AppButton {
            icon: "settings"
            text: qsTr("Settings")
            onClicked: root.settingsRequested()
        }
    }
}