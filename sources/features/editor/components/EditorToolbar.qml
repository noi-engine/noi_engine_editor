import QtQuick
import QtQuick.Layouts
import noi_engine_editor

Rectangle {
    id: root

    signal settingsRequested()
    signal backRequested()
    signal playRequested()
    signal stopRequested()
    signal saveRequested()

    property string currentScenePath: ""
    property bool isPlaying: false
    property bool sceneDirty: false

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
                text: root.currentSceneName + (root.sceneDirty ? " •" : "")
                font.pixelSize: 13
                font.bold: root.currentScenePath !== ""
                color: root.currentScenePath !== "" ? Theme.white : Theme.darkGrey
            }
        }

        Item { Layout.fillWidth: true }

        AppButton {
            icon: "save"
            text: qsTr("Save")
            enabled: root.currentScenePath !== "" && !root.isPlaying
            onClicked: root.saveRequested()
        }

        AppButton {
            icon: "build"
            text: ProjectBuilder.isCompiling ? qsTr("Compiling...") : qsTr("Compile")
            enabled: !ProjectBuilder.isCompiling && !root.isPlaying
            onClicked: ProjectBuilder.compile(CurrentProjectManager.path)
        }

        AppButton {
            icon: root.isPlaying ? "stop" : "play_arrow"
            text: root.isPlaying ? qsTr("Stop") : qsTr("Play")
            enabled: root.currentScenePath !== "" && !ProjectBuilder.isCompiling
            onClicked: root.isPlaying ? root.stopRequested() : root.playRequested()
        }

        AppButton {
            icon: "settings"
            text: qsTr("Settings")
            enabled: !root.isPlaying
            onClicked: root.settingsRequested()
        }
    }
}