import QtQuick
import QtQuick.Layouts
import noi_engine_editor

MouseArea {
    id: control

    property string text: ""
    property bool isOpen: false

    implicitWidth: contentRow.implicitWidth
    Layout.fillHeight: true
    cursorShape: Qt.PointingHandCursor

    RowLayout {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        IconBadge {
            icon: control.isOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
        }

        Text {
            text: control.text
            font.pixelSize: 11
            font.weight: Font.Medium
            color: Theme.white
        }
    }
}