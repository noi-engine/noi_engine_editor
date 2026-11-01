import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// Floating viewport toolbar: tools, zoom and framing.
Rectangle {
    id: root

    property Item viewport

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 40
    radius: 20
    color: Theme.bgSecondary
    border.color: Theme.borderColor
    opacity: 0.95

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        ToolButtonCustom {
            iconName: "near_me"
            tooltipText: qsTr("Select: click to select, drag to move, handles to resize")
            isActive: root.viewport.activeTool === "select"
            onClicked: root.viewport.activeTool = "select"
        }

        ToolButtonCustom {
            iconName: "pan_tool"
            tooltipText: qsTr("Pan: drag to move the view (middle mouse button works with any tool)")
            isActive: root.viewport.activeTool === "pan"
            onClicked: root.viewport.activeTool = "pan"
        }

        Rectangle { width: 1; height: 18; color: Theme.borderColor }

        ToolButtonCustom {
            iconName: "zoom_out"
            tooltipText: qsTr("Zoom out (Ctrl+-, wheel)")
            onClicked: root.viewport.zoomBy(0.8)
        }

        Text {
            Layout.preferredWidth: 42
            horizontalAlignment: Text.AlignHCenter
            text: Math.round(root.viewport.viewZoom * 100) + "%"
            font.pixelSize: 11
            color: Theme.darkGrey
        }

        ToolButtonCustom {
            iconName: "zoom_in"
            tooltipText: qsTr("Zoom in (Ctrl+=, wheel, Shift + drag up)")
            onClicked: root.viewport.zoomBy(1.25)
        }

        Rectangle { width: 1; height: 18; color: Theme.borderColor }

        ToolButtonCustom {
            iconName: "videocam"
            tooltipText: qsTr("Frame the camera (Ctrl+0)")
            onClicked: root.viewport.frameCamera()
        }

        ToolButtonCustom {
            iconName: "center_focus_strong"
            tooltipText: qsTr("Frame the selection (F)")
            onClicked: root.viewport.frameSelection()
        }
    }
}
