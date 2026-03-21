import Quickshell

// Entry point — one Bar instance per monitor
ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
