import QtQuick
import Quickshell.Hyprland

// Workspace dot indicators — always shows 1-6, circle style like z.hyprdots
// Active: filled primary blue  |  Occupied: dim primary  |  Empty: outline gray
Rectangle {
    id: root

    color: Qt.rgba(35/255, 18/255, 65/255, 0.50)
    radius: 99
    implicitHeight: 22
    implicitWidth: row.implicitWidth + 16

    // Always display workspaces 1–6; merge with any extras Hyprland reports
    property var allIds: {
        const ids = new Set([1, 2, 3, 4, 5, 6])
        for (const ws of Hyprland.workspaces.values) ids.add(ws.id)
        return [...ids].sort((a, b) => a - b)
    }

    property int activeId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? -1

    // Map id → workspace object (null = empty slot)
    function wsForId(id) {
        for (const ws of Hyprland.workspaces.values)
            if (ws.id === id) return ws
        return null
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.allIds

            delegate: Item {
                required property var modelData   // workspace id (int)

                property bool isActive:   modelData === root.activeId
                property bool isOccupied: root.wsForId(modelData) !== null
                property bool hovered:    area.containsMouse

                implicitWidth: dot.width
                implicitHeight: dot.height

                // Circle dot — size varies with state
                Rectangle {
                    id: dot
                    width:  isActive ? 10 : 7
                    height: isActive ? 10 : 7
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter

                    color: isActive
                        ? "#9b7bc4"                              // primary
                        : isOccupied
                            ? Qt.rgba(110/255, 85/255, 150/255, 0.45)  // dim primary
                            : (hovered ? "#8878a8" : "#1e0d3a")          // outline / dark

                    Behavior on width  { NumberAnimation { duration: 150 } }
                    Behavior on height { NumberAnimation { duration: 150 } }
                    Behavior on color  { ColorAnimation  { duration: 150 } }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Make the click target a bit larger than the tiny dot
                    anchors.margins: -4
                    onClicked: Hyprland.dispatch("workspace " + modelData)
                }
            }
        }
    }
}
