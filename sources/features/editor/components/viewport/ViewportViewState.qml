import QtQuick

import noi_engine_editor

// Saves the viewport's view (position, zoom) with the project ("editor_view") and restores it
// when the scene shows up; without a saved view, frames the scene camera.
Item {
    id: root

    property Item viewport // ViewportPanel: viewX, viewY, viewZoom, frameCamera()
    property bool sceneShown: false

    property bool restored: false

    onSceneShownChanged: {
        if (!root.sceneShown || root.restored) return;
        root.restored = true;
        const view = CurrentProjectManager.editorView || {};
        if (view.view_x !== undefined && view.view_y !== undefined && view.zoom) {
            root.viewport.viewX = view.view_x;
            root.viewport.viewY = view.view_y;
            root.viewport.viewZoom = view.zoom;
        } else {
            Qt.callLater(root.viewport.frameCamera);
        }
    }

    Connections {
        target: root.viewport
        function onViewXChanged() { if (root.restored) saveTimer.restart(); }
        function onViewYChanged() { if (root.restored) saveTimer.restart(); }
        function onViewZoomChanged() { if (root.restored) saveTimer.restart(); }
    }

    Timer {
        id: saveTimer
        interval: 700
        onTriggered: {
            CurrentProjectManager.editorView = {
                "view_x": root.viewport.viewX,
                "view_y": root.viewport.viewY,
                "zoom": root.viewport.viewZoom
            };
            CurrentProjectManager.saveProject();
        }
    }
}
