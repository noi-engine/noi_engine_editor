import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import noi_engine_editor

// Physics in plain words: does it fall, is it solid, never moves, or is it a trigger zone. Adds
// and removes the gravity / box collider components for you. The raw components are one click
// away ("Show all components").
Rectangle {
    id: section

    property var modelData // {type: "physics", gravity, collider, transform}
    property var inspector

    function valueOf(properties, name, fallback) {
        for (const p of properties || []) {
            if (p.name === name) return p.value;
        }
        return fallback;
    }

    readonly property bool hasGravity: !!modelData.gravity
    readonly property bool hasCollider: !!modelData.collider
    readonly property var gravityProps: modelData.gravity ? modelData.gravity.properties : []
    readonly property var colliderProps: modelData.collider ? modelData.collider.properties : []

    readonly property real gravityStrength: -valueOf(gravityProps, "acceleration_y", -9.81)
    readonly property bool gravityEnabled: valueOf(gravityProps, "enabled", true) === true
    readonly property bool isStatic: valueOf(colliderProps, "is_static", false) === true
    readonly property bool isTrigger: valueOf(colliderProps, "is_trigger", false) === true
    readonly property real halfWidth: valueOf(colliderProps, "half_width", 0.5)
    readonly property real halfHeight: valueOf(colliderProps, "half_height", 0.5)
    readonly property real offsetX: valueOf(colliderProps, "offset_x", 0)
    readonly property real offsetY: valueOf(colliderProps, "offset_y", 0)
    readonly property var scale: valueOf(modelData.transform, "scale", [1, 1, 1])

    // 0 = none, 1 = solid, 2 = trigger
    readonly property int collisionMode: !hasCollider ? 0 : (isTrigger ? 2 : 1)

    function setCollisionMode(mode) {
        if (mode === 0) {
            if (hasCollider) inspector.componentRemoved("box_collider");
            return;
        }
        if (!hasCollider) {
            inspector.componentAddRequested("box_collider"); // sized to the object by the bridge
        }
        inspector.propertyEdited("box_collider", "is_trigger", "bool", mode === 2);
        if (mode === 2) inspector.propertyEdited("box_collider", "is_static", "bool", true);
    }

    function fitToObject() {
        inspector.propertyEdited("box_collider", "half_width", "float", Math.abs(scale[0]) / 2);
        inspector.propertyEdited("box_collider", "half_height", "float", Math.abs(scale[1]) / 2);
        inspector.propertyEdited("box_collider", "offset_x", "float", 0);
        inspector.propertyEdited("box_collider", "offset_y", "float", 0);
    }

    readonly property bool expanded: inspector.isExpanded("physics")

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + 24
    radius: Theme.radius
    color: Theme.bgTertiary
    border.color: Theme.borderColor

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MuiIcon {
                name: section.expanded ? "expand_more" : "chevron_right"
                font.pixelSize: 16
                color: Theme.grey
            }

            MuiIcon {
                name: "sports_basketball"
                font.pixelSize: 17
                color: Theme.primaryColor
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Physics")
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Theme.white
            }

            // The whole header folds / unfolds the card.
            TapHandler { onTapped: section.inspector.toggleExpanded("physics") }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }

        ColumnLayout {
            visible: section.expanded
            Layout.fillWidth: true
            spacing: 12
            // ---- Gravity
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: qsTr("Falls with gravity")
                        font.pixelSize: 12
                        color: Theme.white
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("It drops until it lands on something solid.")
                        font.pixelSize: 10
                        color: Theme.grey
                        wrapMode: Text.WordWrap
                    }
                }

                Switch {
                    checked: section.hasGravity
                    onToggled: {
                        if (checked) section.inspector.componentAddRequested("gravity");
                        else section.inspector.componentRemoved("gravity");
                    }
                }
            }

            NumberField {
                visible: section.hasGravity
                label: qsTr("Gravity strength (higher falls faster)")
                value: section.gravityStrength
                onEdited: number => section.inspector.propertyEdited("gravity", "acceleration_y", "float", -number)
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.borderColor }

            // ---- Collision
            Text {
                text: qsTr("Collision")
                font.pixelSize: 12
                color: Theme.white
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { mode: 0, label: qsTr("None"), icon: "block" },
                        { mode: 1, label: qsTr("Solid"), icon: "crop_square" },
                        { mode: 2, label: qsTr("Trigger"), icon: "crop_free" }
                    ]

                    delegate: AppButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 34
                        icon: modelData.icon
                        text: modelData.label
                        primary: section.collisionMode === modelData.mode
                        onClicked: section.setCollisionMode(modelData.mode)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: section.collisionMode === 0 ? qsTr("Nothing collides with it: it passes through everything.")
                    : section.collisionMode === 1 ? qsTr("Solid: things can't pass through it.")
                    : qsTr("Trigger: nothing is pushed, your scripts are told when something enters it.")
                font.pixelSize: 10
                color: Theme.grey
                wrapMode: Text.WordWrap
            }

            RowLayout {
                visible: section.collisionMode === 1
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: qsTr("Never moves")
                        font.pixelSize: 12
                        color: Theme.white
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Floors and walls: others bump into it, it stays put.")
                        font.pixelSize: 10
                        color: Theme.grey
                        wrapMode: Text.WordWrap
                    }
                }

                Switch {
                    checked: section.isStatic
                    onToggled: section.inspector.propertyEdited("box_collider", "is_static", "bool", checked)
                }
            }

            // ---- Box size
            ColumnLayout {
                visible: section.hasCollider
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: qsTr("Collision box (pixels)")
                    font.pixelSize: 11
                    color: Theme.darkGrey
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    NumberField {
                        label: qsTr("Width")
                        decimals: 1
                        value: section.halfWidth * 200
                        onEdited: number => section.inspector.propertyEdited("box_collider", "half_width", "float", Math.abs(number) / 200)
                    }

                    NumberField {
                        label: qsTr("Height")
                        decimals: 1
                        value: section.halfHeight * 200
                        onEdited: number => section.inspector.propertyEdited("box_collider", "half_height", "float", Math.abs(number) / 200)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    NumberField {
                        label: qsTr("Offset X")
                        decimals: 1
                        value: section.offsetX * 100
                        onEdited: number => section.inspector.propertyEdited("box_collider", "offset_x", "float", number / 100)
                    }

                    NumberField {
                        label: qsTr("Offset Y")
                        decimals: 1
                        value: section.offsetY * 100
                        onEdited: number => section.inspector.propertyEdited("box_collider", "offset_y", "float", number / 100)
                    }
                }

                AppButton {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    icon: "fit_screen"
                    text: qsTr("Fit to the object's size")
                    onClicked: section.fitToObject()
                }
            }
    
        }
    }
}
