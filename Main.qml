import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import noi_engine_editor

ApplicationWindow {
    id: root

    visible: true
    title: qsTr("Noi Engine Editor")
    width: 1440
    height: 860
    minimumWidth: 960
    minimumHeight: 600
    color: Theme.bgPrimary

    // Every default control (dialogs, text fields, combo boxes, menus...) follows the dark theme.
    Material.theme: Material.Dark
    Material.accent: Theme.primaryColor
    Material.primary: Theme.primaryColor
    Material.background: Theme.bgPrimary
    Material.foreground: Theme.white

    StackView { id: stackView; anchors.fill: parent }

    ToastHost { parent: Overlay.overlay }

    Component.onCompleted: {
        Router.stackView = stackView

        Router.replace("/");

        // Development aid: `--demo <name>` opens a dialog of the home page (see HomePage.demo).
        const demoIndex = Qt.application.arguments.indexOf("--demo");
        if (demoIndex >= 0) {
            const demoName = Qt.application.arguments[demoIndex + 1];
            Qt.callLater(() => { if (stackView.currentItem && stackView.currentItem.demo) stackView.currentItem.demo(demoName); });
        }

        // `noi_engine_editor <project folder>` opens that project directly.
        const args = Qt.application.arguments;
        if (args.length > 1 && CurrentProjectManager.isProjectFolder(args[1])) {
            if (CurrentProjectManager.openProject(args[1])) {
                Router.push("/editor");
            } else {
                console.warn("Can't open " + args[1] + ": " + CurrentProjectManager.lastOpenError);
            }
        }
    }
}
