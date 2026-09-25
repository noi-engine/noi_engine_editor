import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// Scaffolds a new project-level script (sources/scripts/<name>_script.hpp/.cpp) from the
// same skeleton player_script/camera_script already follow. Not tied to any entity - there's
// no in-app code editor yet, so this only creates the files and tells the user where they
// are; wiring the new script into scripts_register.cpp/CMakeLists.txt and rebuilding is still
// a manual step.
Dialog {
    id: root

    readonly property string scriptsFolder: CurrentProjectManager.path + "/sources/scripts"
    readonly property string trimmedName: nameInput.text.trim()
    readonly property bool validName: /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(root.trimmedName)
    readonly property string className: root.trimmedName + "_script"

    property bool done: false
    property string createdHppPath: ""
    property string createdCppPath: ""
    property string errorText: ""

    function hppContent(name) {
        return "#pragma once\n\n" +
            "#include <noi_engine/core/ecs/entity.hpp>\n" +
            "#include <noi_engine/core/model/script.hpp>\n\n" +
            "namespace noi_engine_game\n{\n" +
            "    class " + name + "_script : public noi_engine::script\n    {\n" +
            "    public:\n" +
            "        auto on_update(noi_engine::entity self,\n" +
            "                       const noi_engine::script_context &context, float dt)\n" +
            "            -> void override;\n\n" +
            "        explicit " + name + "_script() = default;\n" +
            "    };\n}\n"
    }

    function cppContent(name) {
        return "#include \"" + name + "_script.hpp\"\n\n" +
            "auto noi_engine_game::" + name + "_script::on_update(\n" +
            "    [[maybe_unused]] const noi_engine::entity self,\n" +
            "    [[maybe_unused]] const noi_engine::script_context& context,\n" +
            "    [[maybe_unused]] const float dt) -> void\n{\n}\n"
    }

    function createScript() {
        if (!root.validName) return;

        const hppFile = root.trimmedName + "_script.hpp";
        const cppFile = root.trimmedName + "_script.cpp";

        if (!CurrentProjectResourcesManager.createFile(root.scriptsFolder, hppFile, root.hppContent(root.trimmedName))) {
            root.errorText = qsTr("A file named %1 already exists.").arg(hppFile);
            return;
        }
        if (!CurrentProjectResourcesManager.createFile(root.scriptsFolder, cppFile, root.cppContent(root.trimmedName))) {
            root.errorText = qsTr("A file named %1 already exists.").arg(cppFile);
            return;
        }

        root.createdHppPath = "sources/scripts/" + hppFile;
        root.createdCppPath = "sources/scripts/" + cppFile;
        root.errorText = "";
        root.done = true;
    }

    title: qsTr("Add Script")
    modal: true
    anchors.centerIn: Overlay.overlay
    implicitWidth: 360
    standardButtons: Dialog.NoButton

    onOpened: {
        root.done = false;
        root.errorText = "";
        nameInput.text = "";
        nameInput.forceActiveFocus();
    }

    background: Rectangle {
        color: Theme.bgTertiary
        border.color: Theme.borderColor
        border.width: 1
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        ColumnLayout {
            visible: !root.done
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: qsTr("Script name (e.g. \"enemy\"):")
                font.pixelSize: 12
                color: Theme.darkGrey
            }

            TextField {
                id: nameInput
                Layout.fillWidth: true
                font.pixelSize: 13
                color: Theme.white
                selectByMouse: true
                placeholderText: qsTr("enemy")
                onAccepted: root.createScript()
            }

            Text {
                Layout.fillWidth: true
                visible: root.trimmedName !== ""
                text: root.validName
                    ? qsTr("Creates sources/scripts/%1.hpp and .cpp").arg(root.className)
                    : qsTr("Use letters, numbers, and underscores only - must start with a letter or underscore.")
                font.pixelSize: 10
                font.italic: true
                color: root.validName ? Theme.grey : Theme.error
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: root.errorText !== ""
                text: root.errorText
                font.pixelSize: 10
                color: Theme.error
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("Cancel")
                    onClicked: root.reject()
                }

                AppButton {
                    text: qsTr("Create")
                    enabled: root.validName
                    onClicked: root.createScript()
                }
            }
        }

        ColumnLayout {
            visible: root.done
            Layout.fillWidth: true
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: qsTr("Script created:")
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.white
            }

            Text {
                Layout.fillWidth: true
                text: root.createdHppPath + "\n" + root.createdCppPath
                font.pixelSize: 11
                font.family: "monospace"
                color: Theme.grey
                wrapMode: Text.WrapAnywhere
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Register it in sources/scripts/scripts_register.cpp with NOI_ENGINE_REGISTER_SCRIPT(%1), add it to CMakeLists.txt, then rebuild before attaching it to an entity.").arg(root.className)
                font.pixelSize: 10
                font.italic: true
                color: Theme.grey
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("Close")
                    onClicked: root.accept()
                }
            }
        }
    }
}
