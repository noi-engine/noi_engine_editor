import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import noi_engine_editor

// Shared read-only log view used by CompilerOutputPanel and EditorLogsPanel.
Item {
    id: rootItem

    property string title: ""
    property string text: ""
    property bool busy: false
    property string busyText: ""

    signal clearRequested()

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSecondary

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Theme.bgTertiary

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: rootItem.title
                        color: Theme.white
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        visible: rootItem.busy
                        text: rootItem.busyText
                        color: Theme.primaryColor
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    MuiIcon {
                        name: "clear_all"
                        font.pixelSize: 18
                        color: clearArea.containsMouse ? Theme.white : Theme.darkGrey

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootItem.clearRequested()
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    text: rootItem.text
                    readOnly: true
                    wrapMode: TextArea.NoWrap
                    selectByMouse: true
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: Theme.white
                    padding: 12

                    background: Rectangle { color: Theme.bgPrimary }

                    onTextChanged: cursorPosition = length
                }
            }
        }
    }
}
