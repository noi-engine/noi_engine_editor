pragma Singleton

import QtQuick
import "IconLoaderCreator.js" as JSIconLoader

QtObject {
    readonly property var muiIconLoader: JSIconLoader.getLoader("mui")

    function mui(iconName) {
        const icon = muiIconLoader.get(iconName);
        if (!icon) {
            console.log("Icon.name=" + iconName + " is not found");
        }

        return icon;
    }
}
