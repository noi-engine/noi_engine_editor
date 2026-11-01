import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// The scripts attached to an entity (script_component): detach one, attach any script of the
// project, or create a new one (New script... writes the files, compiles the project and
// attaches it). Scripts only run in Play mode.
Rectangle {
    id: section

    property var modelData // {type: "script_component", properties: [{name: "scripts[i]", value: label}, ...]}
    property var inspector

    readonly property bool expanded: inspector.isExpanded("script_component")
    readonly property var attached: (modelData.properties || [])
        .filter(p => p.name.startsWith("scripts["))
        .map(p => p.value)
    readonly property var available: inspector.resourceLabelsFor("script")
        .filter(l => section.attached.indexOf(l) === -1)

    function attach(label) {
        inspector.propertyEdited("script_component", "scripts[" + section.attached.length + "]", "resourceRef", label);
    }

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight + 16
    radius: 8
    color: Theme.bgTertiary
    border.color: Theme.borderColor
    border.width: 1

    ColumnLayout {
        id: cardColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MuiIcon {
                name: section.expanded ? "expand_more" : "chevron_right"
                font.pixelSize: 16
                color: Theme.grey
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Scripts")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: section.expanded ? Theme.white : Theme.darkGrey
                elide: Text.ElideRight

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspector.toggleExpanded("script_component")
                }
            }

            Text {
                visible: !section.expanded
                text: section.attached.length
                font.pixelSize: 10
                color: Theme.grey
            }

            MuiIcon {
                name: "delete"
                font.pixelSize: 14
                color: Theme.grey
                ToolTip.visible: removeArea.containsMouse
                ToolTip.text: qsTr("Remove all scripts")

                MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspector.componentRemoved("script_component")
                }
            }
        }

        Repeater {
            model: section.expanded ? section.attached : []

            delegate: RowLayout {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                spacing: 6

                MuiIcon {
                    name: "description"
                    font.pixelSize: 14
                    color: Theme.primaryColor
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData !== "" ? modelData : qsTr("(missing script)")
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: modelData !== "" ? Theme.white : Theme.error
                    elide: Text.ElideRight
                }

                MuiIcon {
                    name: "close"
                    font.pixelSize: 14
                    color: Theme.grey
                    ToolTip.visible: detachArea.containsMouse
                    ToolTip.text: qsTr("Detach")

                    MouseArea {
                        id: detachArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: inspector.propertyRemoved("script_component", "scripts[" + index + "]")
                    }
                }
            }
        }

        Text {
            visible: section.expanded && section.attached.length === 0
            Layout.fillWidth: true
            text: qsTr("No script attached yet.")
            font.pixelSize: 10
            font.italic: true
            color: Theme.grey
        }

        RowLayout {
            visible: section.expanded
            Layout.fillWidth: true
            spacing: 6

            ComboBox {
                id: attachCombo
                Layout.fillWidth: true
                enabled: section.available.length > 0
                model: section.available
                displayText: section.available.length > 0 ? qsTr("Attach a script...") : qsTr("No other script")
                font.pixelSize: 11
                currentIndex: -1
                onActivated: (i) => {
                    section.attach(section.available[i]);
                    attachCombo.currentIndex = -1;
                }
            }

            AppButton {
                text: qsTr("New script...")
                icon: "add"
                onClicked: inspector.openNewScript()
            }
        }

        Text {
            visible: section.expanded
            Layout.fillWidth: true
            text: qsTr("Scripts run in Play mode. Edit their code in sources/scripts, then Compile.")
            font.pixelSize: 9
            font.italic: true
            color: Theme.grey
            wrapMode: Text.WordWrap
        }
    }
}
