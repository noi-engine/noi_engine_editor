import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

Dialog {
    id: root

    modal: true
    anchors.centerIn: parent
    width: 780
    height: 640
    padding: 0
    standardButtons: Dialog.NoButton

    property int currentIndex: 0

    readonly property var tabs: [
        { icon: "build", label: qsTr("Tools") },
    ]

    background: Rectangle {
        radius: 16
        color: Theme.bgPrimary
        border.color: Theme.borderColor
        border.width: 1
    }

    component NavItem: Rectangle {
        id: navItem

        property string icon: ""
        property string label: ""
        property bool selected: false

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 40
        radius: 10
        color: selected ? Theme.primaryColor : (mouseArea.containsMouse ? Theme.bgSecondary : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            MuiIcon {
                name: navItem.icon
                font.pixelSize: 16
                color: navItem.selected ? Theme.black : Theme.darkGrey
            }

            Text {
                text: navItem.label
                color: navItem.selected ? Theme.black : Theme.white
                font.pixelSize: 13
                font.bold: navItem.selected
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navItem.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 14

            IconBadge {
                icon: "settings"
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: qsTr("Settings")
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 20
                }

                Text {
                    text: qsTr("Manage the tools and preferences of Noi Engine Editor.")
                    color: Theme.darkGrey
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            AppButton {
                icon: "close"
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderColor
            opacity: 0.5
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                Layout.margins: 16
                spacing: 4

                Repeater {
                    model: root.tabs

                    delegate: NavItem {
                        required property var modelData
                        required property int index

                        icon: modelData.icon
                        label: modelData.label
                        selected: root.currentIndex === index

                        onClicked: root.currentIndex = index
                    }
                }

                Item { Layout.fillHeight: true }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.borderColor
                opacity: 0.5
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                currentIndex: root.currentIndex

                ToolsSettingsTab {}
            }
        }
    }
}
