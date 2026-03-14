import Foundation
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let autoResumeEnabled = "autoResumeEnabled"
        static let resumeDelay = "resumeDelay"
        static let preferredPlaylistId = "preferredPlaylistId"
        static let preferredPlaylistName = "preferredPlaylistName"
        static let preferredPlaylistUri = "preferredPlaylistUri"
        static let launchAtLogin = "launchAtLogin"
    }

    @Published var autoResumeEnabled: Bool {
        didSet {
            defaults.set(autoResumeEnabled, forKey: Keys.autoResumeEnabled)
        }
    }

    @Published var resumeDelay: Double {
        didSet {
            let clamped = min(max(resumeDelay, 1.0), 30.0)
            if clamped != resumeDelay {
                resumeDelay = clamped
                return
            }
            defaults.set(resumeDelay, forKey: Keys.resumeDelay)
        }
    }

    @Published var preferredPlaylist: SpotifyPlaylist? {
        didSet {
            if let playlist = preferredPlaylist {
                defaults.set(playlist.id, forKey: Keys.preferredPlaylistId)
                defaults.set(playlist.name, forKey: Keys.preferredPlaylistName)
                defaults.set(playlist.uri, forKey: Keys.preferredPlaylistUri)
            } else {
                defaults.removeObject(forKey: Keys.preferredPlaylistId)
                defaults.removeObject(forKey: Keys.preferredPlaylistName)
                defaults.removeObject(forKey: Keys.preferredPlaylistUri)
            }
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(launchAtLogin)
        }
    }

    private init() {
        // Set defaults if not already set
        if defaults.object(forKey: Keys.autoResumeEnabled) == nil {
            defaults.set(true, forKey: Keys.autoResumeEnabled)
        }
        if defaults.object(forKey: Keys.resumeDelay) == nil {
            defaults.set(5.0, forKey: Keys.resumeDelay)
        }
        if defaults.object(forKey: Keys.launchAtLogin) == nil {
            defaults.set(false, forKey: Keys.launchAtLogin)
        }

        self.autoResumeEnabled = defaults.bool(forKey: Keys.autoResumeEnabled)
        self.resumeDelay = defaults.double(forKey: Keys.resumeDelay) > 0
            ? defaults.double(forKey: Keys.resumeDelay)
            : 5.0
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        // Restore preferred playlist
        if let id = defaults.string(forKey: Keys.preferredPlaylistId),
           let name = defaults.string(forKey: Keys.preferredPlaylistName),
           let uri = defaults.string(forKey: Keys.preferredPlaylistUri) {
            self.preferredPlaylist = SpotifyPlaylist(id: id, name: name, uri: uri)
        } else {
            self.preferredPlaylist = nil
        }
    }

    private func updateLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                LogManager.shared.log("Launch at login error: \(error.localizedDescription)")
            }
        }
    }

    func syncLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            // Defer to next run loop tick so ServiceManagement has time to
            // initialize its folder structure, avoiding FSFindFolder error=-43
            // spam on first launch.
            DispatchQueue.main.async {
                let status = SMAppService.mainApp.status
                let isRegistered = (status == .enabled)
                if self.launchAtLogin != isRegistered {
                    self.launchAtLogin = isRegistered
                }
            }
        }
    }
}
