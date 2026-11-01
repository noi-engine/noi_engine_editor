import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// An entity added as a sprite (editor group "sprite"): one section for its look (a color or
// an image) and size, instead of the raw Mesh Renderer / Material Overrides / Transform
// fields. Switching the look also cleans up what the previous look used.
Rectangle {
    id: section

    property var modelData // {type: "sprite", meshRenderer, overrides, transform}
    property var inspector

    readonly property bool expanded: inspector.isExpanded("sprite")

    function valueOf(properties, name, fallback) {
        for (const p of properties || []) {
            if (p.name === name) return p.value;
        }
        return fallback;
    }

    readonly property string material: valueOf(modelData.meshRenderer, "material", "")
    readonly property bool imageMode: material === "materials:texture"
    readonly property var spriteColor: valueOf(modelData.overrides, "color:u_color", [1, 1, 1, 1])
    readonly property string texture: valueOf(modelData.overrides, "texture:u_texture", "")
    readonly property var scale: valueOf(modelData.transform, "scale", [1, 1, 1])
    readonly property var textures: inspector.resourceLabelsFor("texture")
    property bool keepRatio: true

    function useColor() {
        inspector.propertyEdited("mesh_renderer", "material", "resourceRef", "materials:color");
        inspector.propertyRemoved("mesh_renderer_properties", "texture:u_texture");
        inspector.propertyEdited("mesh_renderer_properties", "color:u_color", "vec4", [1, 1, 1, 1]);
    }

    function useImage(label) {
        inspector.propertyEdited("mesh_renderer", "material", "resourceRef", "materials:texture");
        inspector.propertyRemoved("mesh_renderer_properties", "color:u_color");
        inspector.propertyEdited("mesh_renderer_properties", "texture:u_texture", "resourceRef", label);
    }

    // Size in pixels (100 per world unit).
    function setSize(widthPx, heightPx) {
        inspector.propertyEdited("transform", "scale", "vec3", [widthPx / 100, heightPx / 100, scale[2]]);
    }

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight + 16
    radius: 8
    color: Theme.bgTertiary
    border.color: Theme.primaryColor
    border.width: 1

    ColumnLayout {
        id: cardColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

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
                text: qsTr("Sprite")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.white

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspector.toggleExpanded("sprite")
                }
            }

            MuiIcon {
                name: "tune"
                font.pixelSize: 14
                color: Theme.grey
                ToolTip.visible: componentsArea.containsMouse
                ToolTip.text: qsTr("Show the components behind the sprite")

                MouseArea {
                    id: componentsArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspector.showGroupComponents = true
                }
            }

            MuiIcon {
                name: "delete"
                font.pixelSize: 14
                color: Theme.grey
                ToolTip.visible: removeArea.containsMouse
                ToolTip.text: qsTr("Remove the sprite (the entity keeps its transform)")

                MouseArea {
                    id: removeArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: inspector.removeSprite()
                }
            }
        }

        ColumnLayout {
            visible: section.expanded
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: qsTr("Look")
                font.pixelSize: 10
                color: Theme.darkGrey
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                AppButton {
                    Layout.fillWidth: true
                    text: qsTr("Color")
                    icon: "palette"
                    primary: !section.imageMode
                    onClicked: if (section.imageMode) section.useColor()
                }

                AppButton {
                    Layout.fillWidth: true
                    text: qsTr("Image")
                    icon: "image"
                    primary: section.imageMode
                    onClicked: {
                        if (section.imageMode) return;
                        if (section.textures.length > 0) section.useImage(section.textures[0]);
                        else importTexture.pick();
                    }
                }
            }

            // Color: a swatch, then the RGBA fields on their own row (too narrow side by side).
            Rectangle {
                visible: !section.imageMode
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                radius: 4
                border.color: Theme.borderColor
                color: Qt.rgba(section.spriteColor[0], section.spriteColor[1], section.spriteColor[2], section.spriteColor[3])
            }

            RowLayout {
                visible: !section.imageMode
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["R", "G", "B", "A"]

                    delegate: PropertyField {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        label: modelData
                        accentColor: ["#E05B5B", "#35C98A", "#4B8CE0", Theme.lightGrey][index]
                        isNumeric: true
                        minValue: 0
                        maxValue: 1
                        value: Number(section.spriteColor[index]).toFixed(2)
                        onEdited: v => {
                            const next = section.spriteColor.slice();
                            next[index] = parseFloat(v);
                            inspector.propertyEdited("mesh_renderer_properties", "color:u_color", "vec4", next);
                        }
                    }
                }
            }

            // Image
            ColumnLayout {
                visible: section.imageMode
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    ComboBox {
                        id: textureCombo
                        Layout.fillWidth: true
                        model: section.textures
                        currentIndex: section.textures.indexOf(section.texture)
                        displayText: currentIndex >= 0 ? currentText : qsTr("(pick an image)")
                        onActivated: index => section.useImage(textAt(index))
                    }

                    AppButton {
                        text: qsTr("Import...")
                        icon: "upload"
                        enabled: !importTexture.busy
                        onClicked: importTexture.pick()
                    }
                }

                Text {
                    visible: importTexture.errorText !== ""
                    Layout.fillWidth: true
                    text: importTexture.errorText
                    color: Theme.error
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: qsTr("Size (pixels)")
                font.pixelSize: 10
                color: Theme.darkGrey
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                PropertyField {
                    Layout.fillWidth: true
                    label: "W"
                    accentColor: "#E05B5B"
                    isNumeric: true
                    minValue: 1
                    value: String(Math.round(section.scale[0] * 100))
                    onEdited: v => {
                        const w = parseFloat(v);
                        const h = section.keepRatio ? w * section.scale[1] / section.scale[0] : section.scale[1] * 100;
                        section.setSize(w, h);
                    }
                }

                MuiIcon {
                    name: section.keepRatio ? "link" : "link_off"
                    font.pixelSize: 16
                    color: section.keepRatio ? Theme.primaryColor : Theme.grey
                    ToolTip.visible: ratioArea.containsMouse
                    ToolTip.text: qsTr("Keep proportions")

                    MouseArea {
                        id: ratioArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: section.keepRatio = !section.keepRatio
                    }
                }

                PropertyField {
                    Layout.fillWidth: true
                    label: "H"
                    accentColor: "#35C98A"
                    isNumeric: true
                    minValue: 1
                    value: String(Math.round(section.scale[1] * 100))
                    onEdited: v => {
                        const h = parseFloat(v);
                        const w = section.keepRatio ? h * section.scale[0] / section.scale[1] : section.scale[0] * 100;
                        section.setSize(w, h);
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Tip: drag the handles of the selection in the viewport to resize it.")
                font.pixelSize: 10
                color: Theme.grey
                wrapMode: Text.WordWrap
            }
        }
    }

    ImportTextureDialog {
        id: importTexture
        resourcesPath: inspector.resourcesPath
        scenePath: inspector.currentScenePath
        onReloadRequested: inspector.sceneReloadRequested()
        onImported: label => inspector.pendingSpriteTexture = label
    }
}
