import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// The one dialog every window of the editor is built on: dark card, icon + title + subtitle,
// scrollable content and a footer for the actions. It never grows past the window, so it stays
// usable on small screens.
//
//   AppDialog {
//       title: qsTr("New folder"); subtitle: qsTr("..."); icon: "create_new_folder"
//       AppTextField { ... }                       // content
//       footerContent: [ AppButton { ... } ]        // actions, right aligned
//   }
Dialog {
    id: root

    property string subtitle: ""
    property string icon: ""
    property int preferredWidth: 520
    property bool showClose: true
    default property alias content: contentColumn.data
    property alias footerContent: footerRow.data

    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    parent: Overlay.overlay

    width: Math.min(preferredWidth, (parent ? parent.width : preferredWidth) - 32)
    height: Math.min(chrome.implicitHeight, (parent ? parent.height : 600) - 32)

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
        NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 120; easing.type: Easing.OutCubic }
    }

    // The title is drawn by our own header below, not by the style's.
    header: Item { implicitHeight: 0 }
    footer: Item { implicitHeight: 0 }

    background: Rectangle {
        radius: Theme.radiusLarge
        color: Theme.bgPrimary
        border.color: Theme.borderColor
        border.width: 1
    }

    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.55) }

    contentItem: ColumnLayout {
        id: chrome
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacingLarge
            spacing: 14

            IconBadge {
                visible: root.icon !== ""
                icon: root.icon !== "" ? root.icon : "info"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.white
                    font.bold: true
                    font.pixelSize: 18
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    color: Theme.darkGrey
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }

            AppButton {
                visible: root.showClose
                icon: "close"
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.borderColor
        }

        Flickable {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: contentColumn.implicitHeight + 2 * Theme.spacingLarge
            Layout.minimumHeight: 60
            contentWidth: width
            contentHeight: contentColumn.implicitHeight + 2 * Theme.spacingLarge
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: contentColumn
                x: Theme.spacingLarge
                y: Theme.spacingLarge
                width: scroller.width - 2 * Theme.spacingLarge
                spacing: Theme.spacing
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: footerRow.children.length > 0
            color: Theme.borderColor
        }

        RowLayout {
            id: footerRow
            Layout.fillWidth: true
            Layout.margins: Theme.spacingLarge
            visible: children.length > 0
            spacing: Theme.spacingSmall

            // Actions added through footerContent are pushed to the right.
        }
    }
}
