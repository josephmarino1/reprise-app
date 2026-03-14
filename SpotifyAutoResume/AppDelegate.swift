import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the Dock icon. LSUIElement in Info.plist blocks MenuBarExtra,
        // so we set the activation policy programmatically after launch instead.
        NSApp.setActivationPolicy(.accessory)
    }
}
