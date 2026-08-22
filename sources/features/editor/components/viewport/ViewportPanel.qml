import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: root

    property string scenePath: ""
    property var selectedEntity: null

    property string activeTool: "move"
    property real worldScale: 1.0

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
                width: Math.max(viewportFlickable.width, root.baseWidth * root.worldScale)
                height: Math.max(viewportFlickable.height, root.baseHeight * root.worldScale)

                OpenGLView {
                    id: openGLView
                    anchors.fill: parent
                    scenePath: root.scenePath
                    resourcesPath: CurrentProjectManager.resourcesPath()
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
            worldScale: root.worldScale

            onToolChanged: (tool) => root.activeTool = tool
            onExpandWorld: root.worldScale += 0.25
            onShrinkWorld: root.worldScale = Math.max(1.0, root.worldScale - 0.25)

            onCenterRequested: {
                viewportFlickable.contentX = Math.max(0, (container.width - viewportFlickable.width) / 2)
                viewportFlickable.contentY = Math.max(0, (container.height - viewportFlickable.height) / 2)
            }

            onResetRequested: {
                viewportFlickable.contentX = 0
                viewportFlickable.contentY = 0
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