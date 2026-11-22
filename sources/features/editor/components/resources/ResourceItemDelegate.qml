import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Item {
    id: root

    property string fileName: ""
    property string filePath: ""
    property bool isDir: false
    property bool isSelected: false
    property bool isMainScene: false
    property real iconScale: 1.0

    signal selected()
    signal doubleClicked()
    signal renameRequested()
    signal deleteRequested()
    // Scene files: the scene the game starts on.
    signal mainSceneRequested()

    readonly property bool isImage: !root.isDir && /\.(png|jpe?g|bmp|tga|gif)$/i.test(root.fileName)
    readonly property bool isScene: !root.isDir && /\.scene$/i.test(root.fileName)
    readonly property bool isCode: !root.isDir && /\.(cpp|hpp|h|cc)$/i.test(root.fileName)
    readonly property bool isShader: !root.isDir && /\.(shader|glsl|vert|frag)$/i.test(root.fileName)
    readonly property bool isAudio: !root.isDir && /\.(wav|ogg|mp3|flac)$/i.test(root.fileName)
    readonly property string typeIcon: isDir ? "folder" : isScene ? "landscape" : isCode ? "code"
        : isShader ? "blur_on" : isAudio ? "music_note" : "description"

    // Images can be dragged into the viewport to create a sprite there.
    Drag.active: mouseArea.drag.active && root.isImage
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.mimeData: ({"text/uri-list": "file://" + root.filePath})

    width: 90 * root.iconScale
    height: 90 * root.iconScale

    Rectangle {
        id: selectionBg
        anchors.fill: parent
        anchors.margins: 2
        radius: 6
        color: root.isSelected
            ? Qt.alpha(Theme.primaryColor, 0.25)
            : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.color: root.isSelected
            ? Theme.primaryColor
            : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6 * root.iconScale

        // Images show themselves; everything else gets the icon of its kind.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 56 * root.iconScale
            Layout.preferredHeight: 56 * root.iconScale
            radius: 8
            color: root.isScene ? Theme.primaryLightB : Theme.bgTertiary
            border.color: Theme.borderColor
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 3
                visible: root.isImage
                source: root.isImage ? "file://" + root.filePath : ""
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            // The scene the game starts on.
            Rectangle {
                visible: root.isMainScene
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 3
                width: 16
                height: 16
                radius: 8
                color: Theme.primaryColor

                MuiIcon {
                    anchors.centerIn: parent
                    name: "play_arrow"
                    font.pixelSize: 11
                    color: Theme.black
                }
            }

            MuiIcon {
                anchors.centerIn: parent
                visible: !root.isImage
                name: root.typeIcon
                font.pixelSize: 26 * root.iconScale
                color: root.isScene ? Theme.primaryColor : (root.isDir ? Theme.warning : Theme.darkGrey)
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 76 * root.iconScale
            text: root.fileName
            font.pixelSize: Math.max(9, Math.round(11 * root.iconScale))
            font.weight: root.isSelected ? Font.Medium : Font.Normal
            color: root.isSelected ? Theme.white : (mouseArea.containsMouse ? Theme.white : Theme.darkGrey)
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: root.isImage ? dragProxy : null

        onClicked: mouse => {
            root.selected()
            if (mouse.button === Qt.RightButton) {
                resourceMenu.popup()
            }
        }

        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                root.doubleClicked()
            }
        }
    }

    // Drag target (Drag.Automatic doesn't move it, it just starts the drag).
    Item { id: dragProxy }

    Menu {
        id: resourceMenu
        MenuItem {
            visible: root.isScene
            height: visible ? implicitHeight : 0
            text: qsTr("Open scene")
            onTriggered: root.doubleClicked()
        }
        MenuItem {
            visible: root.isScene
            height: visible ? implicitHeight : 0
            text: qsTr("Set as main scene")
            onTriggered: root.mainSceneRequested()
        }
        MenuSeparator { visible: root.isScene }
        MenuItem {
            text: qsTr("Rename")
            onTriggered: root.renameRequested()
        }
        MenuItem {
            text: qsTr("Delete")
            onTriggered: root.deleteRequested()
        }
    }
}