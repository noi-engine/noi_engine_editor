import QtQuick
import noi_engine_editor

LogPanel {
    title: qsTr("EDITOR LOGS")
    text: EditorLogger.text
    onClearRequested: EditorLogger.clear()
}
