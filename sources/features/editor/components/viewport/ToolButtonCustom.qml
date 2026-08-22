import QtQuick
import QtQuick.Controls
import noi_engine_editor

Rectangle {
    id: root

    property string iconName: ""
    property string tooltipText: ""
    property bool isActive: false
    property bool isEnabled: true

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: 14
    opacity: isEnabled ? (btnMouse.containsMouse ? 0.9 : 1.0) : 0.3
    color: isActive ? Theme.primaryLightB : (btnMouse.containsMouse ? Theme.bgTertiary : "transparent")
    border.color: isActive ? Theme.primaryColor : "transparent"

    MuiIcon {
        anchors.centerIn: parent
        name: root.iconName
        font.pixelSize: 15
        color: root.isActive ? Theme.primaryColor : (btnMouse.containsMouse ? Theme.white : Theme.darkGrey)
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        enabled: root.isEnabled
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ToolTip.visible: btnMouse.containsMouse && tooltipText !== ""
    ToolTip.text: tooltipText
    ToolTip.delay: 300
}