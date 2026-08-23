import QtQuick
import QtQuick.Layouts

import noi_engine_editor

RowLayout {
    id: root

    signal createProjectRequested()
    signal openProjectRequested()

    spacing: 24 // Espacement légèrement augmenté pour mieux aérer

    ActionCard {
        primary: true

        icon: "add_circle"
        title: qsTr("Create a Project")
        description: qsTr("Start a new project and build your next experience with Noi Engine.")
        actionText: qsTr("Get started")

        onClicked: root.createProjectRequested()
    }

    ActionCard {
        primary: false
        icon: "folder_open"
        title: qsTr("Open a Project")
        description: qsTr("Open an existing Noi Engine project from your computer.")
        actionText: qsTr("Browse projects")

        onClicked: root.openProjectRequested()
    }
}