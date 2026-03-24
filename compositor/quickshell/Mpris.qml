import QtQuick
import Quickshell.Services.Mpris

// Compact bar widget — exposes `hovered` so Bar.qml can show the popup
Item {
    id: root

    // ── Player selection ──────────────────────────────────────────────
    property var player: {
        const players = Mpris.players.values
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing &&
                !p.identity.toLowerCase().includes("firefox"))
                return p
        }
        for (const p of players) {
            if (!p.identity.toLowerCase().includes("firefox")) return p
        }
        return null
    }

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing

    // ── Progress — pure stopwatch, no D-Bus position polling ──────────
    // PlexAmp's MPRIS always reports Position=0 and crashes on Seek/SetPosition
    // (Node.js BigInt bug in its dbus-next). We track time locally instead.
    property real trackPos: 0
    property real trackLen: player?.length ?? 0
    property real progress: (trackLen > 0) ? Math.min(trackPos / trackLen, 1.0) : 0

    property double _posAtPause: 0   // saved position when paused
    property double _playStart:  0   // Date.now() when play last started (0 = not set)

    onIsPlayingChanged: {
        if (isPlaying) {
            _playStart = Date.now()
        } else {
            _posAtPause = trackPos
            _playStart  = 0
        }
    }

    // Guard: only run when _playStart is set so we never compute Date.now() - 0
    Timer {
        interval: 500
        running: root.isPlaying && root._playStart > 0
        repeat: true
        onTriggered: root.trackPos = root._posAtPause + (Date.now() - root._playStart) / 1000
    }

    function seekTo(secs) {
        if (!player) return
        player.seek(secs - trackPos)
        _posAtPause = secs
        _playStart  = isPlaying ? Date.now() : 0
        trackPos    = secs
    }

    function _syncPos() {}

    // On player change: seed _posAtPause from D-Bus (correct for Spotify etc, 0 for PlexAmp)
    // Watched binding — fires whenever the track changes regardless of signal delivery
    readonly property string currentTrackKey: (player?.trackTitle ?? "") + "|" + (player?.trackAlbum ?? "")
    onCurrentTrackKeyChanged: {
        trackPos = 0; _posAtPause = 0; _playStart = isPlaying ? Date.now() : 0
    }

    onPlayerChanged: {
        if (!player) { trackPos = 0; _posAtPause = 0; _playStart = 0 }
        // currentTrackKey binding handles reset when player/track changes
    }

    // ── Hover state (read by Bar.qml to trigger popup) ────────────────
    property bool hovered: hoverArea.containsMouse

    // ── Helpers ───────────────────────────────────────────────────────
    function playerIcon() {
        if (!player) return ""
        return player.identity.toLowerCase().includes("spotify") ? "" : ""
    }

    function trunc(s, n) { return s.length > n ? s.substring(0, n - 1) + "…" : s }

    // ── Layout ────────────────────────────────────────────────────────
    visible: player !== null
    implicitWidth:  visible ? content.implicitWidth + 20 : 0
    implicitHeight: content.implicitHeight + 8

    // Thin left separator
    Rectangle {
        id: leftSep
        width: 1; height: 14
        color: Qt.rgba(110/255, 85/255, 150/255, 0.28)
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    }

    Row {
        id: content
        anchors { left: leftSep.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 6

        Text {
            text: root.playerIcon()
            color: root.isPlaying ? "#9b7bc4" : "#8878a8"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
            anchors.verticalCenter: parent.verticalCenter
        }

        // Compact: title only — artist is shown in the hover popup
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.trunc(root.player?.trackTitle ?? "", 24)
            color: root.isPlaying ? "#9b7bc4" : "#8878a8"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: root.isPlaying }
        }

        Row {
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: [
                    { icon: "󰒮", act: "prev"      },
                    { icon: root.isPlaying ? "󰏤" : "󰐊", act: "pp" },
                    { icon: "󰒭", act: "next"      }
                ]
                delegate: Text {
                    required property var modelData
                    text: modelData.icon
                    color: ca.containsMouse ? "#9b7bc4" : "#8878a8"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: modelData.act === "pp" ? 13 : 10 }
                    anchors.verticalCenter: parent?.verticalCenter
                    Behavior on color { ColorAnimation { duration: 100 } }
                    MouseArea {
                        id: ca; anchors.fill: parent; anchors.margins: -4
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if      (modelData.act === "prev") root.player?.previous()
                            else if (modelData.act === "pp")   root.player?.togglePlaying()
                            else                               root.player?.next()
                        }
                    }
                }
            }
        }
    }

    // Hover detection — covers only the content row, not a bottom strip
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
    }
}
