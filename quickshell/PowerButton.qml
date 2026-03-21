import QtQuick
import Quickshell.Io

Item {
    id: root

    implicitWidth: label.implicitWidth + 8
    implicitHeight: 27

    Process {
        id: wlogout
        command: ["sh", "-c", "wlogout -l ~/.config/wlogout/layout -s ~/.config/wlogout/style.css"]
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: "⏻"
        color: area.containsMouse ? "#e8e0f0" : "#8878a8"
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wlogout.running = true
    }
}
