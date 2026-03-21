import QtQuick
import Quickshell.Io

// Bare volume — lives inside the right group pill in Bar.qml
Item {
    id: root

    property int volume: 0
    property bool muted: false

    function icon() {
        if (muted || volume === 0) return ""
        if (volume < 33) return ""
        if (volume < 66) return ""
        return ""
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 27

    Process {
        id: volProc
        running: true
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const m = line.match(/Volume:\s+([0-9.]+)(\s+\[MUTED\])?/)
                if (m) {
                    root.volume = Math.round(parseFloat(m[1]) * 100)
                    root.muted  = !!m[2]
                }
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: volProc.running = true }

    Process { id: volUp;   command: ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", "2%+"] }
    Process { id: volDown; command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "2%-"] }
    Process { id: pavuProc; command: ["pavucontrol"] }
    Timer   { id: repoll; interval: 150; onTriggered: volProc.running = true }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon() + " " + root.volume + "%"
        color: root.muted ? "#8878a8" : "#9b7bc4"   // outline / primary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: pavuProc.running = true
        onWheel: wheel => {
            wheel.angleDelta.y > 0 ? volUp.running = true : volDown.running = true
            repoll.restart()
        }
    }
}
