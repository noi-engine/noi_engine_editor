import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

Rectangle {
    id: root

    property var entity: null
    property var componentsData: []
    property var loadedResources: []
    property string resourcesPath: ""
    property string currentScenePath: ""

    signal sceneReloadRequested()
    property var material: null
    property var materialProperties: []

    signal propertyEdited(string componentType, string propertyName, string propertyType, var value)
    signal componentAddRequested(string componentType)
    signal componentRemoved(string componentType)
    signal propertyRemoved(string componentType, string propertyName)

    // Ordered for how users actually reach for these: building blocks first, then the two
    // camera variants together, then physics together. name_component (every entity already
    // has one), mesh_renderer_properties (meaningless without a mesh_renderer - bundled
    // alongside it instead, see addComponentMenuEntries) and script_component (superseded by
    // the "Script" utility below - scripts are project-level .cpp/.hpp files, not a component
    // you hand-configure in the Inspector) are intentionally not offered as raw entries.
    readonly property var allComponentTypes: [
        "transform", "render_layer", "mesh_renderer",
        "camera_2d", "camera_3d", "orbit_camera",
        "gravity", "box_collider"
    ]

    readonly property var componentLabels: ({
        "transform": qsTr("Transform"),
        "render_layer": qsTr("Render Layer"),
        "mesh_renderer": qsTr("Mesh Renderer"),
        "camera_2d": qsTr("Camera 2D"),
        "camera_3d": qsTr("Camera 3D"),
        "orbit_camera": qsTr("Orbit Camera"),
        "gravity": qsTr("Gravity"),
        "box_collider": qsTr("Box Collider")
    })

    readonly property bool hasSelection: root.entity !== null || root.material !== null

    // Material mode reuses the exact same "sections of properties" rendering as entity mode
    // by wrapping its flat property list as a single synthetic "material" section.
    readonly property var effectiveComponentsData: root.material
        ? [{"type": "material", "properties": root.materialProperties}]
        : root.componentsData

    readonly property string headerTitle: root.material
        ? (root.material.label !== "" ? root.material.label : ("Material #" + root.material.id))
        : (root.entity ? (root.entity.name !== "" ? root.entity.name : ("Entity #" + root.entity.id)) : "")

    readonly property string headerSubtitle: root.material
        ? qsTr("#%1 / gen %2").arg(root.material.id).arg(root.material.generation)
        : (root.entity ? qsTr("#%1 / gen %2").arg(root.entity.id).arg(root.entity.generation) : "")

    readonly property string headerIcon: root.material ? "palette" : "category"

    function resourceLabelsFor(resourceType) {
        const items = root.loadedResources || [];
        const labels = [""];
        for (let i = 0; i < items.length; i++) {
            if (items[i].type === resourceType) {
                labels.push(items[i].label);
            }
        }
        return labels;
    }

    function missingComponentTypes() {
        const present = (root.componentsData || []).map(c => c.type);
        return root.allComponentTypes.filter(t => present.indexOf(t) === -1);
    }

    // "Sprite" and "Script" are not real bridge component types - they're utilities:
    // - Sprite is a one-click convenience that adds transform + mesh_renderer +
    //   mesh_renderer_properties together (optionally wired to a texture, see
    //   AddSpriteDialog), so users don't have to assemble the raw pieces by hand. Offered
    //   whenever mesh_renderer isn't already present.
    // - Script scaffolds a new project-level script file pair and is always offered - it
    //   isn't "added" to this entity at all (see AddScriptDialog).
    function addComponentMenuEntries() {
        const present = (root.componentsData || []).map(c => c.type);
        const utilities = present.indexOf("mesh_renderer") === -1 ? ["sprite", "script"] : ["script"];
        return utilities.concat(missingComponentTypes());
    }

    function addComponentMenuLabel(type) {
        if (type === "sprite") return qsTr("Sprite");
        if (type === "script") return qsTr("Script");
        return root.componentLabels[type] || type;
    }

    // mesh_renderer/mesh_renderer_properties on the camera entity is the red border gizmo
    // injected by the editor's own preview (see bridge_game::set_scene_2d()) - not something
    // the user added, and never written back to the scene file on save. It should stay visible
    // (so its presence isn't mysterious) but not editable, and not a candidate for "Add Property".
    readonly property bool isCameraEntity: root.entity !== null && root.entity.name === "main_camera"

    function isEditorManaged(componentType) {
        return root.isCameraEntity && (componentType === "mesh_renderer" || componentType === "mesh_renderer_properties");
    }

    // Property names on mesh_renderer_properties/material sections are stored with a
    // "param:"/"color:"/"texture:" prefix (see bridge_game_entities.cpp /
    // bridge_game_resources.cpp) so set_component_property can route by kind - strip it for
    // display, keep the full name for the propertyEdited signal.
    function displayName(fullName) {
        const idx = fullName.indexOf(":");
        if (idx === -1) return fullName;
        const prefix = fullName.substring(0, idx);
        if (prefix === "color" || prefix === "param" || prefix === "texture") {
            return fullName.substring(idx + 1);
        }
        return fullName;
    }

    // Same prefix check as displayName() - true for the dynamic param:/color:/texture: entries
    // that "Add Property" can create (and that can therefore also be removed), false for a
    // component's own fixed fields (e.g. transform.position).
    function isDynamicProperty(fullName) {
        const idx = fullName.indexOf(":");
        if (idx === -1) return false;
        const prefix = fullName.substring(0, idx);
        return prefix === "color" || prefix === "param" || prefix === "texture";
    }

    // Known value constraints for built-in engine components, applied via PropertyField's
    // validator props. Anything not listed here just gets isNumeric:true (reject non-numeric
    // input) with no range bound.
    readonly property var fieldConstraints: ({
        "render_layer.order": { integer: true },
        "camera_2d.zoom": { min: 0.0001 },
        "camera_2d.orthographic_size": { min: 0.0001 },
        "camera_2d.aspect_ratio": { min: 0.0001 },
        "camera_3d.fov": { min: 1, max: 179 },
        "camera_3d.near_plane": { min: 0.0001 },
        "camera_3d.far_plane": { min: 0.0001 },
        "camera_3d.aspect_ratio": { min: 0.0001 },
        "orbit_camera.distance": { min: 0 },
        "orbit_camera.min_distance": { min: 0 },
        "orbit_camera.max_distance": { min: 0 },
        "orbit_camera.sensitivity": { min: 0 },
        "orbit_camera.zoom_speed": { min: 0 },
        "orbit_camera.min_pitch": { min: -89, max: 89 },
        "orbit_camera.max_pitch": { min: -89, max: 89 }
    })

    function constraintFor(componentType, propertyName) {
        return root.fieldConstraints[componentType + "." + propertyName] || {};
    }

    // Section types that hold dynamic, addable param:/color:/texture: maps (as opposed to a
    // fixed set of fields like transform or camera_2d).
    function supportsAddProperty(componentType) {
        return componentType === "mesh_renderer_properties" || componentType === "material";
    }

    color: Theme.bgSecondary

    Rectangle {
        anchors.left: parent.left
        width: 1
        height: parent.height
        color: Theme.borderColor
    }

    EmptyState {
        visible: !root.hasSelection

        anchors.centerIn: parent
        width: parent.width - 24

        icon: "ads_click"
        title: qsTr("No Selection")
        description: qsTr("Select an entity in the hierarchy, or a material in Loaded Resources, to inspect its properties.")
    }

    Flickable {
        visible: root.hasSelection

        anchors.fill: parent
        anchors.margins: 14

        contentWidth: width
        contentHeight: column.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column

            width: parent.width
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 10

                IconBadge {
                    icon: root.headerIcon
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: root.headerTitle
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: Theme.white
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.headerSubtitle
                        font.pixelSize: 11
                        color: Theme.grey
                    }
                }
            }

            Repeater {
                model: root.effectiveComponentsData

                delegate: Rectangle {
                    id: componentSection

                    required property var modelData
                    readonly property string componentType: componentSection.modelData.type
                    readonly property var componentProperties: componentSection.modelData.properties
                    readonly property bool forcedReadOnly: root.isEditorManaged(componentSection.componentType)

                    Layout.fillWidth: true
                    implicitHeight: cardColumn.implicitHeight + 24
                    radius: 8
                    color: Theme.bgTertiary
                    border.color: Theme.borderColor
                    border.width: 1

                    ColumnLayout {
                        id: cardColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: componentSection.componentType.toUpperCase()
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.5
                                color: Theme.primaryColor
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: componentSection.forcedReadOnly
                                text: qsTr("editor-managed · not saved")
                                font.pixelSize: 9
                                font.italic: true
                                color: Theme.grey
                            }

                            MuiIcon {
                                name: "delete"
                                font.pixelSize: 14
                                color: Theme.grey
                                visible: root.entity !== null && componentSection.componentType !== "name_component"
                                    && !componentSection.forcedReadOnly

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.componentRemoved(componentSection.componentType)
                                }
                            }
                        }

                        Repeater {
                            model: componentSection.componentProperties

                            delegate: Item {
                                id: propRow

                                required property var modelData
                                readonly property bool effectiveReadOnly: propRow.modelData.readOnly || componentSection.forcedReadOnly

                                Layout.fillWidth: true
                                implicitHeight: propColumn.implicitHeight

                                ColumnLayout {
                                    id: propColumn
                                    width: parent.width
                                    spacing: 6

                                    RowLayout {
                                        visible: propRow.modelData.type !== "bool" && propRow.modelData.type !== "vec4"
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.displayName(propRow.modelData.name)
                                            font.pixelSize: 10
                                            color: Theme.darkGrey
                                        }

                                        MuiIcon {
                                            name: "delete"
                                            font.pixelSize: 12
                                            color: Theme.grey
                                            visible: root.supportsAddProperty(componentSection.componentType)
                                                && root.isDynamicProperty(propRow.modelData.name)
                                                && !propRow.effectiveReadOnly

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.propertyRemoved(componentSection.componentType, propRow.modelData.name)
                                            }
                                        }
                                    }

                                    RowLayout {
                                        visible: propRow.modelData.type === "vec3"
                                        Layout.fillWidth: true
                                        spacing: 6

                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "X"
                                            accentColor: "#E05B5B"
                                            readOnly: propRow.effectiveReadOnly
                                            isNumeric: true
                                            value: Number(propRow.modelData.value[0]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                                [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2]])
                                        }
                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "Y"
                                            accentColor: "#35C98A"
                                            readOnly: propRow.effectiveReadOnly
                                            isNumeric: true
                                            value: Number(propRow.modelData.value[1]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                                [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2]])
                                        }
                                        PropertyField {
                                            Layout.fillWidth: true
                                            label: "Z"
                                            accentColor: "#4B8CE0"
                                            readOnly: propRow.effectiveReadOnly
                                            isNumeric: true
                                            value: Number(propRow.modelData.value[2]).toFixed(2)
                                            onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec3",
                                                [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v)])
                                        }
                                    }

                                    // Color (vec4): swatch + stripped name on their own row, RGBA fields
                                    // on a second full-width row - packing swatch+4 fields into one row
                                    // left each TextField too narrow to show its value.
                                    ColumnLayout {
                                        visible: propRow.modelData.type === "vec4"
                                        Layout.fillWidth: true
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: 32
                                                Layout.preferredHeight: 32
                                                radius: 8
                                                border.color: Theme.borderColor
                                                border.width: 1
                                                color: propRow.modelData.type === "vec4"
                                                    ? Qt.rgba(propRow.modelData.value[0], propRow.modelData.value[1],
                                                              propRow.modelData.value[2], propRow.modelData.value[3])
                                                    : "transparent"
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: root.displayName(propRow.modelData.name)
                                                font.pixelSize: 11
                                                color: Theme.darkGrey
                                                elide: Text.ElideRight
                                            }

                                            MuiIcon {
                                                name: "delete"
                                                font.pixelSize: 12
                                                color: Theme.grey
                                                visible: root.supportsAddProperty(componentSection.componentType)
                                                    && root.isDynamicProperty(propRow.modelData.name)
                                                    && !propRow.effectiveReadOnly

                                                MouseArea {
                                                    anchors.fill: parent
                                                    anchors.margins: -4
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.propertyRemoved(componentSection.componentType, propRow.modelData.name)
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            PropertyField {
                                                Layout.fillWidth: true
                                                label: "R"
                                                accentColor: "#E05B5B"
                                                readOnly: propRow.effectiveReadOnly
                                                isNumeric: true
                                                minValue: 0
                                                maxValue: 1
                                                value: Number(propRow.modelData.value[0]).toFixed(2)
                                                onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                    [parseFloat(v), propRow.modelData.value[1], propRow.modelData.value[2], propRow.modelData.value[3]])
                                            }
                                            PropertyField {
                                                Layout.fillWidth: true
                                                label: "G"
                                                accentColor: "#35C98A"
                                                readOnly: propRow.effectiveReadOnly
                                                isNumeric: true
                                                minValue: 0
                                                maxValue: 1
                                                value: Number(propRow.modelData.value[1]).toFixed(2)
                                                onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                    [propRow.modelData.value[0], parseFloat(v), propRow.modelData.value[2], propRow.modelData.value[3]])
                                            }
                                            PropertyField {
                                                Layout.fillWidth: true
                                                label: "B"
                                                accentColor: "#4B8CE0"
                                                readOnly: propRow.effectiveReadOnly
                                                isNumeric: true
                                                minValue: 0
                                                maxValue: 1
                                                value: Number(propRow.modelData.value[2]).toFixed(2)
                                                onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                    [propRow.modelData.value[0], propRow.modelData.value[1], parseFloat(v), propRow.modelData.value[3]])
                                            }
                                            PropertyField {
                                                Layout.fillWidth: true
                                                label: "A"
                                                accentColor: Theme.lightGrey
                                                readOnly: propRow.effectiveReadOnly
                                                isNumeric: true
                                                minValue: 0
                                                maxValue: 1
                                                value: Number(propRow.modelData.value[3]).toFixed(2)
                                                onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name, "vec4",
                                                    [propRow.modelData.value[0], propRow.modelData.value[1], propRow.modelData.value[2], parseFloat(v)])
                                            }
                                        }
                                    }

                                    ComboBox {
                                        id: resourceCombo
                                        visible: propRow.modelData.type === "resourceRef"
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        enabled: !propRow.effectiveReadOnly

                                        model: root.resourceLabelsFor(propRow.modelData.resourceType)
                                        displayText: currentText !== "" ? currentText : qsTr("(none)")

                                        Component.onCompleted: currentIndex = find(propRow.modelData.value)

                                        onActivated: (index) => root.propertyEdited(componentSection.componentType,
                                            propRow.modelData.name, "resourceRef", textAt(index))

                                        background: Rectangle {
                                            radius: 6
                                            color: Theme.bgPrimary
                                            border.color: resourceCombo.activeFocus ? Theme.primaryColor : Theme.borderColor
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            leftPadding: 10
                                            rightPadding: 24
                                            text: resourceCombo.displayText
                                            font.pixelSize: 12
                                            font.italic: resourceCombo.currentText === ""
                                            color: resourceCombo.enabled ? (resourceCombo.currentText !== "" ? Theme.white : Theme.grey) : Theme.lightGrey
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        indicator: MuiIcon {
                                            x: resourceCombo.width - width - 8
                                            y: (resourceCombo.height - height) / 2
                                            name: "expand_more"
                                            font.pixelSize: 16
                                            color: Theme.grey
                                        }

                                        popup.background: Rectangle {
                                            color: Theme.bgTertiary
                                            border.color: Theme.borderColor
                                            border.width: 1
                                            radius: 6
                                        }

                                        delegate: ItemDelegate {
                                            width: resourceCombo.width
                                            highlighted: resourceCombo.highlightedIndex === index

                                            contentItem: Text {
                                                text: modelData !== "" ? modelData : qsTr("(none)")
                                                font.pixelSize: 12
                                                font.italic: modelData === ""
                                                color: Theme.white
                                                elide: Text.ElideRight
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            background: Rectangle {
                                                color: highlighted ? Theme.primaryLightC : "transparent"
                                            }
                                        }

                                        MouseArea {
                                            // ComboBox changes its value on mouse wheel by default (Qt Quick
                                            // Controls' QQuickComboBox::wheelEvent), which fires just from
                                            // scrolling the Inspector past it - not what a "click to pick a
                                            // value" control should do. acceptedButtons: Qt.NoButton makes
                                            // this MouseArea ignore presses (they fall through to the
                                            // ComboBox underneath, so clicking still opens it normally) while
                                            // still intercepting - and swallowing - wheel events.
                                            anchors.fill: parent
                                            acceptedButtons: Qt.NoButton
                                            onWheel: (wheel) => wheel.accepted = true
                                        }
                                    }

                                    PropertyField {
                                        visible: propRow.modelData.type === "float" || propRow.modelData.type === "string"
                                        Layout.fillWidth: true
                                        label: root.displayName(propRow.modelData.name).substring(0, 1).toUpperCase()
                                        accentColor: Theme.lightGrey
                                        readOnly: propRow.effectiveReadOnly
                                        isNumeric: propRow.modelData.type === "float"
                                        integerValue: propRow.modelData.type === "float"
                                            && !!root.constraintFor(componentSection.componentType, propRow.modelData.name).integer
                                        minValue: propRow.modelData.type === "float"
                                            ? (root.constraintFor(componentSection.componentType, propRow.modelData.name).min ?? NaN)
                                            : NaN
                                        maxValue: propRow.modelData.type === "float"
                                            ? (root.constraintFor(componentSection.componentType, propRow.modelData.name).max ?? NaN)
                                            : NaN
                                        value: propRow.modelData.type === "float"
                                            ? (integerValue ? String(Math.round(propRow.modelData.value)) : Number(propRow.modelData.value).toFixed(3))
                                            : String(propRow.modelData.value)
                                        onEdited: (v) => root.propertyEdited(componentSection.componentType, propRow.modelData.name,
                                            propRow.modelData.type, propRow.modelData.type === "float" ? parseFloat(v) : v)
                                    }

                                    RowLayout {
                                        visible: propRow.modelData.type === "bool"
                                        Layout.fillWidth: true
                                        spacing: 8

                                        CheckBox {
                                            checked: !!propRow.modelData.value
                                            enabled: !propRow.effectiveReadOnly
                                            onToggled: root.propertyEdited(componentSection.componentType, propRow.modelData.name, "bool", checked)
                                        }
                                        Text {
                                            text: root.displayName(propRow.modelData.name)
                                            font.pixelSize: 11
                                            color: Theme.darkGrey
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: componentSection.componentProperties.length === 0
                            text: qsTr("No editable fields")
                            font.pixelSize: 10
                            font.italic: true
                            color: Theme.grey
                        }

                        Rectangle {
                            visible: root.supportsAddProperty(componentSection.componentType) && !componentSection.forcedReadOnly
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            Layout.preferredHeight: addPropertyRow.implicitHeight + 12
                            radius: 6
                            color: "transparent"
                            border.color: Theme.borderColor
                            border.width: 1

                            RowLayout {
                                id: addPropertyRow
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                MuiIcon {
                                    name: "add"
                                    font.pixelSize: 14
                                    color: Theme.grey
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Add Property")
                                    font.pixelSize: 11
                                    color: Theme.grey
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addPropertyPopup.componentType = componentSection.componentType
                                    addPropertyPopup.existingNames = componentSection.componentProperties.map(p => p.name)
                                    addPropertyPopup.open()
                                }
                            }
                        }
                    }
                }
            }

            AppButton {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.entity !== null && root.addComponentMenuEntries().length > 0

                icon: "add_circle"
                text: qsTr("Add Component")

                onClicked: addComponentMenu.open()

                Menu {
                    id: addComponentMenu
                    y: parent.height

                    background: Rectangle {
                        implicitWidth: 200
                        color: Theme.bgTertiary
                        border.color: Theme.borderColor
                        border.width: 1
                        radius: 6
                    }

                    Repeater {
                        model: root.addComponentMenuEntries()

                        delegate: MenuItem {
                            id: addComponentMenuItem
                            required property string modelData

                            text: root.addComponentMenuLabel(addComponentMenuItem.modelData)
                            width: addComponentMenu.width

                            contentItem: Text {
                                text: root.addComponentMenuLabel(addComponentMenuItem.modelData)
                                font.pixelSize: 12
                                color: Theme.white
                                leftPadding: 8
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: addComponentMenuItem.highlighted ? Theme.primaryLightC : "transparent"
                            }

                            onTriggered: {
                                if (addComponentMenuItem.modelData === "sprite") {
                                    addSpriteDialog.open();
                                } else if (addComponentMenuItem.modelData === "script") {
                                    addScriptDialog.open();
                                } else if (addComponentMenuItem.modelData === "mesh_renderer") {
                                    // mesh_renderer_properties is meaningless on its own - always
                                    // bundled with mesh_renderer instead of offered separately.
                                    root.componentAddRequested("mesh_renderer");
                                    root.componentAddRequested("mesh_renderer_properties");
                                } else {
                                    root.componentAddRequested(addComponentMenuItem.modelData);
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }
        }
    }

    Popup {
        id: addPropertyPopup

        property string componentType: ""
        property var existingNames: []

        // Textures have no default/builtin fallback the way meshes and materials do (there is
        // no "always exists" texture) - a new texture *property* is only useful once it points
        // at a real, already-loaded texture resource, so unlike Parameter/Color it can't ship
        // with a safe placeholder default. Populated fresh each time the popup opens.
        readonly property var availableTextures: root.resourceLabelsFor("texture").filter(l => l !== "")
        readonly property bool isTextureKind: addPropertyPopup.kinds[kindCombo.currentIndex]
            ? addPropertyPopup.kinds[kindCombo.currentIndex].prefix === "texture"
            : false

        // A freshly-imported texture only shows up in availableTextures once the scene reload
        // triggered by ImportTextureDialog actually completes (a few render frames later, not
        // synchronously with its imported() signal) - remember which label to select and apply
        // it once the list catches up.
        property string pendingTextureSelect: ""
        onAvailableTexturesChanged: {
            if (addPropertyPopup.pendingTextureSelect === "") return;
            const idx = addPropertyPopup.availableTextures.indexOf(addPropertyPopup.pendingTextureSelect);
            if (idx !== -1) {
                textureCombo.currentIndex = idx;
                addPropertyPopup.pendingTextureSelect = "";
            }
        }

        readonly property var kinds: [
            { label: qsTr("Parameter"), prefix: "param", propertyType: "float", defaultValue: 0.0 },
            { label: qsTr("Color"), prefix: "color", propertyType: "vec4", defaultValue: [1, 1, 1, 1] },
            { label: qsTr("Texture"), prefix: "texture", propertyType: "resourceRef" }
        ]

        function fullName(kindIndex, name) {
            return addPropertyPopup.kinds[kindIndex].prefix + ":" + name;
        }

        function nameTaken(kindIndex, name) {
            const candidate = addPropertyPopup.fullName(kindIndex, name);
            return addPropertyPopup.existingNames.indexOf(candidate) !== -1;
        }

        modal: true
        anchors.centerIn: Overlay.overlay
        width: 300

        onOpened: {
            kindCombo.currentIndex = 0
            nameInput.text = ""
            nameInput.forceActiveFocus()
            addPropertyPopup.pendingTextureSelect = ""
            popupImportTexture.errorText = ""
        }

        background: Rectangle {
            color: Theme.bgTertiary
            border.color: Theme.borderColor
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Text {
                text: qsTr("Add Property")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.white
            }

            ComboBox {
                id: kindCombo
                Layout.fillWidth: true
                model: addPropertyPopup.kinds.map(k => k.label)
            }

            TextField {
                id: nameInput
                Layout.fillWidth: true
                placeholderText: qsTr("name")
                selectByMouse: true
                color: Theme.white
            }

            // A texture property is only meaningful pointing at a real, already-loaded texture -
            // there's no safe placeholder to fall back to (unlike Parameter's 0.0 or Color's
            // white), so require picking one instead of silently defaulting to an empty/unknown
            // reference (that used to crash the renderer on an invalid handle - see
            // resource_manager::get() and material::apply() in noi_engine).
            ColumnLayout {
                Layout.fillWidth: true
                visible: addPropertyPopup.isTextureKind
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ComboBox {
                        id: textureCombo
                        Layout.fillWidth: true
                        visible: addPropertyPopup.availableTextures.length > 0
                        model: addPropertyPopup.availableTextures
                    }

                    AppButton {
                        text: qsTr("Import...")
                        enabled: !popupImportTexture.busy
                        onClicked: popupImportTexture.pick()
                    }
                }

                Text {
                    visible: addPropertyPopup.availableTextures.length === 0 && popupImportTexture.errorText === ""
                    text: qsTr("No textures loaded yet - import an image to make one available.")
                    color: Theme.grey
                    font.pixelSize: 10
                    font.italic: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    visible: popupImportTexture.errorText !== ""
                    text: popupImportTexture.errorText
                    color: Theme.error
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            ImportTextureDialog {
                id: popupImportTexture
                resourcesPath: root.resourcesPath
                scenePath: root.currentScenePath
                onReloadRequested: root.sceneReloadRequested()
                onImported: (label) => {
                    const idx = addPropertyPopup.availableTextures.indexOf(label);
                    if (idx !== -1) {
                        textureCombo.currentIndex = idx;
                    } else {
                        addPropertyPopup.pendingTextureSelect = label;
                    }
                }
            }

            Text {
                readonly property bool empty: nameInput.text.trim() === ""
                readonly property bool taken: !empty && addPropertyPopup.nameTaken(kindCombo.currentIndex, nameInput.text.trim())
                visible: taken
                text: qsTr("A property with that name already exists.")
                color: Theme.error
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("Cancel")
                    onClicked: addPropertyPopup.close()
                }

                AppButton {
                    text: qsTr("Add")
                    enabled: nameInput.text.trim() !== ""
                        && !addPropertyPopup.nameTaken(kindCombo.currentIndex, nameInput.text.trim())
                        && (!addPropertyPopup.isTextureKind || addPropertyPopup.availableTextures.length > 0)
                    onClicked: {
                        const kind = addPropertyPopup.kinds[kindCombo.currentIndex]
                        const name = nameInput.text.trim()
                        const value = addPropertyPopup.isTextureKind ? textureCombo.currentText : kind.defaultValue
                        root.propertyEdited(addPropertyPopup.componentType, addPropertyPopup.fullName(kindCombo.currentIndex, name),
                            kind.propertyType, value)
                        addPropertyPopup.close()
                    }
                }
            }
        }
    }

    AddSpriteDialog {
        id: addSpriteDialog

        textureLabels: root.resourceLabelsFor("texture").filter(l => l !== "")
        resourcesPath: root.resourcesPath
        scenePath: root.currentScenePath
        onReloadRequested: root.sceneReloadRequested()

        onConfirmed: (textureLabel) => {
            root.componentAddRequested("transform");
            root.componentAddRequested("mesh_renderer");
            root.componentAddRequested("mesh_renderer_properties");
            if (textureLabel !== "") {
                root.propertyEdited("mesh_renderer", "material", "resourceRef", "materials:texture");
                root.propertyEdited("mesh_renderer_properties", "texture:u_texture", "resourceRef", textureLabel);
            }
        }
    }

    AddScriptDialog {
        id: addScriptDialog
    }
}
