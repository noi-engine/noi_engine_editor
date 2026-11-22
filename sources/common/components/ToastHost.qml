import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// Bottom-right stack of toasts, fed by Notifier. Errors stay longer than confirmations.
Item {
    id: root

    anchors.fill: parent
    z: 1000

    Connections {
        target: Notifier
        function onPosted(text, kind) {
            toasts.append({text: text, kind: kind});
        }
    }

    ListModel { id: toasts }

    ColumnLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.bottomMargin: 44
        spacing: 8

        Repeater {
            model: toasts

            delegate: Rectangle {
                id: toast
                required property int index
                required property string text
                required property string kind

                readonly property color accent: kind === "error" ? Theme.error
                    : kind === "warning" ? Theme.warning
                    : kind === "success" ? Theme.success : Theme.primaryLightA

                Layout.alignment: Qt.AlignRight
                Layout.maximumWidth: Math.min(420, root.width - 40)
                implicitWidth: toastRow.implicitWidth + 28
                implicitHeight: toastRow.implicitHeight + 22
                radius: Theme.radius
                color: Theme.bgTertiary
                border.color: accent
                border.width: 1
                opacity: 0

                Component.onCompleted: {
                    opacity = 1;
                    life.interval = kind === "error" ? 9000 : 3500;
                    life.start();
                }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Timer {
                    id: life
                    onTriggered: {
                        toast.opacity = 0;
                        removeTimer.start();
                    }
                }
                Timer {
                    id: removeTimer
                    interval: 180
                    onTriggered: if (toast.index < toasts.count) toasts.remove(toast.index)
                }

                RowLayout {
                    id: toastRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    MuiIcon {
                        name: toast.kind === "error" ? "error" : toast.kind === "warning" ? "warning"
                            : toast.kind === "success" ? "check_circle" : "info"
                        font.pixelSize: 18
                        color: toast.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: toast.text
                        color: Theme.white
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { toast.opacity = 0; removeTimer.start(); }
                }
            }
        }
    }
}
