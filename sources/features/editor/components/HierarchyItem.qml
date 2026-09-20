import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    required property string entityName
    property bool selected: false
    property bool isLocked: false // camera entity - not renameable/deletable, but still duplicable

    signal clicked()
    signal renameRequested()
    signal duplicateRequested()
    signal deleteRequested()

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            root.clicked()
            if (mouse.button === Qt.RightButton) {
                hierarchyMenu.popup()
            }
        }
    }

    Menu {
        id: hierarchyMenu

        MenuItem {
            text: qsTr("Rename")
            enabled: !root.isLocked
            onTriggered: root.renameRequested()
        }
        MenuItem {
            text: qsTr("Duplicate")
            onTriggered: root.duplicateRequested()
        }
        MenuItem {
            text: qsTr("Delete")
            enabled: !root.isLocked
            onTriggered: root.deleteRequested()
        }
    }
}
