import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Item {
    id: root

    property string fileName: ""
    property string filePath: ""
    property bool isDir: false
    property bool isSelected: false
    property real iconScale: 1.0

    signal selected()
    signal doubleClicked()
    signal renameRequested()
    signal deleteRequested()
    // Image files: put the image in the open scene, as a sprite or as the background.
    signal spriteRequested(bool background)

    readonly property bool isImage: !root.isDir && /\.(png|jpe?g|bmp|tga|gif)$/i.test(root.fileName)

    // Images can be dragged into the viewport to create a sprite there.
    Drag.active: mouseArea.drag.active && root.isImage
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.mimeData: ({"text/uri-list": "file://" + root.filePath})

    width: 90 * root.iconScale
    height: 90 * root.iconScale

    Rectangle {
        id: selectionBg
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: root.isSelected
            ? Qt.alpha(Theme.primaryColor, 0.25)
            : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.color: root.isSelected
            ? Theme.primaryColor
            : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6 * root.iconScale

        IconBadge {
            Layout.alignment: Qt.AlignHCenter
            icon: root.isDir ? "folder" : "description"
            scale: root.iconScale
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 76 * root.iconScale
            text: root.fileName
            font.pixelSize: Math.max(9, Math.round(11 * root.iconScale))
            font.weight: root.isSelected ? Font.Medium : Font.Normal
            color: root.isSelected ? Theme.white : (mouseArea.containsMouse ? Theme.white : Theme.darkGrey)
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: root.isImage ? dragProxy : null

        onClicked: mouse => {
            root.selected()
            if (mouse.button === Qt.RightButton) {
                resourceMenu.popup()
            }
        }

        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.doubleClicked()
            }
        }
    }

    // Drag target (Drag.Automatic doesn't move it, it just starts the drag).
    Item { id: dragProxy }

    Menu {
        id: resourceMenu
        MenuItem {
            visible: root.isImage
            height: visible ? implicitHeight : 0
            text: qsTr("Create Sprite in Scene")
            onTriggered: root.spriteRequested(false)
        }
        MenuItem {
            visible: root.isImage
            height: visible ? implicitHeight : 0
            text: qsTr("Use as Background")
            onTriggered: root.spriteRequested(true)
        }
        MenuItem {
            text: qsTr("Rename")
            onTriggered: root.renameRequested()
        }
        MenuItem {
            text: qsTr("Delete")
            onTriggered: root.deleteRequested()
        }
    }
}