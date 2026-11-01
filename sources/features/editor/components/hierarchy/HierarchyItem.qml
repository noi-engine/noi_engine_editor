import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// One entity row in the Hierarchy.
Rectangle {
    id: root

    required property string entityName
    property string subtitle: "" // folder path, shown in search results
    property int depth: 0
    property bool selected: false
    property bool isLocked: false // camera entity - not renameable/deletable, but still duplicable
    property bool inFolder: false

    signal clicked()
    signal renameRequested()
    signal duplicateRequested()
    signal deleteRequested()
    signal moveToFolderRequested()
    signal removeFromFolderRequested()
    // Drag & drop: positions are in the item's own coordinates; the Hierarchy maps them.
    signal dragStarted(real x, real y)
    signal dragMoved(real x, real y)
    signal dragEnded(real x, real y)
    property bool dropTarget: false

    Layout.fillWidth: true
    height: 30

    radius: 6

    color: selected ? Theme.primaryLightC : (mouseArea.containsMouse ? Theme.bgTertiary : "transparent")
    border.color: Theme.primaryColor
    border.width: root.dropTarget ? 1 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 + root.depth * 16
        anchors.rightMargin: 10
        spacing: 8

        MuiIcon {
            name: root.isLocked ? "videocam" : "category"
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

        Text {
            visible: root.subtitle !== ""
            Layout.maximumWidth: root.width * 0.45
            text: root.subtitle
            font.pixelSize: 10
            color: Theme.grey
            elide: Text.ElideLeft
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true

        property point pressPoint
        property bool dragging: false

        onPressed: mouse => {
            pressPoint = Qt.point(mouse.x, mouse.y);
            dragging = false;
        }
        onPositionChanged: mouse => {
            if (!(mouse.buttons & Qt.LeftButton)) return;
            if (!dragging && Math.abs(mouse.x - pressPoint.x) + Math.abs(mouse.y - pressPoint.y) > 8) {
                dragging = true;
                root.dragStarted(mouse.x, mouse.y);
            }
            if (dragging) root.dragMoved(mouse.x, mouse.y);
        }
        onReleased: mouse => {
            if (dragging) {
                dragging = false;
                root.dragEnded(mouse.x, mouse.y);
            }
        }

        onClicked: mouse => {
            if (dragging) return;
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
        MenuSeparator {}
        MenuItem {
            text: qsTr("Move to Folder...")
            onTriggered: root.moveToFolderRequested()
        }
        MenuItem {
            text: qsTr("Remove from Folder")
            enabled: root.inFolder
            onTriggered: root.removeFromFolderRequested()
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Delete")
            enabled: !root.isLocked
            onTriggered: root.deleteRequested()
        }
    }
}
