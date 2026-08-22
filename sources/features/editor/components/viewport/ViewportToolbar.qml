import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Rectangle {
    id: toolbar

    property string activeTool: "move"
    property real worldScale: 1.0
    property bool isCollapsed: false

    signal toolChanged(string tool)
    signal expandWorld()
    signal shrinkWorld()
    signal centerRequested()
    signal resetRequested()

    width: isCollapsed ? 68 : toolRow.implicitWidth + 20
    height: 40
    radius: 20
    color: Theme.bgSecondary
    border.color: Theme.borderColor
    z: 100

    function keepInBounds() {
        if (!parent) return
        if (x + width > parent.width - 8) {
            x = Math.max(8, parent.width - width - 8)
        }
        if (x < 8) {
            x = 8
        }
        if (y + height > parent.height - 8) {
            y = Math.max(8, parent.height - height - 8)
        }
        if (y < 8) {
            y = 8
        }
    }

    Connections {
        target: toolbar.parent
        function onWidthChanged() { toolbar.keepInBounds() }
        function onHeightChanged() { toolbar.keepInBounds() }
    }

    onWidthChanged: keepInBounds()

    Behavior on width {
        NumberAnimation {
            duration: 180
            easing.type: Easing.InOutQuad
            onRunningChanged: {
                if (!running) toolbar.keepInBounds()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.black
        opacity: 0.4
        z: -1
        anchors.topMargin: 2
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: toolbar

        drag.minimumX: 8
        drag.maximumX: toolbar.parent ? toolbar.parent.width - toolbar.width - 8 : 0
        drag.minimumY: 8
        drag.maximumY: toolbar.parent ? toolbar.parent.height - toolbar.height - 8 : 0

        cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    }

    RowLayout {
        id: toolRow
        anchors.centerIn: parent
        spacing: 4

        MuiIcon {
            name: "drag_indicator"
            font.pixelSize: 18
            color: Theme.grey
            Layout.leftMargin: 2
        }

        ToolButtonCustom {
            iconName: toolbar.isCollapsed ? "chevron_right" : "chevron_left"
            tooltipText: toolbar.isCollapsed ? "Déplier" : "Réduire"
            onClicked: toolbar.isCollapsed = !toolbar.isCollapsed
        }

        RowLayout {
            spacing: 4
            visible: !toolbar.isCollapsed

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.borderColor
            }

            ToolButtonCustom {
                iconName: "open_with"
                tooltipText: "Déplacement (Pan)"
                isActive: toolbar.activeTool === "move"
                onClicked: {
                    toolbar.activeTool = "move"
                    toolbar.toolChanged("move")
                }
            }

            ToolButtonCustom {
                iconName: "near_me"
                tooltipText: "Sélection"
                isActive: toolbar.activeTool === "select"
                isEnabled: false
                onClicked: {
                    toolbar.activeTool = "select"
                    toolbar.toolChanged("select")
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.borderColor
            }

            ToolButtonCustom {
                iconName: "aspect_ratio"
                tooltipText: "Agrandir le World (+25%)"
                onClicked: toolbar.expandWorld()
            }

            ToolButtonCustom {
                iconName: "compress"
                tooltipText: "Réduire le World (-25%)"
                isEnabled: toolbar.worldScale > 1.0
                onClicked: toolbar.shrinkWorld()
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.borderColor
            }

            ToolButtonCustom {
                iconName: "filter_center_focus"
                tooltipText: "Recentrer"
                onClicked: toolbar.centerRequested()
            }

            ToolButtonCustom {
                iconName: "restart_alt"
                tooltipText: "Position d'origine (0,0)"
                onClicked: toolbar.resetRequested()
            }
        }
    }

    component ToolButtonCustom: Rectangle {
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
            name: parent.iconName
            font.pixelSize: 15
            color: parent.isActive ? Theme.primaryColor : (btnMouse.containsMouse ? Theme.white : Theme.darkGrey)
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: parent.isEnabled
            hoverEnabled: true
            onClicked: parent.clicked()
        }

        ToolTip.visible: btnMouse.containsMouse && tooltipText !== ""
        ToolTip.text: tooltipText
        ToolTip.delay: 300
    }
}
