import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris

// ── ControlCenter ─────────────────────────────────────────────────────────────
// Pure content item — no animation logic here.
// ControlCenterWindow.qml owns the window and all grow/shrink animations.
// Set `active = true` when the panel is open so background processes run.
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: root

    signal closeRequested()

    // ── Geometry ──────────────────────────────────────────────────────────────
    width:  520
    height: card.implicitHeight + 12    // 12 px bottom breathing room

    // Set by ControlCenterWindow when the panel is open/closed
    property bool active: false

    // ── Palette ───────────────────────────────────────────────────────────────
    readonly property color clrBg:      Qt.rgba(22/255,  11/255, 46/255,  0.92)
    readonly property color clrSurface: Qt.rgba(35/255,  18/255, 72/255,  0.65)
    readonly property color clrAccent:  "#9b7bc4"
    readonly property color clrText:    "#e8e0f0"
    readonly property color clrMuted:   "#8878a8"
    readonly property color clrBorder:  Qt.rgba(110/255, 85/255, 150/255, 0.35)
    readonly property string fontFam:   "JetBrainsMono Nerd Font"

    // ── MPRIS player selection (mirrors Mpris.qml logic) ──────────────────────
    property var mprisPlayer: {
        const players = Mpris.players.values
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing &&
                !p.identity.toLowerCase().includes("firefox"))
                return p
        }
        for (const p of players) {
            if (!p.identity.toLowerCase().includes("firefox")) return p
        }
        return null
    }
    property bool mprisPlaying: mprisPlayer?.playbackState === MprisPlaybackState.Playing

    // ── Toggle state ──────────────────────────────────────────────────────────
    property bool dndEnabled:        false
    property bool nightLightEnabled: false

    // ── Volume (pactl / wpctl) ────────────────────────────────────────────────
    property int  volumeValue: 50

    Process {
        id: volReadProc
        running: root.active
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const m = line.match(/Volume:\s+([0-9.]+)/)
                if (m) root.volumeValue = Math.round(parseFloat(m[1]) * 100)
            }
        }
    }
    Timer {
        interval: 3000; running: root.active; repeat: true
        onTriggered: volReadProc.running = true
    }
    Process {
        id: volSetProc
        command: ["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", root.volumeValue + "%"]
    }
    // Repoll after a set
    Timer { id: volRepoll; interval: 120; onTriggered: volReadProc.running = true }

    // ── Brightness (brightnessctl) ─────────────────────────────────────────────
    property int brightnessValue: 50

    Process {
        id: brightReadProc
        running: root.active
        command: [
            "bash", "-c",
            "b=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1);" +
            "m=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1);" +
            "[ -n \"$b\" ] && [ -n \"$m\" ] && echo $((b * 100 / m)) || echo 0"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => { const v = parseInt(line.trim()); if (!isNaN(v)) root.brightnessValue = v }
        }
    }
    Timer {
        interval: 3000; running: root.active; repeat: true
        onTriggered: brightReadProc.running = true
    }
    Process {
        id: brightSetProc
        command: ["brightnessctl", "set", root.brightnessValue + "%"]
    }
    Timer { id: brightRepoll; interval: 120; onTriggered: brightReadProc.running = true }

    // ── CPU & RAM stats (every 2 s, only when visible) ────────────────────────
    property real cpuPercent: 0
    property real ramPercent: 0

    Process {
        id: statsProc
        running: root.active
        // One-liner: cpu% via /proc/stat, ram% via /proc/meminfo
        command: [
            "bash", "-c",
            // CPU: read two snapshots 500 ms apart
            "read -r c1 </proc/stat;" +
            "sleep 0.5;" +
            "read -r c2 </proc/stat;" +
            "awk -v a=\"$c1\" -v b=\"$c2\" 'BEGIN{" +
            "  split(a,A); split(b,B);" +
            "  iA=A[2]+A[3]+A[4]+A[5]+A[6]+A[7]+A[8];" +
            "  iB=B[2]+B[3]+B[4]+B[5]+B[6]+B[7]+B[8];" +
            "  idA=A[5]; idB=B[5];" +
            "  dt=iB-iA; didle=idB-idA;" +
            "  cpu=(dt>0)?(dt-didle)/dt*100:0;" +
            "  printf \"cpu=%.1f\\n\", cpu" +
            "}'" +
            // RAM
            "&& awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"ram=%.1f\\n\",(t-a)/t*100}' /proc/meminfo"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const cpu = line.match(/^cpu=([0-9.]+)/)
                const ram = line.match(/^ram=([0-9.]+)/)
                if (cpu) root.cpuPercent = parseFloat(cpu[1])
                if (ram) root.ramPercent = parseFloat(ram[1])
            }
        }
    }
    Timer {
        interval: 2000; running: root.active; repeat: true
        onTriggered: statsProc.running = true
    }

    // ── Wallpaper list ────────────────────────────────────────────────────────
    // We list ~/Pictures/wallpapers and build a model from the output
    property var wallpapers: []

    Process {
        id: wallpaperListProc
        running: root.active
        command: ["bash", "-c",
            "ls ~/Pictures/wallpapers/*.{jpg,jpeg,png,webp} 2>/dev/null | head -40"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const p = line.trim()
                if (p.length > 0) {
                    // Append to array — create a new array so QML sees the change
                    root.wallpapers = root.wallpapers.concat([p])
                }
            }
        }
        onRunningChanged: {
            if (running) root.wallpapers = []    // reset before each refresh
        }
    }

    Process {
        id: wallpaperSetProc
        // command set dynamically — preloads first, then sets
        command: ["bash", "-c", "true"]
    }

    // ── Toggle processes ──────────────────────────────────────────────────────
    Process { id: dndToggleProc;    command: ["swaync-client", "--toggle-dnd"] }
    Process { id: nightLightOnProc; command: ["hyprsunset", "-t", "4500"] }
    Process { id: nightLightOffProc;command: ["pkill", "hyprsunset"] }

    // ── Pinned apps ───────────────────────────────────────────────────────────
    readonly property var pinnedApps: [
        { label: "Firefox",   icon: "󰈹", cmd: ["firefox"] },
        { label: "Kitty",     icon: "", cmd: ["kitty"] },
        { label: "Files",     icon: "󰝰", cmd: ["kitty", "-e", "lf"] },
        { label: "VSCodium",  icon: "󰨞", cmd: ["vscodium"] },
        { label: "PlexAmp",   icon: "󰎖", cmd: ["flatpak", "run", "com.plexamp.Plexamp"] },
        { label: "PulseAudio",icon: "󰓃", cmd: ["pavucontrol"] }
    ]

    // ── Calendar state ────────────────────────────────────────────────────────
    property var calDate: new Date()    // controls which month is displayed

    function calPrev() {
        const d = new Date(root.calDate)
        d.setDate(1)
        d.setMonth(d.getMonth() - 1)
        root.calDate = d
    }
    function calNext() {
        const d = new Date(root.calDate)
        d.setDate(1)
        d.setMonth(d.getMonth() + 1)
        root.calDate = d
    }

    // ── Main card ─────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        width: root.width
        // Let height be driven by the column's content
        implicitHeight: mainCol.implicitHeight + 24
        height: implicitHeight

        // Background and border are now owned by ControlCenterWindow
        color: "transparent"

        Column {
            id: mainCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
            spacing: 14

            // ── Header ───────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 32

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Control Center"
                    color: root.clrText
                    font { family: root.fontFam; pixelSize: 15; bold: true }
                }

                // Close button
                Text {
                    id: closeBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "󰅖"
                    color: closeBtnHover.containsMouse ? root.clrAccent : root.clrMuted
                    font { family: root.fontFam; pixelSize: 16 }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: closeBtnHover }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width; height: 1
                color: root.clrBorder
            }

            // ── Music player ─────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: musicRow.implicitHeight + 20
                color: root.clrSurface
                radius: 10
                border.width: 1; border.color: root.clrBorder
                visible: root.mprisPlayer !== null

                Row {
                    id: musicRow
                    anchors { fill: parent; margins: 10 }
                    spacing: 14

                    // Album art
                    Rectangle {
                        id: ccArtBox
                        width: 80; height: 80; radius: 8
                        color: Qt.rgba(35/255, 18/255, 65/255, 1)
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.fill: parent
                            source: root.mprisPlayer?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            text: ""; color: root.clrMuted
                            font { family: root.fontFam; pixelSize: 28 }
                            visible: parent.children[0]?.status !== Image.Ready
                        }
                    }

                    // Track info + controls
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - ccArtBox.width - parent.spacing
                        spacing: 6

                        Text {
                            width: parent.width
                            text: root.mprisPlayer?.trackTitle ?? "—"
                            color: root.clrText
                            font { family: root.fontFam; pixelSize: 13; bold: true }
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: root.mprisPlayer?.trackArtist ?? ""
                            color: root.clrAccent
                            font { family: root.fontFam; pixelSize: 11 }
                            elide: Text.ElideRight
                            visible: text !== ""
                        }

                        // Prev / Play-Pause / Next
                        Row {
                            spacing: 18
                            Repeater {
                                model: [
                                    { icon: "󰒮", act: "prev", sz: 18 },
                                    { icon: root.mprisPlaying ? "󰏤" : "󰐊", act: "pp", sz: 26 },
                                    { icon: "󰒭", act: "next", sz: 18 }
                                ]
                                delegate: Text {
                                    required property var modelData
                                    text: modelData.icon
                                    color: mBtnHover.containsMouse ? root.clrAccent : root.clrText
                                    font { family: root.fontFam; pixelSize: modelData.sz }
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    HoverHandler { id: mBtnHover }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -8
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if      (modelData.act === "prev") root.mprisPlayer?.previous()
                                            else if (modelData.act === "pp")   root.mprisPlayer?.togglePlaying()
                                            else                               root.mprisPlayer?.next()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Middle row: calendar  |  toggles + sliders ───────────────────
            Row {
                width: parent.width
                spacing: 12
                height: Math.max(calCard.implicitHeight, rightCol.implicitHeight)

                // ── Left: mini calendar ───────────────────────────────────────
                Rectangle {
                    id: calCard
                    width: (parent.width - parent.spacing) / 2
                    implicitHeight: calCol.implicitHeight + 20
                    height: implicitHeight
                    color: root.clrSurface
                    radius: 10
                    border.width: 1; border.color: root.clrBorder

                    Column {
                        id: calCol
                        anchors { fill: parent; margins: 10 }
                        spacing: 8

                        // Month navigation row
                        Item {
                            width: parent.width; height: 24

                            Text {
                                id: prevMonthBtn
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "󰍞"
                                color: prevMonthHover.containsMouse ? root.clrAccent : root.clrMuted
                                font { family: root.fontFam; pixelSize: 16 }
                                Behavior on color { ColorAnimation { duration: 100 } }
                                HoverHandler { id: prevMonthHover }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.calPrev()
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatDate(root.calDate, "MMMM yyyy")
                                color: root.clrText
                                font { family: root.fontFam; pixelSize: 12; bold: true }
                            }

                            Text {
                                id: nextMonthBtn
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                text: "󰍟"
                                color: nextMonthHover.containsMouse ? root.clrAccent : root.clrMuted
                                font { family: root.fontFam; pixelSize: 16 }
                                Behavior on color { ColorAnimation { duration: 100 } }
                                HoverHandler { id: nextMonthHover }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.calNext()
                                }
                            }
                        }

                        // Day-of-week header
                        Row {
                            width: parent.width
                            Repeater {
                                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                delegate: Text {
                                    required property string modelData
                                    width: calCol.width / 7
                                    text: modelData
                                    color: root.clrMuted
                                    font { family: root.fontFam; pixelSize: 9 }
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Day grid — up to 6 weeks × 7 days
                        Column {
                            id: dayGridCol
                            width: parent.width
                            spacing: 2

                            // Build the grid model: array of day numbers (0 = blank)
                            property var dayGrid: {
                                const y = root.calDate.getFullYear()
                                const m = root.calDate.getMonth()
                                const first = new Date(y, m, 1).getDay()   // 0=Sun
                                const last  = new Date(y, m + 1, 0).getDate()
                                let cells = []
                                for (let i = 0; i < first; i++) cells.push(0)
                                for (let d = 1; d <= last; d++) cells.push(d)
                                // Pad to full week rows
                                while (cells.length % 7 !== 0) cells.push(0)
                                return cells
                            }

                            property int todayDay: {
                                const now = new Date()
                                const y = root.calDate.getFullYear()
                                const m = root.calDate.getMonth()
                                if (now.getFullYear() === y && now.getMonth() === m)
                                    return now.getDate()
                                return -1
                            }

                            Repeater {
                                model: Math.ceil(parent.dayGrid.length / 7)
                                delegate: Row {
                                    required property int index
                                    readonly property int weekStart: index * 7
                                    width: calCol.width

                                    Repeater {
                                        model: 7
                                        delegate: Item {
                                            required property int index
                                            readonly property int day: dayGridCol.dayGrid[parent.weekStart + index] ?? 0
                                            readonly property bool isToday: day > 0 && day === dayGridCol.todayDay

                                            width: calCol.width / 7
                                            height: 20

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 18; height: 18; radius: 9
                                                color: parent.isToday ? root.clrAccent : "transparent"
                                                visible: parent.day > 0
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: parent.day > 0 ? parent.day : ""
                                                color: parent.isToday ? "#ffffff" : root.clrText
                                                font { family: root.fontFam; pixelSize: 10 }
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Right: toggles + sliders ──────────────────────────────────
                Column {
                    id: rightCol
                    width: (parent.width - parent.spacing) / 2
                    spacing: 10

                    // Quick toggles row
                    Rectangle {
                        width: parent.width
                        height: toggleRow.implicitHeight + 16
                        color: root.clrSurface
                        radius: 10
                        border.width: 1; border.color: root.clrBorder

                        Row {
                            id: toggleRow
                            anchors { fill: parent; margins: 8 }
                            spacing: 10

                            // Generic toggle button component
                            component ToggleBtn: Rectangle {
                                id: tbRoot
                                property string icon:    ""
                                property string label:   ""
                                property bool   active:  false
                                signal tapped()

                                width:  (rightCol.width - 10) / 2 - 8   // half minus padding
                                height: 44; radius: 8
                                color:  active
                                    ? Qt.rgba(155/255, 123/255, 196/255, 0.25)
                                    : Qt.rgba(35/255,  18/255,  72/255,  0.50)
                                border.width: 1
                                border.color: active ? root.clrAccent : root.clrBorder

                                Behavior on color        { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tbRoot.icon
                                        color: tbRoot.active ? root.clrAccent : root.clrMuted
                                        font { family: root.fontFam; pixelSize: 16 }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tbRoot.label
                                        color: tbRoot.active ? root.clrText : root.clrMuted
                                        font { family: root.fontFam; pixelSize: 9 }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tbRoot.tapped()
                                }
                            }

                            // Do Not Disturb
                            ToggleBtn {
                                icon:   root.dndEnabled ? "󰂛" : "󰂚"
                                label:  "Do Not Disturb"
                                active: root.dndEnabled
                                onTapped: {
                                    root.dndEnabled = !root.dndEnabled
                                    dndToggleProc.running = true
                                }
                            }

                            // Night Light
                            ToggleBtn {
                                icon:   root.nightLightEnabled ? "󰛨" : "󰖔"
                                label:  "Night Light"
                                active: root.nightLightEnabled
                                onTapped: {
                                    root.nightLightEnabled = !root.nightLightEnabled
                                    if (root.nightLightEnabled) nightLightOnProc.running  = true
                                    else                        nightLightOffProc.running = true
                                }
                            }
                        }
                    }

                    // Volume slider
                    Rectangle {
                        width: parent.width
                        height: 46
                        color: root.clrSurface
                        radius: 10
                        border.width: 1; border.color: root.clrBorder

                        SliderRow {
                            anchors { fill: parent; margins: 10 }
                            icon:  root.volumeValue === 0 ? "󰸈" : (root.volumeValue < 50 ? "󰕾" : "󰕾")
                            value: root.volumeValue
                            onChanged: v => {
                                root.volumeValue = Math.round(v)
                                volSetProc.running = true
                                volRepoll.restart()
                            }
                        }
                    }

                    // Brightness slider
                    Rectangle {
                        width: parent.width
                        height: 46
                        color: root.clrSurface
                        radius: 10
                        border.width: 1; border.color: root.clrBorder

                        SliderRow {
                            anchors { fill: parent; margins: 10 }
                            icon:  "󰃟"
                            value: root.brightnessValue
                            onChanged: v => {
                                root.brightnessValue = Math.round(v)
                                brightSetProc.running = true
                                brightRepoll.restart()
                            }
                        }
                    }
                }
            }

            // ── System stats bar ─────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: statsCol.implicitHeight + 16
                color: root.clrSurface
                radius: 10
                border.width: 1; border.color: root.clrBorder

                Column {
                    id: statsCol
                    anchors { fill: parent; margins: 10 }
                    spacing: 8

                    // CPU
                    Item {
                        width: parent.width; height: 16

                        Text {
                            id: cpuLabel
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "CPU"
                            color: root.clrMuted
                            font { family: root.fontFam; pixelSize: 10 }
                            width: 36
                        }
                        Text {
                            id: cpuPct
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: root.cpuPercent.toFixed(1) + "%"
                            color: root.cpuPercent > 80 ? "#e07878" : root.clrAccent
                            font { family: root.fontFam; pixelSize: 10 }
                            width: 42; horizontalAlignment: Text.AlignRight
                        }
                        Rectangle {
                            anchors {
                                left: cpuLabel.right; right: cpuPct.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 6; rightMargin: 6
                            }
                            height: 4; radius: 2
                            color: Qt.rgba(110/255, 85/255, 150/255, 0.20)
                            Rectangle {
                                width: parent.width * Math.min(root.cpuPercent / 100, 1)
                                height: parent.height; radius: parent.radius
                                color: root.cpuPercent > 80 ? "#e07878" : root.clrAccent
                                Behavior on width { NumberAnimation { duration: 400 } }
                            }
                        }
                    }

                    // RAM
                    Item {
                        width: parent.width; height: 16

                        Text {
                            id: ramLabel
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "RAM"
                            color: root.clrMuted
                            font { family: root.fontFam; pixelSize: 10 }
                            width: 36
                        }
                        Text {
                            id: ramPct
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: root.ramPercent.toFixed(1) + "%"
                            color: root.ramPercent > 80 ? "#e07878" : root.clrAccent
                            font { family: root.fontFam; pixelSize: 10 }
                            width: 42; horizontalAlignment: Text.AlignRight
                        }
                        Rectangle {
                            anchors {
                                left: ramLabel.right; right: ramPct.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 6; rightMargin: 6
                            }
                            height: 4; radius: 2
                            color: Qt.rgba(110/255, 85/255, 150/255, 0.20)
                            Rectangle {
                                width: parent.width * Math.min(root.ramPercent / 100, 1)
                                height: parent.height; radius: parent.radius
                                color: root.ramPercent > 80 ? "#e07878" : root.clrAccent
                                Behavior on width { NumberAnimation { duration: 400 } }
                            }
                        }
                    }
                }
            }

            // ── Wallpaper picker ──────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 116
                color: root.clrSurface
                radius: 10
                border.width: 1; border.color: root.clrBorder
                clip: true

                Column {
                    anchors { fill: parent; margins: 8 }
                    spacing: 6

                    Text {
                        text: "Wallpapers"
                        color: root.clrMuted
                        font { family: root.fontFam; pixelSize: 10 }
                    }

                    ListView {
                        id: wallpaperList
                        width: parent.width
                        height: parent.height - 16 - 6    // subtract label + spacing
                        orientation: ListView.Horizontal
                        spacing: 8
                        clip: true

                        model: root.wallpapers

                        delegate: Rectangle {
                            required property string modelData
                            width: 80; height: wallpaperList.height
                            radius: 6
                            color: Qt.rgba(35/255, 18/255, 72/255, 1)
                            clip: true
                            border.width: wpHover.containsMouse ? 2 : 0
                            border.color: root.clrAccent

                            Behavior on border.width { NumberAnimation { duration: 100 } }

                            Image {
                                anchors.fill: parent
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                            }

                            HoverHandler { id: wpHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wallpaperSetProc.command = [
                                        "bash", "-c",
                                        "$HOME/.config/hypr/set-wallpaper.sh '" + modelData + "'"
                                    ]
                                    wallpaperSetProc.running = true
                                }
                            }
                        }

                        // Placeholder when no wallpapers found
                        Text {
                            anchors.centerIn: parent
                            visible: root.wallpapers.length === 0
                            text: "No images found in ~/Pictures/wallpapers"
                            color: root.clrMuted
                            font { family: root.fontFam; pixelSize: 10 }
                        }
                    }
                }
            }

            // ── Pinned apps row ───────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: appsRow.implicitHeight + 16
                color: root.clrSurface
                radius: 10
                border.width: 1; border.color: root.clrBorder

                Row {
                    id: appsRow
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: root.pinnedApps

                        delegate: Item {
                            required property var modelData

                            // Dynamic process — created per app launch request
                            Process {
                                id: appProc
                                command: modelData.cmd
                            }

                            width: (card.width - 32) / root.pinnedApps.length
                            height: appCol.implicitHeight + 8

                            Column {
                                id: appCol
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: appHover.containsMouse ? root.clrAccent : root.clrText
                                    font { family: root.fontFam; pixelSize: 22 }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: appHover.containsMouse ? root.clrText : root.clrMuted
                                    font { family: root.fontFam; pixelSize: 9 }
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }

                            HoverHandler { id: appHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    appProc.running = true
                                    root.closeRequested()
                                }
                            }
                        }
                    }
                }
            }

            // Bottom padding spacer
            Item { width: 1; height: 2 }
        }
    }
}
