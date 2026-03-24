import QtQuick
import Quickshell.Io

// Bare bluetooth — lives inside the right group pill in Bar.qml
// Hidden when bluetooth is off
Item {
    id: root

    property string btStatus: "off"
    property string deviceName: ""

    visible: btStatus !== "off"
    implicitWidth: visible ? label.implicitWidth + 10 : 0
    implicitHeight: 27

    Process {
        id: btProc
        running: true
        command: [
            "bash", "-c",
            "power=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}');" +
            "if [ \"$power\" = 'yes' ]; then" +
            "  dev=$(bluetoothctl info 2>/dev/null | awk '/Name:/{$1=\"\"; sub(/^ /,\"\"); print; exit}');" +
            "  [ -n \"$dev\" ] && echo \"connected $dev\" || echo 'on';" +
            "else echo 'off'; fi"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const t = line.trim()
                if (t.startsWith("connected ")) {
                    root.btStatus = "connected"; root.deviceName = t.substring(10)
                } else {
                    root.btStatus = t; root.deviceName = ""
                }
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: btProc.running = true }
    Process { id: bluemanProc; command: ["blueman-manager"] }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.btStatus === "connected" ? " " + root.deviceName : ""
        color: "#9b7bc4"    // primary
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }

    MouseArea { anchors.fill: parent; onClicked: bluemanProc.running = true }
}
