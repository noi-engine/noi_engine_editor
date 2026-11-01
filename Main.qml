import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

ApplicationWindow {
    id: root

    visible: true
    color: Theme.bgPrimary

    StackView { id: stackView; anchors.fill: parent }

    Component.onCompleted: {
        Router.stackView = stackView

        Theme.setup()

        Router.replace("/");

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
