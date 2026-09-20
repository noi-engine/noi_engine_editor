import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Rectangle {
    id: toolbar

    property string activeTool: "move"
    property bool isCollapsed: false
    property real zoomValue: 1.0
    property bool gridVisible: false

    signal toolChanged(string tool)
    signal zoomInRequested()
    signal zoomOutRequested()
    signal zoomResetRequested()
    signal setZoomRequested(real zoom)
    signal modifyWorldSizeRequested(real factor)
    signal resetAllRequested()
    signal gridVisibleToggled(bool visible)

    width: isCollapsed ? 68 : toolRow.implicitWidth + 20
    height: 40
    radius: 20
    color: Theme.bgSecondary
    border.color: Theme.borderColor
    z: 100

    function keepInBounds() {
        if (!parent) return
        x = Math.min(Math.max(8, x), parent.width - width - 8)
        y = Math.min(Math.max(8, y), parent.height - height - 8)
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
            onRunningChanged: { if (!running) toolbar.keepInBounds() }
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
            tooltipText: toolbar.isCollapsed ? "Expand" : "Collapse"
            onClicked: toolbar.isCollapsed = !toolbar.isCollapsed
        }

        RowLayout {
            spacing: 6
            visible: !toolbar.isCollapsed

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.borderColor
            }

            ToolButtonCustom {
                iconName: "open_with"
                tooltipText: "Pan Tool"
                isActive: toolbar.activeTool === "move"
                onClicked: {
                    toolbar.activeTool = "move"
                    toolbar.toolChanged("move")
                }
            }

            ToolButtonCustom {
                iconName: "near_me"
                tooltipText: "Select Tool"
                isActive: toolbar.activeTool === "select"
                isEnabled: false
                onClicked: {
                    toolbar.activeTool = "select"
                    toolbar.toolChanged("select")
                }
            }

            ToolButtonCustom {
                iconName: "filter_center_focus"
                tooltipText: "Reset All (Zoom & Position)"
                onClicked: toolbar.resetAllRequested()
            }

            ActionGroupPopup {
                iconName: "grid_4x4"
                tooltipText: "View Options"
                actions: [
                    {
                        type: "custom",
                        items: [
                            {
                                iconName: toolbar.gridVisible ? "grid_on" : "grid_off",
                                tooltipText: toolbar.gridVisible ? "Hide Reference Grid" : "Show Reference Grid",
                                isActive: toolbar.gridVisible,
                                closeOnClick: false,
                                triggered: function() {
                                    toolbar.gridVisible = !toolbar.gridVisible
                                    toolbar.gridVisibleToggled(toolbar.gridVisible)
                                }
                            }
                        ]
                    }
                ]
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                color: Theme.borderColor
            }

            ActionGroupPopup {
                iconName: "search"
                tooltipText: "Zoom Controls (" + Math.round(toolbar.zoomValue * 100) + "%)"
                actions: [
                    {
                        type: "header",
                        label: Math.round(toolbar.zoomValue * 100) + "%"
                    },
                    {
                        type: "custom",
                        items: [
                            {
                                iconName: "zoom_in",
                                tooltipText: "Zoom In",
                                closeOnClick: false,
                                triggered: function() { toolbar.zoomInRequested() }
                            },
                            {
                                iconName: "zoom_out",
                                tooltipText: "Zoom Out",
                                closeOnClick: false,
                                triggered: function() { toolbar.zoomOutRequested() }
                            },
                            {
                                iconName: "youtube_searched_for",
                                tooltipText: "Reset Zoom",
                                closeOnClick: true,
                                triggered: function() { toolbar.zoomResetRequested() }
                            }
                        ]
                    },
                    {
                        type: "separator"
                    },
                    {
                        type: "custom",
                        items: [
                            {
                                iconName: "fit_screen",
                                tooltipText: "Set 50%",
                                closeOnClick: true,
                                triggered: function() { toolbar.setZoomRequested(0.5) }
                            },
                            {
                                iconName: "aspect_ratio",
                                tooltipText: "Set 100%",
                                closeOnClick: true,
                                triggered: function() { toolbar.setZoomRequested(1.0) }
                            },
                            {
                                iconName: "fullscreen",
                                tooltipText: "Set 200%",
                                closeOnClick: true,
                                triggered: function() { toolbar.setZoomRequested(2.0) }
                            }
                        ]
                    }
                ]
            }

            ActionGroupPopup {
                iconName: "public"
                tooltipText: "World Scale Controls"
                actions: [
                    {
                        type: "custom",
                        items: [
                            {
                                iconName: "add",
                                tooltipText: "+25%",
                                closeOnClick: false,
                                triggered: function() { toolbar.modifyWorldSizeRequested(1.25) }
                            },
                            {
                                iconName: "add_circle",
                                tooltipText: "+50%",
                                closeOnClick: false,
                                triggered: function() { toolbar.modifyWorldSizeRequested(1.50) }
                            },
                            {
                                iconName: "add_circle_outline",
                                tooltipText: "+100%",
                                closeOnClick: false,
                                triggered: function() { toolbar.modifyWorldSizeRequested(2.00) }
                            }
                        ]
                    },
                    {
                        type: "separator"
                    },
                    {
                        type: "custom",
                        items: [
                            {
                                iconName: "remove",
                                tooltipText: "-25%",
                                closeOnClick: false,
                                triggered: function() { toolbar.modifyWorldSizeRequested(0.75) }
                            },
                            {
                                iconName: "remove_circle",
                                tooltipText: "-50%",
                                closeOnClick: false,
                                triggered: function() { toolbar.modifyWorldSizeRequested(0.50) }
                            },
                            {
                                iconName: "remove_circle_outline",
                                tooltipText: "-100% (Reset World)",
                                closeOnClick: true,
                                triggered: function() { toolbar.modifyWorldSizeRequested(0.0) }
                            }
                        ]
                    }
                ]
            }
        }
    }
}