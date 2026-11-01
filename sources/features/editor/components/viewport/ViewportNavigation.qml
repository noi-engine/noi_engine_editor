import QtQuick

// Moving around the viewport: drag with the middle button anywhere, or with the left button
// on empty space (presses on entities / the camera border are taken by the items above);
// the wheel, or Shift + drag (up = zoom in), zooms at the cursor.
MouseArea {
    id: root

    property Item viewport

    property point last
    property point zoomOrigin
    property bool panning: false
    property bool zooming: false

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    hoverEnabled: false
    cursorShape: zooming ? Qt.SizeVerCursor
        : (panning ? Qt.ClosedHandCursor : (viewport.activeTool === "pan" ? Qt.OpenHandCursor : Qt.ArrowCursor))

    onPressed: mouse => {
        last = Qt.point(mouse.x, mouse.y);
        zoomOrigin = last;
        zooming = mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ShiftModifier);
        panning = !zooming;
    }
    onPositionChanged: mouse => {
        if (zooming) {
            viewport.zoomAt(Math.pow(1.01, last.y - mouse.y), zoomOrigin.x, zoomOrigin.y);
        } else if (panning) {
            viewport.panBy(mouse.x - last.x, mouse.y - last.y);
        }
        last = Qt.point(mouse.x, mouse.y);
    }
    onReleased: { panning = false; zooming = false; }
    onCanceled: { panning = false; zooming = false; }

    onWheel: wheel => {
        const steps = wheel.angleDelta.y / 120;
        if (steps !== 0) viewport.zoomAt(Math.pow(1.15, steps), wheel.x, wheel.y);
    }
}
