pragma Singleton

import QtQuick

// Short messages ("Scene saved", "Couldn't save: ...") shown by the ToastHost of the main window.
QtObject {
    signal posted(string text, string kind)

    function info(text) { posted(text, "info") }
    function success(text) { posted(text, "success") }
    function warning(text) { posted(text, "warning") }
    function error(text) { posted(text, "error") }
}
