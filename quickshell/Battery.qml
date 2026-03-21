import QtQuick
import Quickshell.Io

// Bare battery — lives inside the right group pill in Bar.qml
Item {
    id: root

    property int capacity: 100
    property string status: "Unknown"

    function icon() {
        if (status === "Charging") return "󰂄 "
        if (status === "Full")     return "󰚥 "
        if (capacity <= 10) return "󰁺"
        if (capacity <= 20) return "󰁻"
        if (capacity <= 30) return "󰁼"
        if (capacity <= 40) return "󰁽"
        if (capacity <= 50) return "󰁾"
        if (capacity <= 60) return "󰁿"
        if (capacity <= 70) return "󰂀"
        if (capacity <= 80) return "󰂁"
        if (capacity <= 90) return "󰂂"
        return "󰁹"
    }

    function textColor() {
        if (status === "Charging") return "#9b7bc4"   // primary
        if (capacity <= 15)        return "#ffb4ab"   // error
        if (capacity <= 30)        return "#d4c8e8"   // tertiary (warning)
        return "#9b7bc4"                              // primary
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 27

    Process {
        id: battProc
        running: true
        command: [
            "bash", "-c",
            "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1);" +
            "sts=$(cat /sys/class/power_supply/BAT*/status   2>/dev/null | head -1);" +
            "echo \"${cap:-0} ${sts:-Unknown}\""
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(" ")
                if (parts.length >= 2) { root.capacity = parseInt(parts[0]) || 0; root.status = parts[1] }
            }
        }
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: battProc.running = true }

    SequentialAnimation on opacity {
        running: root.capacity <= 15 && root.status === "Discharging"
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 500 }
        NumberAnimation { to: 1.0; duration: 500 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon() + root.capacity + "%"
        color: root.textColor()
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }
}
