import SwiftUI

@main
struct RepriseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        PlaybackMonitor.shared.start()
    }

    var body: some Scene {
        MenuBarExtra("Reprise", systemImage: "music.note") {
            MenuBarView()
                .environmentObject(PlaybackMonitor.shared)
                .environmentObject(SettingsManager.shared)
                .environmentObject(LogManager.shared)
        }
        .menuBarExtraStyle(.window)

        Settings {
            // LogView used as a standalone settings window — dismiss is handled
            // by the system window close button, so the binding is unused here.
            LogView()
                .environmentObject(LogManager.shared)
        }
    }
}
