import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    required property string entityName
    required property string entityType
    required property int entityDepth

    property bool selected: false

    signal clicked()

    function iconFor(type) {
        switch (type) {
            case "camera": return "camera_alt"
            case "light": return "light_mode"
            case "mesh": return "view_in_ar"
            default: return "folder"
        }
    }

    Layout.fillWidth: true
    height: 32

    radius: 6

    color: selected ? Theme.primaryLightC : (mouseArea.containsMouse ? Theme.bgTertiary : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 + root.entityDepth * 18
        anchors.rightMargin: 10
        spacing: 8

        MuiIcon {
            name: root.iconFor(root.entityType)
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