import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// One folder row in the Hierarchy.
Rectangle {
    id: root

    required property string folderName
    property int depth: 0
    property int entityCount: 0
    property bool expanded: true

    signal toggled()
    signal renameRequested()
    signal ungroupRequested()
    signal newEntityRequested()
    signal newSubfolderRequested()
    signal duplicateRequested()
    signal deleteRequested()
    // Drag & drop: positions are in the item's own coordinates; the Hierarchy maps them.
    signal dragStarted(real x, real y)
    signal dragMoved(real x, real y)
    signal dragEnded(real x, real y)
    property bool dropTarget: false

    Layout.fillWidth: true
    height: 30
    radius: 6
    color: root.dropTarget ? Theme.primaryLightC : (mouseArea.containsMouse ? Theme.bgTertiary : "transparent")
    border.color: Theme.primaryColor
    border.width: root.dropTarget ? 1 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4 + root.depth * 16
        anchors.rightMargin: 10
        spacing: 4

        MuiIcon {
            name: root.expanded ? "expand_more" : "chevron_right"
            font.pixelSize: 16
            color: Theme.grey
        }

        MuiIcon {
            name: root.expanded ? "folder_open" : "folder"
            font.pixelSize: 15
            color: "#E0B85B"
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: root.folderName
            font.pixelSize: 12
            color: Theme.darkGrey
            elide: Text.ElideRight
        }

        Text {
            text: root.entityCount
            font.pixelSize: 10
            color: Theme.grey
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
            if (mouse.button === Qt.RightButton) {
                folderMenu.popup();
            } else {
                root.toggled();
            }
        }
    }

    Menu {
        id: folderMenu

        MenuItem {
            text: qsTr("New Entity Here")
            onTriggered: root.newEntityRequested()
        }
        MenuItem {
            text: qsTr("New Sub-folder")
            onTriggered: root.newSubfolderRequested()
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Rename")
            onTriggered: root.renameRequested()
        }
        MenuItem {
            text: qsTr("Duplicate")
            onTriggered: root.duplicateRequested()
        }
        MenuItem {
            text: qsTr("Ungroup (keep entities)")
            onTriggered: root.ungroupRequested()
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Delete (with its entities)")
            onTriggered: root.deleteRequested()
        }
    }
}
