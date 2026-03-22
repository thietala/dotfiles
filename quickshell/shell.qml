import Quickshell

// Entry point — one Bar per monitor, one Control Center on the primary screen
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    ControlCenterWindow {
        screen: Quickshell.screens[0]
    }
}
