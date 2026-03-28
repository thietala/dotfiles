import QtQuick
import QtQuick.Controls

// Bare clock — sits inside the centre dock, no own background.
// Emits clicked() so Bar.qml can toggle the Control Center.
Item {
    id: root

    signal clicked()
    signal hovered()
    signal exited()

    property var now: new Date()

    implicitWidth: label.implicitWidth + 8   // a little breathing room for the hover target
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
        color: hover.containsMouse ? "#9b7bc4" : "#e8e0f0"   // accent on hover
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        Behavior on color { ColorAnimation { duration: 120 } }

    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked:  root.clicked()
        onEntered:  root.hovered()
        onExited:   root.exited()
    }
}
