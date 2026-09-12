import QtQuick
import QtQuick.Layouts

import noi_engine_editor

Rectangle {
    id: root

    required property string resourceLabel
    required property string resourceType
    property bool hasHandle: true
    property int resourceId: -1
    property int resourceGeneration: -1
    property bool selected: false

    signal clicked()

    function iconFor(type) {
        switch (type) {
            case "mesh": return "view_in_ar"
            case "script": return "description"
            case "shader": return "gradient"
            case "texture": return "image"
            case "material": return "palette"
            default: return "folder"
        }
    }

    Layout.fillWidth: true
    height: 32

    radius: 6

    color: root.selected ? Theme.primaryLightC : (mouseArea.containsMouse ? Theme.bgTertiary : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        MuiIcon {
            name: root.iconFor(root.resourceType)
            font.pixelSize: 15
            color: root.selected ? Theme.primaryColor : Theme.grey
        }

        Text {
            Layout.fillWidth: true
            text: root.resourceLabel !== "" ? root.resourceLabel : qsTr("(unlabeled)")
            font.pixelSize: 12
            color: root.resourceLabel !== "" ? (root.selected ? Theme.white : Theme.darkGrey) : Theme.grey
            font.italic: root.resourceLabel === ""
            elide: Text.ElideRight
        }

        Text {
            visible: root.hasHandle
            text: "#%1 / gen %2".arg(root.resourceId).arg(root.resourceGeneration)
            font.family: "monospace"
            font.pixelSize: 10
            color: Theme.grey
        }

        Text {
            visible: !root.hasHandle
            text: qsTr("not loaded")
            font.italic: true
            font.pixelSize: 10
            color: Theme.grey
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
