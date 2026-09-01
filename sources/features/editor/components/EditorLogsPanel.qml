import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import noi_engine_editor

Item {
    id: rootItem

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
                        text: qsTr("EDITOR LOGS")
                        color: Theme.white
                        font.pixelSize: 11
                        font.bold: true
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
                            onClicked: EditorLogger.clear()
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    id: logsArea
                    text: EditorLogger.text
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
