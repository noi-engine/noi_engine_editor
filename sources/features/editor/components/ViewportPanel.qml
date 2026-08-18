import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: root

    property string scenePath: ""
    property var selectedEntity: null

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary

        OpenGLView {
            id: openGLView
            anchors.fill: parent
            focus: true
            visible: root.scenePath !== ""
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            visible: root.scenePath === ""

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 32
                color: Theme.bgSecondary
                border.color: Theme.borderColor
                border.width: 1

                MuiIcon {
                    anchors.centerIn: parent
                    name: "landscape"
                    font.pixelSize: 32
                    color: Theme.darkGrey
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No Scene Loaded")
                color: Theme.white
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Double-click a scene in the Scenes panel to open it.")
                color: Theme.darkGrey
                font.pixelSize: 11
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            height: 24
            width: pathText.implicitWidth + 16
            radius: 4
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            visible: root.scenePath !== ""

            Text {
                id: pathText
                anchors.centerIn: parent
                text: root.scenePath
                color: Theme.darkGrey
                font.pixelSize: 10
            }
        }
    }
}