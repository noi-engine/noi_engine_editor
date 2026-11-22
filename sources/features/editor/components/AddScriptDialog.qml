import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import noi_engine_editor

// Creates a new script (sources/scripts/<name>_script.hpp/.cpp). The script registers itself
// (NOI_ENGINE_SCRIPT) and the project's CMakeLists picks up every file in sources/scripts, so
// there is nothing to wire by hand: scriptCreated() is emitted, the Inspector compiles the
// project and attaches the script to the selected entity. Editing its code is done outside the
// editor.
AppDialog {
    id: root

    readonly property string scriptsFolder: CurrentProjectManager.path + "/sources/scripts"
    signal scriptCreated(string label)

    // "enemy" and "enemy_script" both give enemy_script.
    readonly property string trimmedName: nameInput.text.trim().replace(/_script$/, "")
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
            "        // Once, when Play starts (or when the entity appears).\n" +
            "        auto on_create(noi_engine::entity self,\n" +
            "                       const noi_engine::script_context &context)\n" +
            "            -> void override;\n\n" +
            "        // Every frame; dt is in seconds.\n" +
            "        auto on_update(noi_engine::entity self,\n" +
            "                       const noi_engine::script_context &context, float dt)\n" +
            "            -> void override;\n\n" +
            "        explicit " + name + "_script() = default;\n\n" +
            "        // Registers the script under the name \"" + name + "_script\" (the name scenes use).\n" +
            "        NOI_ENGINE_SCRIPT(" + name + "_script);\n" +
            "    };\n}\n"
    }

    function cppContent(name) {
        return "#include \"" + name + "_script.hpp\"\n\n" +
            "auto noi_engine_game::" + name + "_script::on_create(\n" +
            "    [[maybe_unused]] const noi_engine::entity self,\n" +
            "    [[maybe_unused]] const noi_engine::script_context& context) -> void\n{\n}\n\n" +
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
        root.scriptCreated(root.className);
    }

    title: root.done ? qsTr("Script created") : qsTr("New script")
    subtitle: root.done
        ? qsTr("Your script is ready to be filled with code.")
        : qsTr("A script is the code that makes an object move or react (a player, an enemy, a door...).")
    icon: "code"
    preferredWidth: 500

    onOpened: {
        root.done = false;
        root.errorText = "";
        nameInput.text = "";
        nameInput.field.forceActiveFocus();
    }

    // ---- Step 1: name
    AppTextField {
        id: nameInput
        visible: !root.done
        Layout.fillWidth: true
        label: qsTr("Script name")
        placeholderText: qsTr("enemy")
        hint: root.trimmedName === ""
            ? qsTr("Use letters, numbers and underscores (for example enemy).")
            : root.validName ? qsTr("Creates sources/scripts/%1.hpp and %1.cpp").arg(root.className) : ""
        error: root.trimmedName !== "" && !root.validName
            ? qsTr("Use letters, numbers and underscores only, starting with a letter or underscore.") : ""
        onEdited: root.errorText = ""
        onAccepted: root.createScript()
    }

    Banner {
        Layout.fillWidth: true
        kind: "error"
        visible: !root.done && root.errorText !== ""
        title: qsTr("The script couldn't be created")
        text: root.errorText + " " + qsTr("Pick another name.")
    }

    // ---- Step 2: created
    Banner {
        Layout.fillWidth: true
        visible: root.done
        kind: "success"
        title: root.className
        text: qsTr("Created %1 and %2.").arg(root.createdHppPath).arg(root.createdCppPath)
    }

    Text {
        Layout.fillWidth: true
        visible: root.done
        text: qsTr("What happens next: the project compiles, then %1 is attached to the selected object. Write what it does in these two files (with your code editor), and press Compile again to try it.").arg(root.className)
        font.pixelSize: 12
        color: Theme.darkGrey
        wrapMode: Text.WordWrap
    }

    footerContent: [
        Item { Layout.fillWidth: true },
        AppButton {
            visible: !root.done
            text: qsTr("Cancel")
            onClicked: root.reject()
        },
        AppButton {
            visible: !root.done
            text: qsTr("Create script")
            icon: "add"
            primary: true
            enabled: root.validName
            onClicked: root.createScript()
        },
        AppButton {
            visible: root.done
            text: qsTr("Close")
            primary: true
            onClicked: root.accept()
        }
    ]
}
