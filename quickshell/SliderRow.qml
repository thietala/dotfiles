import QtQuick
import QtQuick.Controls.Basic

// ── SliderRow ─────────────────────────────────────────────────────────────────
// Icon + styled Slider. Signals changed(value) while dragging and on release.
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: root

    property string icon:  ""
    property real   value: 0      // 0–100
    property real   min:   0
    property real   max:   100
    signal changed(real newValue)

    implicitWidth:  300
    implicitHeight: 28

    readonly property color  clrAccent:  "#9b7bc4"
    readonly property color  clrTrack:   Qt.rgba(110/255, 85/255, 150/255, 0.25)
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    Row {
        anchors.fill: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text:  root.icon
            color: root.clrAccent
            font { family: root.fontFamily; pixelSize: 14 }
            width: 18
            horizontalAlignment: Text.AlignHCenter
        }

        Slider {
            id: slider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 18 - parent.spacing

            from:  root.min
            to:    root.max
            value: root.value

            onMoved: root.changed(value)

            background: Rectangle {
                x:      slider.leftPadding
                y:      slider.topPadding + slider.availableHeight / 2 - height / 2
                width:  slider.availableWidth
                height: 4
                radius: 2
                color:  root.clrTrack

                Rectangle {
                    width:  slider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color:  root.clrAccent
                }
            }

            handle: Rectangle {
                x:      slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y:      slider.topPadding  + slider.availableHeight / 2 - height / 2
                width:  14; height: 14; radius: 7
                color:  root.clrAccent
                opacity: slider.pressed ? 0.8 : 1.0
                Behavior on opacity { NumberAnimation { duration: 80 } }
            }
        }
    }
}
