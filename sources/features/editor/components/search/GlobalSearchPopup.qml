import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import noi_engine_editor

// Ctrl+K: one search over the scene's entities (by name, folder or component), the project's
// scenes and the loaded resources. Enter / click opens the highlighted result.
Popup {
    id: root

    property var entities: []
    property var resources: []
    property var scenePaths: []
    property string resourcesRoot: ""

    signal entityChosen(var entity)
    signal sceneChosen(string filePath)
    signal resourceChosen(var resource)

    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property int maxPerGroup: 8

    readonly property var results: {
        const q = root.query;
        if (q === "") return [];
        const hits = [];

        const entityHits = (root.entities || []).filter(e => e.name.toLowerCase().indexOf(q) !== -1
            || (e.folder || "").toLowerCase().indexOf(q) !== -1
            || (e.componentTypes || []).some(t => t.indexOf(q) !== -1));
        for (const e of entityHits.slice(0, root.maxPerGroup)) {
            // Show why it matched: the component when the name doesn't, else the folder.
            const component = (e.componentTypes || []).find(t => t.indexOf(q) !== -1);
            const byName = e.name.toLowerCase().indexOf(q) !== -1;
            hits.push({group: qsTr("Entities"), icon: "category", title: e.name,
                       detail: !byName && component ? component : (e.folder || ""),
                       kind: "entity", payload: e});
        }

        const sceneHits = (root.scenePaths || []).filter(p => p.toLowerCase().indexOf(q) !== -1);
        for (const p of sceneHits.slice(0, root.maxPerGroup)) {
            hits.push({group: qsTr("Scenes"), icon: "landscape", title: p.substring(p.lastIndexOf("/") + 1),
                       detail: p.replace(root.resourcesRoot + "/", ""), kind: "scene", payload: p});
        }

        const resourceHits = (root.resources || []).filter(r => r.label.toLowerCase().indexOf(q) !== -1);
        for (const r of resourceHits.slice(0, root.maxPerGroup)) {
            hits.push({group: qsTr("Resources"), icon: r.type === "material" ? "palette" : "inventory_2",
                       title: r.label, detail: r.type, kind: "resource", payload: r});
        }
        return hits;
    }

    function choose(index) {
        const hit = root.results[index];
        if (!hit) return;
        root.close();
        if (hit.kind === "entity") root.entityChosen(hit.payload);
        else if (hit.kind === "scene") root.sceneChosen(hit.payload);
        else root.resourceChosen(hit.payload);
    }

    modal: true
    focus: true
    width: Math.min(560, (parent ? parent.width : 560) - 40)
    height: Math.min(440, column.implicitHeight + 24)
    x: ((parent ? parent.width : width) - width) / 2
    y: 70
    padding: 12

    onOpened: {
        searchInput.text = "";
        resultsView.currentIndex = 0;
        searchInput.forceActiveFocus();
    }

    background: Rectangle {
        color: Theme.bgSecondary
        border.color: Theme.borderColor
        border.width: 1
        radius: 10
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 8
            color: Theme.bgPrimary
            border.color: Theme.primaryColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                MuiIcon {
                    name: "search"
                    font.pixelSize: 18
                    color: Theme.grey
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    background: Item {}
                    placeholderText: qsTr("Search entities, components, folders, scenes, resources...")
                    placeholderTextColor: Theme.grey
                    font.pixelSize: 13
                    color: Theme.white
                    onTextChanged: resultsView.currentIndex = 0

                    Keys.onDownPressed: resultsView.currentIndex = Math.min(resultsView.count - 1, resultsView.currentIndex + 1)
                    Keys.onUpPressed: resultsView.currentIndex = Math.max(0, resultsView.currentIndex - 1)
                    Keys.onReturnPressed: root.choose(resultsView.currentIndex)
                    Keys.onEnterPressed: root.choose(resultsView.currentIndex)
                    Keys.onEscapePressed: root.close()
                }
            }
        }

        Text {
            visible: root.query !== "" && root.results.length === 0
            text: qsTr("No result for \"%1\"").arg(searchInput.text.trim())
            font.pixelSize: 12
            font.italic: true
            color: Theme.grey
        }

        ListView {
            id: resultsView

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 340)
            visible: root.results.length > 0
            clip: true
            model: root.results
            currentIndex: 0
            section.property: "group"
            section.delegate: Text {
                required property string section
                text: section.toUpperCase()
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.grey
                topPadding: 8
                bottomPadding: 4
            }

            delegate: Rectangle {
                id: resultRow

                required property var modelData
                required property int index

                width: resultsView.width
                height: 32
                radius: 6
                color: resultsView.currentIndex === index ? Theme.primaryLightC
                    : (rowArea.containsMouse ? Theme.bgTertiary : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    MuiIcon {
                        name: resultRow.modelData.icon
                        font.pixelSize: 15
                        color: Theme.primaryColor
                    }

                    Text {
                        Layout.fillWidth: true
                        text: resultRow.modelData.title
                        font.pixelSize: 12
                        color: Theme.white
                        elide: Text.ElideRight
                    }

                    Text {
                        text: resultRow.modelData.detail
                        font.pixelSize: 10
                        color: Theme.grey
                        elide: Text.ElideLeft
                        Layout.maximumWidth: resultRow.width * 0.4
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.choose(resultRow.index)
                }
            }
        }
    }
}
