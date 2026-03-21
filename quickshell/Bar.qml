import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors { top: true; left: true; right: true }

    WlrLayershell.layer: WlrLayer.Top
    // Always reserve only 35 px — popup overlaps content below rather than pushing it
    WlrLayershell.exclusiveZone: 35
    WlrLayershell.namespace: "quickshell-bar"

    // Grows to fit the popup when visible
    readonly property int barH:     35
    readonly property int popupH:   200
    implicitHeight: popupVisible ? barH + popupH + 10 : barH


    color: "transparent"

    // ── Full-width bar background ─────────────────────────────────────────
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: root.barH
        color: Qt.rgba(28/255, 14/255, 52/255, 0.55)
        // Subtle specular bottom edge
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(110/255, 85/255, 150/255, 0.22)
        }
    }

    // ── Popup visibility (with close-delay so you can move mouse into it) ──
    property bool popupVisible: false

    Timer {
        id: closeTimer
        interval: 500
        onTriggered: root.popupVisible = false
    }

    function onMprisHoverEnter() {
        closeTimer.stop()
        if (!popupVisible) {
            mprisWidget._syncPos()   // refresh position when popup opens
            popupVisible = true
        }
    }
    function onMprisHoverLeave() { closeTimer.restart() }

    // ── Left — window title ───────────────────────────────────────────────
    WindowTitle {
        id: wt
        anchors { left: parent.left; top: parent.top; leftMargin: 16 }
        height: root.barH
        width: implicitWidth
    }

    // ── Centre — dock section hanging from top ────────────────────────────
    Item {
        id: centreSection
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
        width: centreRow.implicitWidth + 32
        height: root.barH

        // RowLayout centres items of different heights on the same baseline
        RowLayout {
            id: centreRow
            anchors.centerIn: parent
            spacing: 10
            height: root.barH

            Workspaces { Layout.alignment: Qt.AlignVCenter }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1; height: 16
                color: Qt.rgba(110/255, 85/255, 150/255, 0.50)
            }

            Clock { Layout.alignment: Qt.AlignVCenter }

            Mpris {
                id: mprisWidget
                Layout.alignment: Qt.AlignVCenter
                onHoveredChanged: hovered ? root.onMprisHoverEnter() : root.onMprisHoverLeave()
            }
        }

        // Progress bar — anchored to dock bottom, completely outside hover zone
        Rectangle {
            visible: mprisWidget.visible && mprisWidget.trackLen > 0
            anchors {
                left: parent.left; right: parent.right; bottom: parent.bottom
                leftMargin: 10; rightMargin: 10
            }
            height: 2; radius: 1
            color: Qt.rgba(110/255, 85/255, 150/255, 0.18)

            Rectangle {
                width: parent.width * mprisWidget.progress
                height: parent.height; radius: 1
                color: "#9b7bc4"
                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
            }
        }
    }

    // ── Right — status group ──────────────────────────────────────────────
    Row {
        anchors { right: parent.right; top: parent.top; rightMargin: 16 }
        height: root.barH
        spacing: 6

        Row {
            id: statusRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Network {}
            Rectangle { width:1; height:14; color: Qt.rgba(110/255,85/255,150/255,0.45); anchors.verticalCenter: parent.verticalCenter }
            NetTraffic {}
            Rectangle { width:1; height:14; color: Qt.rgba(110/255,85/255,150/255,0.45); anchors.verticalCenter: parent.verticalCenter }
            Audio {}
            Rectangle { width:1; height:14; color: Qt.rgba(110/255,85/255,150/255,0.45); anchors.verticalCenter: parent.verticalCenter }
            Bluetooth {}
            Rectangle { width:1; height:14; color: Qt.rgba(110/255,85/255,150/255,0.45); anchors.verticalCenter: parent.verticalCenter }
            Tray {}
        }

        PowerButton { anchors.verticalCenter: parent.verticalCenter }
    }

    // ── Mpris hover popup — centred below the dock ────────────────────────
    Item {
        id: popup

        function fmt(secs) {
            const s = Math.floor(secs)
            return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
        }
        visible: root.popupVisible
        opacity: root.popupVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }

        // Centre under the dock section
        x: (root.width - width) / 2
        y: root.barH
        width: 320
        height: root.popupH

        // ── Card background ───────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(28/255, 14/255, 52/255, 0.90)
            radius: 16
            border.width: 1
            border.color: Qt.rgba(110/255, 85/255, 150/255, 0.32)

            Column {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // ── Top row: album art + track info ───────────────────
                Row {
                    width: parent.width
                    spacing: 14

                    // Album art
                    Rectangle {
                        id: artContainer
                        width: 80; height: 80
                        radius: 10
                        color: Qt.rgba(35/255, 18/255, 65/255, 1)
                        clip: true

                        Image {
                            id: artImage
                            anchors.fill: parent
                            source: mprisWidget.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                            onStatusChanged: artFallback.visible = (status !== Image.Ready)
                        }

                            // Fallback music icon when no art available
                        Text {
                            id: artFallback
                            anchors.centerIn: parent
                            text: ""
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 32 }
                            color: "#8878a8"
                        }
                    }

                    // Track info
                    Column {
                        width: parent.width - artContainer.width - parent.spacing
                        anchors.verticalCenter: artContainer.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: mprisWidget.player?.trackTitle ?? ""
                            color: "#e8e0f0"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true }
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: mprisWidget.player?.trackArtist ?? ""
                            color: "#9b7bc4"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                        Text {
                            width: parent.width
                            text: mprisWidget.player?.trackAlbum ?? ""
                            color: "#8878a8"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }
                }

                // ── Controls ──────────────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    Repeater {
                        model: [
                            { icon: "󰒮", act: "prev",  sz: 18 },
                            { icon: mprisWidget.isPlaying ? "󰏤" : "󰐊", act: "pp", sz: 26 },
                            { icon: "󰒭", act: "next",  sz: 18 }
                        ]
                        delegate: Text {
                            required property var modelData
                            text: modelData.icon
                            color: btnHover.hovered ? "#9b7bc4" : "#e8e0f0"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: modelData.sz }
                            Behavior on color { ColorAnimation { duration: 100 } }
                            HoverHandler { id: btnHover }
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if      (modelData.act === "prev") mprisWidget.player?.previous()
                                    else if (modelData.act === "pp")   mprisWidget.player?.togglePlaying()
                                    else                               mprisWidget.player?.next()
                                }
                            }
                        }
                    }
                }

                // ── Progress bar + timestamps ─────────────────────────
                Column {
                    width: parent.width
                    spacing: 4
                    visible: mprisWidget.trackLen > 0

                    // Bar — click to scrub
                    Rectangle {
                        id: scrubBar
                        width: parent.width; height: 3; radius: 2
                        color: Qt.rgba(110/255, 85/255, 150/255, 0.20)

                        Rectangle {
                            width: scrubBar.width * mprisWidget.progress
                            height: parent.height; radius: 2
                            color: "#9b7bc4"
                            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                        }
                    }

                    // Timestamps — position left, duration right
                    Item {
                        width: parent.width
                        height: tsPos.implicitHeight

                        Text {
                            id: tsPos
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: popup.fmt(mprisWidget.trackPos)
                            color: "#8878a8"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 9 }
                        }
                        Text {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: popup.fmt(mprisWidget.trackLen)
                            color: "#8878a8"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 9 }
                        }
                    }
                }
            }
        }

        // Hover tracker — no click handler so press events fall through to buttons
        MouseArea {
            id: popupHover
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: root.onMprisHoverEnter()
            onExited:  root.onMprisHoverLeave()
        }

        // Scrub hit area — sits on top of popupHover, only covers the progress bar
        MouseArea {
            x: scrubBar.mapToItem(popup, 0, 0).x
            y: scrubBar.mapToItem(popup, 0, 0).y - 6
            width: scrubBar.width
            height: scrubBar.height + 12
            visible: mprisWidget.trackLen > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                const ratio = Math.max(0, Math.min(1, mouseX / width))
                mprisWidget.seekTo(ratio * mprisWidget.trackLen)
            }
        }
    }
}
