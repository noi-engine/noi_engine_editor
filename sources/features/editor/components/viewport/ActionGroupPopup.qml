import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

ToolButtonCustom {
    id: root

    property var actions: []

    onClicked: popup.visible ? popup.close() : popup.open()

    Popup {
        id: popup
        y: root.height + 6
        x: (root.width - width) / 2
        padding: 8
        closePolicy: Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.bgSecondary
            border.color: Theme.borderColor
            radius: 8
        }

        ColumnLayout {
            spacing: 6

            Repeater {
                model: root.actions

                ColumnLayout {
                    spacing: 4

                    Loader {
                        active: modelData ? modelData.type === "separator" : false
                        sourceComponent: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.borderColor
                        }
                    }

                    Loader {
                        active: modelData ? modelData.type === "header" : false
                        sourceComponent: Text {
                            text: (modelData && modelData.label) ? modelData.label : ""
                            color: Theme.white
                            font.pixelSize: 11
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Loader {
                        active: modelData ? modelData.type === "custom" : false
                        sourceComponent: RowLayout {
                            spacing: 4
                            Repeater {
                                model: (modelData && modelData.items) ? modelData.items : []
                                ToolButtonCustom {
                                    required property var modelData
                                    iconName: modelData.iconName || ""
                                    tooltipText: modelData.tooltipText || ""
                                    onClicked: {
                                        if (modelData.triggered) modelData.triggered()
                                        var closeOnClick = modelData.closeOnClick !== undefined ? modelData.closeOnClick : true
                                        if (closeOnClick) popup.close()
                                    }
                                }
                            }
                        }
                    }

                    Loader {
                        active: modelData ? (modelData.type === "button" || modelData.type === undefined) : false
                        sourceComponent: ToolButtonCustom {
                            iconName: (modelData && modelData.iconName) ? modelData.iconName : ""
                            tooltipText: (modelData && modelData.tooltipText) ? modelData.tooltipText : ""
                            onClicked: {
                                if (modelData && modelData.triggered) modelData.triggered()
                                var closeOnClick = (modelData && modelData.closeOnClick !== undefined) ? modelData.closeOnClick : true
                                if (closeOnClick) popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}