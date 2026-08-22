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

    readonly property real baseWidth: CurrentProjectManager.windowWidth * 3
    readonly property real baseHeight: CurrentProjectManager.windowHeight * 3

    Rectangle {
        anchors.fill: parent
        color: Theme.bgPrimary

        Flickable {
            id: viewportFlickable
            anchors.fill: parent
            visible: root.scenePath !== ""

            boundsBehavior: Flickable.StopAtBounds
            interactive: root.activeTool === "move"

            contentWidth: container.width
            contentHeight: container.height

            Item {
                id: container
                width: root.baseWidth * root.worldScale
                height: root.baseHeight * root.worldScale

                OpenGLView {
                    id: openGLView
                    anchors.centerIn: parent
                    width: root.baseWidth
                    height: root.baseHeight
                    scenePath: root.scenePath
                    gameWidth: CurrentProjectManager.windowWidth
                    gameHeight: CurrentProjectManager.windowHeight
                    resourcesPath: CurrentProjectManager.resourcesPath()
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.activeTool !== "move"
                    cursorShape: Qt.ArrowCursor

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