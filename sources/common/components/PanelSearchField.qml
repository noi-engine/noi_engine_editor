import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Compact search box for panel headers.
Rectangle {
    id: root

    property alias text: textField.text
    property string placeholderText: qsTr("Search...")

    function focusField() {
        textField.forceActiveFocus();
        textField.selectAll();
    }

    Layout.fillWidth: true
    Layout.preferredHeight: 28
    radius: 6
    color: Theme.bgPrimary
    border.color: textField.activeFocus ? Theme.primaryColor : Theme.borderColor
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 6

        MuiIcon {
            name: "search"
            font.pixelSize: 14
            color: Theme.grey
        }

        TextField {
            id: textField

            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: root.placeholderText
            placeholderTextColor: Theme.grey
            background: Item {}
            font.pixelSize: 11
            color: Theme.white
            selectByMouse: true
            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 0
            rightPadding: 0

            Keys.onEscapePressed: textField.clear()
        }

        MuiIcon {
            visible: textField.text.length > 0
            name: "close"
            font.pixelSize: 13
            color: Theme.grey

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: textField.clear()
            }
        }
    }
}
