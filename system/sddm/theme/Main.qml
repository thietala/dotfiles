import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#1a0e38"
    opacity: 0

    readonly property color clrPrimary: "#9b7bc4"
    readonly property color clrText:    "#e8e0f0"
    readonly property color clrMuted:   "#8878a8"
    readonly property color clrBorder:  Qt.rgba(110/255, 85/255, 150/255, 0.35)
    readonly property color clrError:   "#ffb4ab"

    property int userIndex:    userModel.lastIndex
    property int sessionIndex: sessionModel.lastIndex
    property string loginUsername: ""
    property string pendingUser: ""
    property string pendingPass: ""

    Repeater {
        id: userUpdater
        model: userModel
        delegate: Item {
            visible: false
            function check() { if (index === root.userIndex) root.loginUsername = name }
            Component.onCompleted: check()
        }
    }
    onUserIndexChanged: { for (var i = 0; i < userUpdater.count; i++) userUpdater.itemAt(i).check() }

    // ── Fade-in ───────────────────────────────────────────────────────────────
    NumberAnimation on opacity { from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic; running: true }

    // ── Wallpaper ─────────────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background !== undefined ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: source !== ""
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(26/255, 14/255, 56/255, 0.72) }

    // ── Greeting ──────────────────────────────────────────────────────────────
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: clock.top; bottomMargin: 16 }
        text: { var h = new Date().getHours(); return h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening" }
        color: Qt.rgba(168/255, 152/255, 200/255, 0.85)
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.italic: true
    }

    // ── Clock ─────────────────────────────────────────────────────────────────
    Text {
        id: clock
        anchors { horizontalCenter: parent.horizontalCenter; bottom: dateLine.top; bottomMargin: 4 }
        color: root.clrText
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 100
        Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm") }
    }

    // ── Date ──────────────────────────────────────────────────────────────────
    Text {
        id: dateLine
        anchors { horizontalCenter: parent.horizontalCenter; bottom: divider.top; bottomMargin: 20 }
        color: root.clrPrimary
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
        Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: dateLine.text = Qt.formatDate(new Date(), "dddd, dd MMMM yyyy") }
    }

    Text {
        id: divider
        anchors { horizontalCenter: parent.horizontalCenter; bottom: card.top; bottomMargin: 28 }
        text: "───────────────────────"
        color: Qt.rgba(110/255, 85/255, 150/255, 0.40)
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
    }

    // ── Login card ────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 340; height: col.height + 48
        color: Qt.rgba(35/255, 18/255, 72/255, 0.65)
        radius: 20; border.width: 1; border.color: root.clrBorder

        transform: Translate { id: cardSlide; y: 32 }
        NumberAnimation on opacity { from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic; running: true }
        NumberAnimation { target: cardSlide; property: "y"; from: 32; to: 0; duration: 700; easing.type: Easing.OutCubic; running: true }

        Rectangle { // specular edge
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            height: 1; radius: 1; color: Qt.rgba(1, 1, 1, 0.08)
        }

        Column {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right
                      topMargin: 24; leftMargin: 24; rightMargin: 24 }
            spacing: 14

            // Avatar
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: root.clrPrimary
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 40
            }

            // ── Username ───────────────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 42
                color: Qt.rgba(26/255, 14/255, 56/255, 0.60)
                radius: 10; border.width: 1; border.color: root.clrBorder

                Rectangle { // left arrow (hidden if single user)
                    visible: userModel.count > 1
                    width: 40; height: parent.height; radius: 10
                    anchors.left: parent.left
                    color: uL.containsMouse ? Qt.rgba(110/255,85/255,150/255,0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: ""; color: root.clrMuted
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    MouseArea { id: uL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.userIndex = (root.userIndex - 1 + userModel.count) % userModel.count }
                }
                Text {
                    anchors.centerIn: parent
                    text: "  " + root.loginUsername; color: root.clrText
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                }
                Rectangle { // right arrow
                    visible: userModel.count > 1
                    width: 40; height: parent.height; radius: 10
                    anchors.right: parent.right
                    color: uR.containsMouse ? Qt.rgba(110/255,85/255,150/255,0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: ""; color: root.clrMuted
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    MouseArea { id: uR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.userIndex = (root.userIndex + 1) % userModel.count }
                }
            }

            // ── Password ───────────────────────────────────────────────────
            Rectangle {
                id: passBox
                width: parent.width; height: 42
                color: Qt.rgba(26/255, 14/255, 56/255, 0.60)
                radius: 10; border.width: 1
                border.color: passInput.activeFocus ? root.clrPrimary : root.clrBorder
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Shake via Translate so Column layout is not disturbed
                transform: Translate { id: passShake }

                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: passShake; property: "x"; to: -14; duration: 45; easing.type: Easing.OutQuad }
                    NumberAnimation { target: passShake; property: "x"; to:  14; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passShake; property: "x"; to: -10; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passShake; property: "x"; to:  10; duration: 45; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passShake; property: "x"; to:  -5; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: passShake; property: "x"; to:   0; duration: 40; easing.type: Easing.OutBounce }
                }

                ColorAnimation {
                    id: errorFlash
                    target: passBox; property: "border.color"
                    from: "#e06b6b"; to: passInput.activeFocus ? root.clrPrimary : root.clrBorder
                    duration: 1000
                }

                Text {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                    text: "  password"; color: root.clrMuted
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                    visible: passInput.text.length === 0 && !passInput.activeFocus
                }
                TextInput {
                    id: passInput
                    anchors { verticalCenter: parent.verticalCenter
                              left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                    echoMode: TextInput.Password
                    color: root.clrText
                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                    selectionColor: Qt.rgba(155/255, 123/255, 196/255, 0.4)
                    selectedTextColor: root.clrText
                    Keys.onReturnPressed: doLogin()
                    Component.onCompleted: forceActiveFocus()
                }
            }

            // ── Session selector ───────────────────────────────────────────
            Rectangle {
                width: parent.width; height: 42
                color: Qt.rgba(26/255, 14/255, 56/255, 0.60)
                radius: 10; border.width: 1; border.color: root.clrBorder

                Rectangle { // left arrow
                    width: 40; height: parent.height; radius: 10; anchors.left: parent.left
                    color: sL.containsMouse ? Qt.rgba(110/255,85/255,150/255,0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: ""; color: root.clrMuted
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    MouseArea { id: sL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.sessionIndex = (root.sessionIndex - 1 + sessionModel.count) % sessionModel.count }
                }

                Repeater {
                    model: sessionModel
                    delegate: Text {
                        anchors.centerIn: parent
                        visible: index === root.sessionIndex
                        text: "  " + name; color: root.clrMuted
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12
                    }
                }

                Rectangle { // right arrow
                    width: 40; height: parent.height; radius: 10; anchors.right: parent.right
                    color: sR.containsMouse ? Qt.rgba(110/255,85/255,150/255,0.20) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: ""; color: root.clrMuted
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    MouseArea { id: sR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessionModel.count }
                }
            }

            // Error message
            Text {
                id: errorMsg
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""; color: root.clrError
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.italic: true
                visible: text !== ""
                opacity: 0
                NumberAnimation on opacity { id: errorFadeIn; from: 0; to: 1; duration: 300; running: false }
            }

            // Login button
            Rectangle {
                id: loginBtn
                width: parent.width; height: 42; radius: 10
                color: loginHover.containsMouse
                    ? Qt.rgba(155/255, 123/255, 196/255, 0.35)
                    : Qt.rgba(155/255, 123/255, 196/255, 0.18)
                border.width: 1
                border.color: loginHover.containsMouse ? root.clrPrimary : root.clrBorder
                Behavior on color        { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                transform: Scale { id: btnScale; origin.x: loginBtn.width/2; origin.y: loginBtn.height/2 }
                SequentialAnimation {
                    id: btnPress
                    NumberAnimation { target: btnScale; property: "xScale"; to: 0.96; duration: 80; easing.type: Easing.OutQuad }
                    NumberAnimation { target: btnScale; property: "yScale"; to: 0.96; duration: 80; easing.type: Easing.OutQuad }
                    NumberAnimation { target: btnScale; property: "xScale"; to: 1.00; duration: 200; easing.type: Easing.OutElastic }
                    NumberAnimation { target: btnScale; property: "yScale"; to: 1.00; duration: 200; easing.type: Easing.OutElastic }
                }

                Text { anchors.centerIn: parent; text: "  Login"; color: root.clrText
                       font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }

                MouseArea { id: loginHover; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
            }
        }
    }

    // ── Login success overlay ─────────────────────────────────────────────────
    Rectangle {
        id: loginOverlay
        anchors.fill: parent
        z: 999
        color: Qt.rgba(26/255, 14/255, 56/255, 0.82)
        opacity: 0
        visible: opacity > 0

        NumberAnimation {
            id: fadeToBlack
            target: loginOverlay; property: "opacity"
            from: 0; to: 1; duration: 350; easing.type: Easing.InCubic
            onStopped: {
                if (loginOverlay.opacity >= 1)
                    sddm.login(root.pendingUser, root.pendingPass, root.sessionIndex)
            }
        }

        NumberAnimation {
            id: fadeFromBlack
            target: loginOverlay; property: "opacity"
            from: 1; to: 0; duration: 350; easing.type: Easing.OutCubic
        }
    }

    // ── Power buttons ─────────────────────────────────────────────────────────
    Row {
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 32 }
        spacing: 24
        Repeater {
            model: [ { icon: "󰒲", label: "Suspend", act: "suspend" },
                     { icon: "󰜉", label: "Reboot",  act: "reboot"  },
                     { icon: "⏻",  label: "Shutdown",act: "shutdown"} ]
            delegate: Column {
                spacing: 6
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: pwrHover.containsMouse ? Qt.rgba(110/255,85/255,150/255,0.28) : Qt.rgba(35/255,18/255,72/255,0.55)
                    border.width: 1
                    border.color: pwrHover.containsMouse ? root.clrPrimary : root.clrBorder
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: modelData.icon; color: root.clrText
                           font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
                    MouseArea { id: pwrHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { if (modelData.act === "suspend") sddm.suspend()
                                             else if (modelData.act === "reboot") sddm.reboot()
                                             else sddm.powerOff() } }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label
                       color: root.clrMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
            }
        }
    }

    // ── Auth ──────────────────────────────────────────────────────────────────
    function doLogin() {
        errorMsg.text = ""
        root.pendingUser = root.loginUsername
        root.pendingPass = passInput.text
        passInput.text = ""
        btnPress.start()
        fadeToBlack.start()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            fadeFromBlack.start()
            passInput.forceActiveFocus()
            errorMsg.text = "Incorrect password"
            errorMsg.opacity = 0
            errorFadeIn.running = true
            shakeAnim.start()
            errorFlash.running = true
        }
    }
}
