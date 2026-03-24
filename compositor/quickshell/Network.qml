import QtQuick
import Quickshell.Io

// Bare network status — lives inside the right group pill in Bar.qml
Item {
    id: root

    property bool connected: false
    property bool isWifi: false
    property string ssid: ""

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 27

    Process {
        id: netProc
        running: true
        command: [
            "bash", "-c",
            "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2-);" +
            "if [ -n \"$ssid\" ]; then echo \"wifi $ssid\";" +
            "elif ip route show default 2>/dev/null | grep -q default; then echo 'eth';" +
            "else echo 'disconnected'; fi"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const t = line.trim()
                if (t.startsWith("wifi ")) {
                    root.connected = true; root.isWifi = true; root.ssid = t.substring(5)
                } else if (t === "eth") {
                    root.connected = true; root.isWifi = false; root.ssid = ""
                } else {
                    root.connected = false; root.ssid = ""
                }
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: netProc.running = true }
    Process { id: nmtuiProc; command: ["kitty", "-e", "nmtui"] }

    Text {
        id: label
        anchors.centerIn: parent
        text: !root.connected ? "󰌙" : root.isWifi ? "󰤨 " + root.ssid : ""
        color: root.connected ? "#9b7bc4" : "#8878a8"   // primary / outline
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea { anchors.fill: parent; onClicked: nmtuiProc.running = true }
}
