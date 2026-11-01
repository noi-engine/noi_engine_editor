import QtQuick
import noi_engine_editor

LogPanel {
    title: qsTr("OUTPUT")
    text: ProjectBuilder.output
    busy: ProjectBuilder.isCompiling
    busyText: qsTr("Compiling...")
    onClearRequested: ProjectBuilder.clearOutput()
}
