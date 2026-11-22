import QtQuick
import QtQuick.Layouts

import noi_engine_editor

// Left rail of the home page: brand, the main action, navigation and the state of the build tools.
Rectangle {
    id: root

    property bool compact: false
    property int missingCount: 0

    signal newProjectRequested()
    signal openProjectRequested()
    signal settingsRequested()
    signal toolsRequested()

    color: Theme.bgSecondary

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    component NavItem: Rectangle {
        id: item
        property string icon: ""
        property string label: ""
        property bool active: false
        signal triggered()

        Layout.fillWidth: true
        implicitHeight: 42
        radius: Theme.radius
        color: active ? Theme.primaryLightB : (area.containsMouse ? Theme.bgTertiary : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            visible: item.active
            width: 3
            height: 18
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            x: 0
            color: Theme.primaryColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 0 : 14
            anchors.rightMargin: 12
            spacing: 12

            Item { visible: root.compact; Layout.fillWidth: true }

            MuiIcon {
                name: item.icon
                font.pixelSize: 20
                color: item.active ? Theme.primaryColor : Theme.darkGrey
            }

            Text {
                visible: !root.compact
                Layout.fillWidth: true
                text: item.label
                font.pixelSize: 13
                font.weight: item.active ? Font.DemiBold : Font.Medium
                color: item.active ? Theme.white : Theme.darkGrey
                elide: Text.ElideRight
            }

            Item { visible: root.compact; Layout.fillWidth: true }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.triggered()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 10 : 18
        spacing: 6

        // Brand
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            spacing: 12

            Item { visible: root.compact; Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 12
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0; color: Theme.gradientStart }
                    GradientStop { position: 1; color: Theme.gradientEnd }
                }

                MuiIcon {
                    anchors.centerIn: parent
                    name: "sports_esports"
                    font.pixelSize: 22
                    color: Theme.black
                }
            }

            ColumnLayout {
                visible: !root.compact
                spacing: 0

                Text {
                    text: qsTr("Noi Engine")
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    color: Theme.white
                }

                Text {
                    text: qsTr("Game editor")
                    font.pixelSize: 11
                    color: Theme.grey
                }
            }

            Item { Layout.fillWidth: true }
        }

        AppButton {
            Layout.fillWidth: true
            primary: true
            compact: root.compact
            icon: "add"
            text: qsTr("New project")
            onClicked: root.newProjectRequested()
        }

        Item { Layout.preferredHeight: 10 }

        Text {
            visible: !root.compact
            Layout.leftMargin: 14
            text: qsTr("WORKSPACE")
            font.pixelSize: 10
            font.letterSpacing: 1.2
            font.weight: Font.DemiBold
            color: Theme.lightGrey
        }

        NavItem { icon: "grid_view"; label: qsTr("Projects"); active: true }
        NavItem { icon: "folder_open"; label: qsTr("Open a project…"); onTriggered: root.openProjectRequested() }
        NavItem { icon: "settings"; label: qsTr("Settings"); onTriggered: root.settingsRequested() }

        Item { Layout.fillHeight: true }

        // Build tools state: green when everything is there, amber with the count otherwise.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.compact ? 42 : 56
            radius: Theme.radius
            color: toolsArea.containsMouse ? Theme.bgTertiary : Theme.bgPrimary
            border.color: root.missingCount > 0 ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.55) : Theme.borderColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.compact ? 0 : 12
                anchors.rightMargin: 10
                spacing: 10

                Item { visible: root.compact; Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9
                    radius: 5
                    color: root.missingCount > 0 ? Theme.warning : Theme.success
                }

                ColumnLayout {
                    visible: !root.compact
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.missingCount > 0 ? qsTr("%n tool(s) missing", "", root.missingCount) : qsTr("Build tools ready")
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.white
                    }

                    Text {
                        text: root.missingCount > 0 ? qsTr("Click to see how to install") : qsTr("You can compile and play")
                        font.pixelSize: 10
                        color: Theme.grey
                    }
                }

                Item { visible: root.compact; Layout.fillWidth: true }
            }

            MouseArea {
                id: toolsArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toolsRequested()
            }
        }
    }
}
