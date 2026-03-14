import Foundation
import AppKit

struct SpotifyTrack {
    let name: String
    let artist: String
    let album: String
}

struct SpotifyPlaylist: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let uri: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SpotifyPlaylist, rhs: SpotifyPlaylist) -> Bool { lhs.id == rhs.id }
}

enum SpotifyPlayerState: String {
    case playing, paused, stopped, notRunning
}

class SpotifyController {
    static let shared = SpotifyController()
    private init() {}

    var isRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.spotify.client"
        }
    }

    // MARK: - Combined state + track query (one AppleScript call instead of two)

    /// Returns the player state and current track in a single AppleScript round-trip.
    func getStateAndTrack() async -> (SpotifyPlayerState, SpotifyTrack?) {
        let script = """
        tell application "Spotify"
            set s to player state as string
            if player state is playing or player state is paused then
                set t to current track
                return s & "|||" & (name of t) & "|||" & (artist of t) & "|||" & (album of t)
            end if
            return s
        end tell
        """
        guard let raw = await runScript(script) else { return (.stopped, nil) }
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                       .components(separatedBy: "|||")

        let state: SpotifyPlayerState
        switch parts[0].trimmingCharacters(in: .whitespacesAndNewlines) {
        case "playing": state = .playing
        case "paused":  state = .paused
        case "stopped": state = .stopped
        default:        state = .stopped
        }

        var track: SpotifyTrack?
        if parts.count >= 4 {
            track = SpotifyTrack(
                name:   parts[1].trimmingCharacters(in: .whitespacesAndNewlines),
                artist: parts[2].trimmingCharacters(in: .whitespacesAndNewlines),
                album:  parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return (state, track)
    }

    // MARK: - Playback control

    func resume() async {
        guard isRunning else { return }
        await runScript("tell application \"Spotify\"\nplay\nend tell")
    }

    func playPlaylist(_ playlist: SpotifyPlaylist) async {
        guard isRunning else { return }
        await runScript("""
        tell application "Spotify"
            play track "\(playlist.uri)"
        end tell
        """)
    }

    // MARK: - Permissions

    /// Opens System Settings → Privacy & Security → Automation so the user
    /// can review or re-grant Spotify access. (Sandboxed apps cannot run tccutil.)
    func resetAutomationPermission() async {
        LogManager.shared.log("Opening System Settings → Privacy → Automation.")
        await MainActor.run {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - AppleScript runner

    @discardableResult
    private func runScript(_ source: String) async -> String? {
        await ScriptExecutor.shared.execute {
            var error: NSDictionary?
            guard let script = NSAppleScript(source: source) else { return nil }
            let output = script.executeAndReturnError(&error)
            if let error = error {
                let msg = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                // "isn't running" / "is not running" are expected when Spotify is closed.
                // Don't log them — the isRunning pre-check should prevent them, but
                // there's an unavoidable race if Spotify quits between the check and call.
                // AppleScript uses a curly apostrophe U+2019 in "isn't", not ASCII ',
                // so we check both variants plus a general "not running" pattern.
                let lc = msg.lowercased()
                let isExpected = (lc.contains("isn") && lc.contains("running"))
                               || lc.contains("is not running")
                if !isExpected {
                    DispatchQueue.main.async {
                        LogManager.shared.log("AppleScript error: \(msg)")
                    }
                }
                return nil
            }
            return output.stringValue
        }
    }
}
