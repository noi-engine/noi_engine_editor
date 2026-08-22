import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: root

    property string scenePath: ""
    property var selectedEntity: null

    property string activeTool: "move"
    property real cameraZoom: 1.0

    readonly property real baseWidth: CurrentProjectManager.windowWidth
    readonly property real baseHeight: CurrentProjectManager.windowHeight

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary
        clip: true

        Flickable {
            id: viewportFlickable
            anchors.fill: parent
            visible: root.scenePath !== ""
            clip: true

            boundsBehavior: Flickable.StopAtBounds
            interactive: root.activeTool === "move"

            contentWidth: container.width
            contentHeight: container.height

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: viewportFlickable.moving || viewportFlickable.flicking || viewportFlickable.activeFocus
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                active: viewportFlickable.moving || viewportFlickable.flicking || viewportFlickable.activeFocus
            }

            Item {
                id: container
                width: Math.max(viewportFlickable.width, root.baseWidth)
                height: Math.max(viewportFlickable.height, root.baseHeight)

                OpenGLView {
                    id: openGLView
                    anchors.fill: parent
                    scenePath: root.scenePath
                    resourcesPath: CurrentProjectManager.resourcesPath()
                    cameraZoom: root.cameraZoom
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: {
                        if (root.activeTool === "move") {
                            return pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        }
                        return Qt.ArrowCursor
                    }

                    onClicked: (mouse) => {
                        if (root.activeTool === "select") {
                        }
                    }
                }
            }
        }

        ViewportToolbar {
            x: 20
            y: 20
            visible: root.scenePath !== ""
            activeTool: root.activeTool
            zoomValue: root.cameraZoom

            onToolChanged: (tool) => root.activeTool = tool
            onZoomInRequested: root.cameraZoom += 0.25
            onZoomOutRequested: root.cameraZoom = Math.max(0.1, root.cameraZoom - 0.25)
            onZoomResetRequested: root.cameraZoom = 1.0
            onSetZoomRequested: (zoom) => root.cameraZoom = zoom
            onResetAllRequested: {
                root.cameraZoom = 1.0
                viewportFlickable.contentX = 0
                viewportFlickable.contentY = 0
                container.width = root.baseWidth
                container.height = root.baseHeight
            }
            onModifyWorldSizeRequested: (factor) => {
                if (factor === 0.0) {
                    container.width = root.baseWidth
                    container.height = root.baseHeight
                } else {
                    container.width = Math.max(root.baseWidth, container.width * factor)
                    container.height = Math.max(root.baseHeight, container.height * factor)
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            visible: root.scenePath === ""

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 32
                color: Theme.bgSecondary
                border.color: Theme.borderColor
                border.width: 1

                MuiIcon {
                    anchors.centerIn: parent
                    name: "landscape"
                    font.pixelSize: 32
                    color: Theme.primaryColor
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No Scene Loaded")
                color: Theme.white
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Double-click a scene in the Scenes panel to open it.")
                color: Theme.darkGrey
                font.pixelSize: 11
            }
        }
    }
}