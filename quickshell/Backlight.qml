import QtQuick
import Quickshell.Io

// Bare brightness — lives inside the right group pill in Bar.qml
Item {
    id: root

    property int percent: 0

    function icon(p) {
        const icons = ["", "", "", "", "", "", "", "", ""]
        return icons[Math.min(Math.floor(p / 100 * (icons.length - 1)), icons.length - 1)]
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 27

    Process {
        id: brightProc
        running: true
        command: [
            "bash", "-c",
            "b=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1);" +
            "m=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1);" +
            "[ -n \"$b\" ] && [ -n \"$m\" ] && echo $((b * 100 / m)) || echo 0"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { const v = parseInt(line.trim()); if (!isNaN(v)) root.percent = v }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; onTriggered: brightProc.running = true }

    Process { id: brightUp;   command: ["brightnessctl", "-e4", "-n2", "set", "2%+"] }
    Process { id: brightDown; command: ["brightnessctl", "-e4", "-n2", "set", "2%-"] }
    Timer   { id: repoll; interval: 150; onTriggered: brightProc.running = true }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon(root.percent) + " " + root.percent + "%"
        color: "#c4b8d8"     // tertiary (soft purple)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onWheel: wheel => {
            wheel.angleDelta.y > 0 ? brightUp.running = true : brightDown.running = true
            repoll.restart()
        }
    }
}
