import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root

    // Bind the default sink so it stays tracked and writable
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    readonly property var  sink:   Pipewire.defaultAudioSink
    readonly property int  volume: sink?.ready ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted:  sink?.ready ? sink.audio.muted : false

    function icon() {
        if (muted || volume === 0) return ""
        if (volume < 33) return ""
        if (volume < 66) return ""
        return ""
    }

    implicitWidth:  label.implicitWidth + 16
    implicitHeight: 27

    Text {
        id: label
        anchors.centerIn: parent
        text:  root.icon() + " " + root.volume + "%"
        color: root.muted ? "#8878a8" : "#9b7bc4"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
    }

    Process { id: pavuProc; command: ["pavucontrol"] }

    MouseArea {
        anchors.fill: parent
        onClicked: pavuProc.running = true
        onWheel: wheel => {
            const sink = root.sink
            if (!sink?.ready) return
            const step = 0.02
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (wheel.angleDelta.y > 0 ? step : -step)))
        }
    }
}
