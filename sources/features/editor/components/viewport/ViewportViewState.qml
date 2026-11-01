import QtQuick

import noi_engine_editor

// Saves the viewport's zoom, world size and scroll position with the project (its
// "editor_view") and restores them when the project reopens.
Item {
    id: root

    property Item viewport  // the ViewportPanel: cameraZoom, worldWidth, worldHeight
    property Flickable flickable
    // The scene is on screen, so the content has its final size and the scroll can be restored.
    property bool sceneShown: false

    property bool restored: false
    property bool scrollRestored: false

    function save() {
        if (root.restored) saveTimer.restart();
    }

    Component.onCompleted: {
        const view = CurrentProjectManager.editorView || {};
        if (view.zoom) root.viewport.cameraZoom = view.zoom;
        if (view.world_width) root.viewport.worldWidth = view.world_width;
        if (view.world_height) root.viewport.worldHeight = view.world_height;
        root.restored = true;
    }

    onSceneShownChanged: {
        if (!root.sceneShown || root.scrollRestored) return;
        root.scrollRestored = true;
        const view = CurrentProjectManager.editorView || {};
        Qt.callLater(function() {
            if (view.scroll_x !== undefined) root.flickable.contentX = view.scroll_x;
            if (view.scroll_y !== undefined) root.flickable.contentY = view.scroll_y;
        });
    }

    Connections {
        target: root.viewport
        function onCameraZoomChanged() { root.save(); }
        function onWorldWidthChanged() { root.save(); }
        function onWorldHeightChanged() { root.save(); }
    }

    Connections {
        target: root.flickable
        function onContentXChanged() { if (root.scrollRestored) root.save(); }
        function onContentYChanged() { if (root.scrollRestored) root.save(); }
    }

    Timer {
        id: saveTimer
        interval: 700
        onTriggered: {
            CurrentProjectManager.editorView = {
                "zoom": root.viewport.cameraZoom,
                "world_width": root.viewport.worldWidth,
                "world_height": root.viewport.worldHeight,
                "scroll_x": root.flickable.contentX,
                "scroll_y": root.flickable.contentY
            };
            CurrentProjectManager.saveProject();
        }
    }
}
