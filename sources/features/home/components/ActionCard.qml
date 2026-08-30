import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string description: ""
    property string actionText: ""
    property bool primary: false

    signal clicked()

    Layout.fillWidth: true
    Layout.minimumWidth: 280
    Layout.preferredHeight: 155

    radius: 14

    color: {
        if (root.primary)
            return mouseArea.containsMouse ? Qt.lighter(Theme.primaryColor, 1.05) : Theme.primaryColor
        else
            return mouseArea.containsMouse ? Qt.lighter(Theme.bgSecondary, 1.2) : Theme.bgSecondary
    }

    border.color: root.primary ? "transparent" : (mouseArea.containsMouse ? Theme.primaryColor : Theme.borderColor)
    border.width: 1

    scale: mouseArea.containsMouse ? 1.02 : 1.0

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8

        RowLayout {
            spacing: 11

            MuiIcon {
                name: root.icon
                font.pixelSize: 30
                color: root.primary ? Theme.black : Theme.primaryColor
            }

            Text {
                text: root.title
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: root.primary ? Theme.black : Theme.white
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            color: root.primary ? "#D8F8E9" : Theme.darkGrey
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            spacing: 5

            Item {
                width: mouseArea.containsMouse ? 5 : 0
                Behavior on width { NumberAnimation { duration: 150 } }
            }

            Text {
                text: root.actionText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.primary ? Theme.black : Theme.primaryColor
            }

            MuiIcon {
                name: "arrow_forward"
                font.pixelSize: 18
                color: root.primary ? Theme.black : Theme.primaryColor
            }
        }
    }
}