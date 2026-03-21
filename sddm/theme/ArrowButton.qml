import QtQuick 2.15

Rectangle {
    id: btn
    width: 36
    height: 42
    color: area.containsMouse ? Qt.rgba(110/255, 85/255, 150/255, 0.20) : "transparent"
    radius: 10
    property bool mirror: false
    signal clicked()

    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: btn.mirror ? "" : ""
        color: "#8878a8"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
