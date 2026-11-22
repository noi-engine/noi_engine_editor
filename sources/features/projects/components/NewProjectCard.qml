import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// First tile of the grid: dashed outline, plus sign, starts the new-project window.
Item {
    id: root

    signal clicked()

    implicitHeight: 196

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: area.containsMouse ? Theme.primaryLightC : "transparent"
        border.width: 1
        border.color: area.containsMouse ? Theme.primaryColor : Theme.borderStrong
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 46; height: 46; radius: 23
                color: area.containsMouse ? Theme.primaryColor : Theme.primaryLightB
                Behavior on color { ColorAnimation { duration: 140 } }

                MuiIcon {
                    anchors.centerIn: parent
                    name: "add"
                    font.pixelSize: 26
                    color: area.containsMouse ? Theme.black : Theme.primaryColor
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("New project")
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: Theme.white
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Start from a template")
                font.pixelSize: 11
                color: Theme.grey
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
