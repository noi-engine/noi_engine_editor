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
    // The entity's editor groups changed (e.g. ["sprite"]).
    signal groupsChanged(var groups)

    // ---- Editor groups: components added together (a sprite) are shown as one section.
    readonly property var entityGroups: root.entity && root.entity.groups ? root.entity.groups : []
    readonly property bool isSprite: root.entityGroups.indexOf("sprite") !== -1
    // Shows the raw components behind a group instead of its section.
    property bool showGroupComponents: false
    // Image imported from the Sprite section: applied once the scene reload makes it available.
    property string pendingSpriteTexture: ""

    onEntityChanged: root.showGroupComponents = false

    onLoadedResourcesChanged: {
        if (root.pendingSpriteTexture === "" || root.resourceLabelsFor("texture").indexOf(root.pendingSpriteTexture) === -1) return;
        const label = root.pendingSpriteTexture;
        root.pendingSpriteTexture = "";
        root.propertyEdited("mesh_renderer", "material", "resourceRef", "materials:texture");
        root.propertyRemoved("mesh_renderer_properties", "color:u_color");
        root.propertyEdited("mesh_renderer_properties", "texture:u_texture", "resourceRef", label);
    }

    function sectionData(type) {
        for (const section of root.componentsData || []) {
            if (section.type === type) return section;
        }
        return null;
    }

    function removeSprite() {
        root.componentRemoved("mesh_renderer"); // the bridge removes mesh_renderer_properties with it
        root.groupsChanged(root.entityGroups.filter(g => g !== "sprite"));
    }

    // ---- Material guard
    function entityMaterial() {
        const mr = root.sectionData("mesh_renderer");
        if (!mr) return "";
        const property = (mr.properties || []).find(p => p.name === "material");
        return property ? property.value : "";
    }

    function overrideNames() {
        const mrp = root.sectionData("mesh_renderer_properties");
        return mrp ? (mrp.properties || []).map(p => p.name) : [];
    }

    // Overrides the entity's current material doesn't define.
    function unusedOverrides() {
        const mr = root.sectionData("mesh_renderer");
        if (!mr || !mr.materialProperties) return [];
        return root.overrideNames().filter(n => mr.materialProperties.indexOf(n) === -1);
    }

    // A resource picked in a property's list. Changing a Mesh Renderer's material while it has
    // Material Overrides asks what to do with them first.
    function resourceRefChosen(componentType, propertyName, label, revert) {
        const overrides = root.overrideNames();
        if (componentType === "mesh_renderer" && propertyName === "material" && root.entity !== null
            && overrides.length > 0 && label !== root.entityMaterial()) {
            materialChangeDialog.pendingLabel = label;
            materialChangeDialog.ask(root.entityMaterial(), label, overrides, revert);
            return;
        }
        root.propertyEdited(componentType, propertyName, "resourceRef", label);
    }

    // Ordered for how users actually reach for these: building blocks first, then the two
    // camera variants together, then physics together. name_component (every entity already
    // has one), mesh_renderer_properties (meaningless without a mesh_renderer - bundled
    // alongside it instead, see addComponentMenuEntries) and script_component (superseded by
    // the "Script" utility below - scripts are project-level .cpp/.hpp files, not a component
    // you hand-configure in the Inspector) are intentionally not offered as raw entries.
    readonly property var allComponentTypes: [
        "transform", "render_layer", "mesh_renderer",
        "camera_2d", "camera_3d", "orbit_camera",
        "gravity", "box_collider",
        "culling", "always_active"
    ]

    readonly property var componentLabels: ({
        "material": qsTr("Material"),
        "sprite": qsTr("Sprite"),
        "name_component": qsTr("Name"),
        "mesh_renderer_properties": qsTr("Material Overrides"),
        "script_component": qsTr("Scripts"),
        "world_matrix": qsTr("World Matrix"),
        "transform": qsTr("Transform"),
        "render_layer": qsTr("Render Layer"),
        "mesh_renderer": qsTr("Mesh Renderer"),
        "camera_2d": qsTr("Camera 2D"),
        "camera_3d": qsTr("Camera 3D"),
        "orbit_camera": qsTr("Orbit Camera"),
        "gravity": qsTr("Gravity"),
        "box_collider": qsTr("Box Collider"),
        "culling": qsTr("Culling (performance)"),
        "always_active": qsTr("Always Active (ignore culling)")
    })

    readonly property bool hasSelection: root.entity !== null || root.material !== null

    // Material mode reuses the exact same "sections of properties" rendering as entity mode
    // by wrapping its flat property list as a single synthetic "material" section.
    readonly property var effectiveComponentsData: {
        if (root.material) return [{"type": "material", "properties": root.materialProperties}];
        if (!root.isSprite || root.showGroupComponents || !root.sectionData("mesh_renderer")) return root.componentsData;
        const sprite = {
            "type": "sprite",
            "meshRenderer": root.sectionData("mesh_renderer").properties,
            "overrides": (root.sectionData("mesh_renderer_properties") || {properties: []}).properties,
            "transform": (root.sectionData("transform") || {properties: []}).properties
        };
        return [sprite].concat((root.componentsData || [])
            .filter(c => c.type !== "mesh_renderer" && c.type !== "mesh_renderer_properties"));
    }

    readonly property string headerTitle: root.material
        ? (root.material.label !== "" ? root.material.label : ("Material #" + root.material.id))
        : (root.entity ? (root.entity.name !== "" ? root.entity.name : ("Entity #" + root.entity.id)) : "")

    readonly property string headerSubtitle: root.material
        ? qsTr("#%1 / gen %2").arg(root.material.id).arg(root.material.generation)
        : (root.entity ? qsTr("#%1 / gen %2").arg(root.entity.id).arg(root.entity.generation) : "")

    readonly property string headerIcon: root.material ? "palette" : "category"

    // Only existing resources: the bridge refuses empty or unknown references.
    function resourceLabelsFor(resourceType) {
        const items = root.loadedResources || [];
        const labels = [];
        for (let i = 0; i < items.length; i++) {
            // Unnamed resources (e.g. the editor's camera border material) can't be referenced.
            if (items[i].type === resourceType && items[i].label !== "") {
                labels.push(items[i].label);
            }
        }
        return labels;
    }

    function missingComponentTypes() {
        return root.availableComponentTypes()
            .filter(t => root.showAdvancedComponents || !root.isAdvancedComponent(t));
    }

    function availableComponentTypes() {
        const present = (root.componentsData || []).map(c => c.type);
        return root.allComponentTypes.filter(t => present.indexOf(t) === -1)
            // The scene camera is 2D: a 3D camera component would replace its view.
            .filter(t => !(root.isCameraEntity && (t === "camera_3d" || t === "orbit_camera")))
            // Culling follows the scene camera's view; the camera itself is always active.
            .filter(t => t !== "culling" || root.isCameraEntity)
            .filter(t => t !== "always_active" || !root.isCameraEntity);
    }

    // Components rarely useful in a 2D scene (3D cameras, a second 2D camera on a regular
    // entity): hidden from Add Component unless "Show advanced components" is on.
    property bool showAdvancedComponents: false

    function isAdvancedComponent(type) {
        if (type === "camera_3d" || type === "orbit_camera") return true;
        return type === "camera_2d" && !root.isCameraEntity;
    }

    function hiddenAdvancedCount() {
        return root.showAdvancedComponents ? 0 : root.availableComponentTypes().filter(t => root.isAdvancedComponent(t)).length;
    }

    function hasComponent(type) {
        return (root.componentsData || []).some(c => c.type === type);
    }

    // Why a component can't be removed ("" = it can). Mirrors the bridge's own checks.
    function removeBlockedReason(type) {
        if (type === "name_component") return qsTr("Every entity has a name");
        if (type === "world_matrix") return qsTr("Computed by the engine from the transform");
        if (root.isCameraEntity && type === "camera_2d") return qsTr("The scene camera needs it");
        if (type === "transform") {
            if (root.isCameraEntity) return qsTr("The scene camera needs it");
            const users = ["mesh_renderer", "box_collider", "gravity"].filter(t => root.hasComponent(t));
            if (users.length > 0) {
                return qsTr("Used by %1 - remove it first").arg(users.map(t => root.sectionTitle(t)).join(", "));
            }
        }
        return "";
    }

    // "Sprite" and "Script" are not real bridge component types - they're utilities:
    // - Sprite is a one-click convenience that adds transform + mesh_renderer +
    //   mesh_renderer_properties together (optionally wired to a texture, see
    //   AddSpriteDialog), so users don't have to assemble the raw pieces by hand. Offered
    //   whenever mesh_renderer isn't already present.
    // - Script scaffolds a new project-level script file pair and is always offered - it
    //   isn't "added" to this entity at all (see AddScriptDialog).
    // Groups first (several components set up together), then single components.
    function addComponentMenuEntries() {
        const utilities = [];
        if (!root.hasComponent("mesh_renderer")) utilities.push("sprite");
        if (!root.hasComponent("box_collider")) utilities.push("static_collider");
        if (!root.hasComponent("box_collider") && !root.hasComponent("gravity")) utilities.push("physics_body");
        utilities.push("script");
        return utilities.concat(missingComponentTypes());
    }

    function addComponentMenuLabel(type) {
        if (type === "sprite") return qsTr("Sprite (transform + mesh + material)");
        if (type === "static_collider") return qsTr("Static Collider (doesn't move)");
        if (type === "physics_body") return qsTr("Physics Body (gravity + collider)");
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

    function sectionTitle(componentType) {
        return root.componentLabels[componentType] || componentType;
    }

    // Which sections are open, by component type. Kept here (not in the delegates, which are
    // rebuilt whenever the inspected data changes) so they stay open while editing and
    // across entities. Unset = default: only the material section starts open.
    property var expandedSections: ({})

    function isExpanded(componentType) {
        const value = root.expandedSections[componentType];
        return value === undefined ? componentType === "material" : value;
    }

    function toggleExpanded(componentType) {
        const next = Object.assign({}, root.expandedSections);
        next[componentType] = !root.isExpanded(componentType);
        root.expandedSections = next;
    }

    function setAllExpanded(expanded) {
        const next = {};
        for (const section of root.effectiveComponentsData) {
            next[section.type] = expanded;
        }
        root.expandedSections = Object.assign({}, root.expandedSections, next);
    }

    function openAddProperty(componentType, existingNames) {
        addPropertyPopup.componentType = componentType;
        addPropertyPopup.existingNames = existingNames;
        addPropertyPopup.open();
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

    ColumnLayout {
        visible: root.hasSelection
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
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

            MuiIcon {
                name: "unfold_more"
                font.pixelSize: 16
                color: Theme.grey
                ToolTip.visible: expandAllArea.containsMouse
                ToolTip.text: qsTr("Expand all")

                MouseArea {
                    id: expandAllArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setAllExpanded(true)
                }
            }

            MuiIcon {
                name: "unfold_less"
                font.pixelSize: 16
                color: Theme.grey
                ToolTip.visible: collapseAllArea.containsMouse
                ToolTip.text: qsTr("Collapse all")

                MouseArea {
                    id: collapseAllArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setAllExpanded(false)
                }
            }
        }

        PanelSearchField {
            id: searchField
            placeholderText: qsTr("Search components or properties...")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: width
            contentHeight: column.implicitHeight

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: column

                readonly property int visibleSections: {
                    let count = 0;
                    for (let i = 0; i < column.children.length; i++) {
                        const child = column.children[i];
                        if (child.item && child.item.visible) count++;
                    }
                    return count;
                }

                width: parent.width
                spacing: 8

                Text {
                    visible: root.isSprite && root.showGroupComponents
                    Layout.fillWidth: true
                    text: qsTr("Showing the components behind the sprite. <a href=\"back\">Back to the Sprite section</a>")
                    textFormat: Text.RichText
                    font.pixelSize: 10
                    color: Theme.grey
                    linkColor: Theme.primaryColor
                    wrapMode: Text.WordWrap
                    onLinkActivated: root.showGroupComponents = false
                }

                Repeater {
                    model: root.effectiveComponentsData

                    delegate: Loader {
                        id: sectionLoader

                        required property var modelData

                        Layout.fillWidth: true
                        visible: item ? item.visible : true
                        sourceComponent: modelData.type === "sprite" ? spriteSection : componentSection

                        Component {
                            id: componentSection
                            ComponentSection {
                                modelData: sectionLoader.modelData
                                inspector: root
                                query: searchField.text.trim().toLowerCase()
                            }
                        }

                        Component {
                            id: spriteSection
                            SpriteSection {
                                modelData: sectionLoader.modelData
                                inspector: root
                            }
                        }
                    }
                }

                Text {
                    visible: searchField.text.trim() !== "" && column.visibleSections === 0
                    Layout.fillWidth: true
                    text: qsTr("Nothing matches \"%1\"").arg(searchField.text.trim())
                    font.pixelSize: 11
                    font.italic: true
                    color: Theme.grey
                    wrapMode: Text.Wrap
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
                                    } else if (addComponentMenuItem.modelData === "static_collider") {
                                        root.componentAddRequested("box_collider");
                                        root.propertyEdited("box_collider", "is_static", "bool", true);
                                    } else if (addComponentMenuItem.modelData === "physics_body") {
                                        root.componentAddRequested("gravity");
                                        root.componentAddRequested("box_collider");
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

                        MenuSeparator {
                            visible: root.hiddenAdvancedCount() > 0 || root.showAdvancedComponents
                        }

                        MenuItem {
                            visible: root.hiddenAdvancedCount() > 0 || root.showAdvancedComponents
                            height: visible ? implicitHeight : 0
                            text: root.showAdvancedComponents
                                ? qsTr("Hide advanced components")
                                : qsTr("Show advanced components (%1 hidden)").arg(root.hiddenAdvancedCount())
                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 11
                                font.italic: true
                                color: Theme.grey
                                leftPadding: 8
                                verticalAlignment: Text.AlignVCenter
                            }
                            onTriggered: {
                                root.showAdvancedComponents = !root.showAdvancedComponents;
                                addComponentMenu.open();
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 10 }
            }
        }
    }

    AddPropertyPopup {
        id: addPropertyPopup
        inspector: root
    }

    MaterialChangeDialog {
        id: materialChangeDialog
        property string pendingLabel: ""

        onKeepAndChange: root.propertyEdited("mesh_renderer", "material", "resourceRef", pendingLabel)
        onRemoveAndChange: {
            for (const name of overrides) root.propertyRemoved("mesh_renderer_properties", name);
            root.propertyEdited("mesh_renderer", "material", "resourceRef", pendingLabel);
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
            root.groupsChanged(root.entityGroups.concat(["sprite"]));
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
