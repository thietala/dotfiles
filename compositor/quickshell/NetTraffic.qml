import QtQuick
import Quickshell.Io

// Bare network traffic — lives inside the right group pill in Bar.qml
Item {
    id: root

    property int upBytes: 0
    property int downBytes: 0

    function fmt(b) {
        if (b < 1024)         return b.toFixed(0) + "B"
        if (b < 1024 * 1024)  return (b / 1024).toFixed(1) + "K"
        return (b / 1024 / 1024).toFixed(1) + "M"
    }

    implicitWidth: label.implicitWidth + 16
    implicitHeight: 27

    Process {
        id: netProc
        running: true
        command: [
            "bash", "-c",
            "prev=''; while true; do\n" +
            "  cur=$(awk '/:/ && !/lo:/ {rx+=$2; tx+=$10} END {print rx\" \"tx}' /proc/net/dev)\n" +
            "  if [ -n \"$prev\" ]; then\n" +
            "    pr=$(echo $prev | cut -d' ' -f1)\n" +
            "    pt=$(echo $prev | cut -d' ' -f2)\n" +
            "    cr=$(echo $cur  | cut -d' ' -f1)\n" +
            "    ct=$(echo $cur  | cut -d' ' -f2)\n" +
            "    echo \"$(( (ct-pt)/2 )) $(( (cr-pr)/2 ))\"\n" +
            "  fi\n" +
            "  prev=$cur; sleep 2\n" +
            "done"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.trim().split(" ")
                if (parts.length >= 2) {
                    root.upBytes   = parseInt(parts[0]) || 0
                    root.downBytes = parseInt(parts[1]) || 0
                }
            }
        }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: " " + root.fmt(root.upBytes) + "  " + root.fmt(root.downBytes)
        color: "#a898c8"    // secondary (blue-gray)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
    }

    Process { id: nmtuiProc; command: ["kitty", "-e", "nmtui"] }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: nmtuiProc.running = true }
}
