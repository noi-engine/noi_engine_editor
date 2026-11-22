import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// The editor's button. Primary = mint gradient with a soft glow, danger = red, default = quiet.
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool primary: false
    property bool danger: false
    // Icon only (text moves to the tooltip): for narrow toolbars.
    property bool compact: false
    // Shown on hover; for a disabled button it should say why.
    property string tooltip: ""

    signal clicked()

    implicitWidth: contentRow.implicitWidth + (compact && icon !== "" ? 22 : 30)
    implicitHeight: 40

    radius: 11
    opacity: root.enabled ? 1.0 : 0.4
    scale: mouseArea.pressed && root.enabled ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

    readonly property bool filled: primary || danger

    color: danger ? (mouseArea.containsMouse ? Qt.lighter(Theme.error, 1.1) : Theme.error)
         : primary ? (mouseArea.containsMouse ? Theme.primaryLightA : Theme.primaryColor)
         : (mouseArea.containsMouse ? Theme.bgElevated : Theme.bgTertiary)
    Behavior on color { ColorAnimation { duration: 110 } }

    border.color: filled ? "transparent" : (mouseArea.containsMouse ? Theme.borderStrong : Theme.borderColor)
    border.width: filled ? 0 : 1
    activeFocusOnTab: true
    Keys.onReturnPressed: if (root.enabled) root.clicked()
    Keys.onSpacePressed: if (root.enabled) root.clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.color: Theme.primaryLightA
        border.width: 2
        visible: root.activeFocus
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 7

        MuiIcon {
            visible: root.icon.length > 0
            name: root.icon.length > 0 ? root.icon : "close"
            font.pixelSize: 17
            color: root.filled ? Theme.black : Theme.white
        }

        Text {
            visible: !(root.compact && root.icon !== "") && root.text !== ""
            text: root.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.filled ? Theme.black : Theme.white
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
        onClicked: { if (root.enabled) { root.forceActiveFocus(); root.clicked() } }
    }

    ToolTip.visible: mouseArea.containsMouse && ToolTip.text !== ""
    ToolTip.delay: 450
    ToolTip.text: root.tooltip !== "" ? root.tooltip : (root.compact ? root.text : "")
}
