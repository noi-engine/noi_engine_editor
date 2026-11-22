import QtQuick
import QtQuick.Effects

import noi_engine_editor

// A floating panel of the editor: rounded, hairline border, its content clipped to the rounded
// shape (so headers and the viewport follow the corners).
Item {
    id: root

    default property alias content: holder.data
    property int radius: 14
    property color color: Theme.bgSecondary
    property bool highlighted: false

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.width: 1
        border.color: root.highlighted ? Theme.primaryColor : Theme.borderColor
    }

    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: 1
        // Rounded clipping needs shader effects: with the software renderer the content simply
        // keeps square corners.
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }

    Item {
        id: maskItem
        anchors.fill: holder
        visible: false
        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software

        Rectangle {
            anchors.fill: parent
            radius: root.radius - 1
            color: "black"
        }
    }
}
