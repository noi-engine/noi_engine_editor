import QtQuick

// Moving around the viewport: drag with the middle button anywhere, or with the left button
// on empty space (presses on entities / the camera border are taken by the items above);
// the wheel zooms at the cursor.
MouseArea {
    id: root

    property Item viewport

    property point last
    property bool panning: false

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    hoverEnabled: false
    cursorShape: panning ? Qt.ClosedHandCursor : (viewport.activeTool === "pan" ? Qt.OpenHandCursor : Qt.ArrowCursor)

    onPressed: mouse => {
        last = Qt.point(mouse.x, mouse.y);
        panning = true;
    }
    onPositionChanged: mouse => {
        if (!panning) return;
        viewport.panBy(mouse.x - last.x, mouse.y - last.y);
        last = Qt.point(mouse.x, mouse.y);
    }
    onReleased: panning = false
    onCanceled: panning = false

    onWheel: wheel => {
        const steps = wheel.angleDelta.y / 120;
        if (steps !== 0) viewport.zoomAt(Math.pow(1.15, steps), wheel.x, wheel.y);
    }
}
