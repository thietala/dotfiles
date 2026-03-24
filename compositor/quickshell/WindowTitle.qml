import QtQuick
import Quickshell.Hyprland

Item {
    property string title: Hyprland.activeToplevel?.title ?? ""

    visible: title.length > 0
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: title.length > 55 ? title.substring(0, 52) + "…" : title
        color: "#e8e0f0"
        font.italic: true
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }
}
