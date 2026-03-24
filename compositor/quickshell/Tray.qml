import QtQuick
import Quickshell.Services.SystemTray

// Bare tray — lives inside the right group pill in Bar.qml
Item {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth + 8 : 0
    implicitHeight: 27

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Item {
                required property SystemTrayItem modelData

                implicitWidth: 16
                implicitHeight: 16

                Image {
                    anchors.fill: parent
                    source: modelData.icon
                    smooth: true
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        mouse.button === Qt.LeftButton
                            ? modelData.activate()
                            : modelData.showContextMenu(mouse.x, mouse.y)
                    }
                }
            }
        }
    }
}
