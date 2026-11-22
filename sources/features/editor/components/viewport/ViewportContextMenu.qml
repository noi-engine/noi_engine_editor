import QtQuick
import QtQuick.Controls

import noi_engine_editor

// Right-click menu of the viewport. On an object: copy, paste, duplicate, delete, align to the
// screen, bring to front / send to back. On empty space: paste here, frame the camera.
Menu {
    id: root

    property bool hasEntity: false
    property bool canPaste: false
    property bool isCamera: false

    signal action(string name)

    MenuItem { text: qsTr("Copy\tCtrl+C"); enabled: root.hasEntity && !root.isCamera; onTriggered: root.action("copy") }
    MenuItem { text: root.hasEntity ? qsTr("Paste\tCtrl+V") : qsTr("Paste here"); enabled: root.canPaste; onTriggered: root.action("paste") }
    MenuItem { text: qsTr("Duplicate\tCtrl+D"); enabled: root.hasEntity; onTriggered: root.action("duplicate") }
    MenuItem { text: qsTr("Delete\tDel"); enabled: root.hasEntity && !root.isCamera; onTriggered: root.action("delete") }

    MenuSeparator { visible: root.hasEntity }

    Menu {
        title: qsTr("Align to the screen")
        enabled: root.hasEntity

        MenuItem { text: qsTr("Center"); onTriggered: root.action("align_center") }
        MenuItem { text: qsTr("Center horizontally"); onTriggered: root.action("align_hcenter") }
        MenuItem { text: qsTr("Center vertically"); onTriggered: root.action("align_vcenter") }
        MenuSeparator {}
        MenuItem { text: qsTr("Left edge"); onTriggered: root.action("align_left") }
        MenuItem { text: qsTr("Right edge"); onTriggered: root.action("align_right") }
        MenuItem { text: qsTr("Top edge"); onTriggered: root.action("align_top") }
        MenuItem { text: qsTr("Bottom edge"); onTriggered: root.action("align_bottom") }
    }

    Menu {
        title: qsTr("Order")
        enabled: root.hasEntity && !root.isCamera

        MenuItem { text: qsTr("Bring to front"); onTriggered: root.action("front") }
        MenuItem { text: qsTr("Send to back"); onTriggered: root.action("back") }
    }

    MenuSeparator {}

    MenuItem { text: qsTr("Frame the camera\tCtrl+0"); onTriggered: root.action("frame") }
}
