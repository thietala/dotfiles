import QtQuick
import QtQuick.Controls

// Bare clock — sits inside the centre dock, no own background
Item {
    id: root

    property var now: new Date()

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "HH:mm")
        color: "#e8e0f0"     // on_surface
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14

        ToolTip {
            visible: hover.containsMouse
            text: Qt.formatDateTime(root.now, "ddd dd MMM, HH:mm:ss")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
