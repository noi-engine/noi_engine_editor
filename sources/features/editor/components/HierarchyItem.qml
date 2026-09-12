import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    required property string entityName

    property bool selected: false

    signal clicked()

    Layout.fillWidth: true
    height: 32

    radius: 6

    color: selected ? Theme.primaryLightC : (mouseArea.containsMouse ? Theme.bgTertiary : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        MuiIcon {
            name: "category"
            font.pixelSize: 15
            color: root.selected ? Theme.primaryColor : Theme.grey
        }

        Text {
            Layout.fillWidth: true
            text: root.entityName
            font.pixelSize: 12
            color: root.selected ? Theme.white : Theme.darkGrey
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
