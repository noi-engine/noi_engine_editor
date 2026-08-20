import QtQuick
import QtQuick.Layouts
import noi_engine_editor
import "../../../../common/utils/LocalPathAndUrlConverter.js" as UrlConverter

DropArea {
    id: root

    signal importDropped(list<string> paths)

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.primaryColor, 0.1)
        border.color: Theme.primaryColor
        border.width: 2
        visible: root.containsDrag
        z: 10

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            IconBadge { Layout.alignment: Qt.AlignHCenter; icon: "file_upload" }
            Text {
                text: qsTr("Drop files or folders here")
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Theme.white
            }
        }
    }

    onDropped: drop => {
        if (drop.hasUrls) {
            let paths = drop.urls.map(url => UrlConverter.toLocalPath(url.toString()))
            root.importDropped(paths)
        }
    }
}