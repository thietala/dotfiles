import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// ── ControlCenterWindow ────────────────────────────────────────────────────────
// Fixed-size surface — no Wayland resize ever.
// Blur animates via ignore_alpha layerrule: Hyprland skips blurring transparent
// pixels, so as the QML clip grows the blurred region grows with it.
// ─────────────────────────────────────────────────────────────────────────────
PanelWindow {
    id: root

    required property var screen

    anchors.top: true

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.namespace:     "quickshell-cc"

    implicitWidth:  520
    implicitHeight: cc.height

    color: "transparent"
    visible: false

    property bool isOpen:          false
    property bool mouseHasEntered: false

    // ── Clip container — height grows 0 → full; ignore_alpha makes blur follow ─
    Item {
        id: clipper
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        width:  520
        height: root.isOpen ? cc.height : 0
        clip:   true

        Behavior on height {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        // Panel background — always full height, clipped by parent
        Rectangle {
            width:  520
            height: cc.height
            color:        Qt.rgba(28/255, 14/255, 52/255, 0.55)
            radius:       14
            border.width: 1
            border.color: Qt.rgba(110/255, 85/255, 150/255, 0.45)

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1 }
                height: 1
                color:  Qt.rgba(1, 1, 1, 0.07)
            }
        }

        // Content — slides down with bounce, fades in
        ControlCenter {
            id: cc
            active: root.isOpen

            y:       root.isOpen ? 0 : -18
            opacity: root.isOpen ? 1.0 : 0.0

            onCloseRequested: root.closeCC()

            Behavior on y {
                NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
            }
            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }
    }

    // ── Hover tracking — auto-close when mouse leaves ─────────────────────────
    HoverHandler {
        id: panelHover
        onHoveredChanged: {
            if (hovered) {
                root.mouseHasEntered = true
            } else if (root.mouseHasEntered && root.isOpen) {
                leaveTimer.restart()
            }
        }
    }

    Timer {
        id: leaveTimer
        interval: 250
        onTriggered: if (!panelHover.hovered && root.isOpen) root.closeCC()
    }

    // ── IPC ───────────────────────────────────────────────────────────────────
    IpcHandler {
        target: "cc"
        function toggle(): void           { root.isOpen ? root.closeCC() : root.openCC() }
        function open(): void             { if (!root.isOpen) root.openCC() }
        function closeIfUnhovered(): void { if (!panelHover.hovered) root.closeCC() }
    }

    function openCC() {
        mouseHasEntered = false
        visible = true
        isOpen  = true
    }

    function closeCC() {
        isOpen          = false
        mouseHasEntered = false
        leaveTimer.stop()
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 340
        onTriggered: if (!root.isOpen) root.visible = false
    }
}
