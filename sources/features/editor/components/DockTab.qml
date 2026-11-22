import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// A tab of the bottom dock (Project, Scenes, Console...).
Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool isOpen: false
    // Draws a red dot: something in this tab needs a look (a failed build in the Console).
    property bool attention: false

    signal clicked()

    implicitWidth: row.implicitWidth + 24
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        radius: 8
        color: root.isOpen ? Theme.bgElevated : (area.containsMouse ? Theme.bgTertiary : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 7

        MuiIcon {
            name: root.icon
            font.pixelSize: 16
            color: root.isOpen ? Theme.primaryColor : Theme.grey
        }

        Text {
            text: root.text
            font.pixelSize: 12
            font.weight: root.isOpen ? Font.DemiBold : Font.Medium
            color: root.isOpen ? Theme.white : Theme.darkGrey
        }

        Rectangle {
            visible: root.attention
            Layout.preferredWidth: 7
            Layout.preferredHeight: 7
            radius: 4
            color: Theme.error
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
