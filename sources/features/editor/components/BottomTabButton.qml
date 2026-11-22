import QtQuick
import QtQuick.Layouts
import noi_engine_editor

// A tab of the bottom bar: opens / closes its panel.
MouseArea {
    id: control

    property string text: ""
    property bool isOpen: false

    implicitWidth: contentRow.implicitWidth + 20
    Layout.fillHeight: true
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: 6
        color: control.isOpen ? Theme.primaryLightC : (control.containsMouse ? Theme.bgTertiary : "transparent")
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        MuiIcon {
            name: control.isOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
            font.pixelSize: 14
            color: control.isOpen ? Theme.primaryLightA : Theme.grey
        }

        Text {
            text: control.text
            font.pixelSize: 11
            font.weight: control.isOpen ? Font.DemiBold : Font.Medium
            color: control.isOpen ? Theme.primaryLightA : Theme.white
        }
    }
}
