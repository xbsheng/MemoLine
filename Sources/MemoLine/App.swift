import AppKit

/// An accessory app: no Dock icon, no window of its own, just the line.
@main
enum MemoLineApp {
    static func main() {
        // The check runs headless and never opens a window; see SelfCheck.swift.
        if CommandLine.arguments.contains("--self-check") {
            runSelfCheck()
            return
        }
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
