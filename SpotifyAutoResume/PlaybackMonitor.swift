import Foundation
import Combine

@MainActor
class PlaybackMonitor: ObservableObject {
    static let shared = PlaybackMonitor()

    @Published var currentState: SpotifyPlayerState = .notRunning
    @Published var currentTrack: SpotifyTrack?
    @Published var isAutoResumeEnabled: Bool = true
    @Published var lastResumeTime: Date?
    @Published var stoppedAt: Date?
    @Published var countdownSeconds: Int = 0

    private var timer: Timer?
    private let pollingInterval: TimeInterval = 2.0

    private init() {
        isAutoResumeEnabled = SettingsManager.shared.autoResumeEnabled
    }

    func start() {
        isAutoResumeEnabled = SettingsManager.shared.autoResumeEnabled
        timer?.invalidate()
        // Timer fires on the main RunLoop. Each tick spawns a Task that
        // immediately suspends while AppleScript runs on ScriptExecutor's
        // background thread — the main thread is never blocked.
        let t = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { await self.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Polling

    private func poll() async {
        let settings = SettingsManager.shared
        isAutoResumeEnabled = settings.autoResumeEnabled

        guard settings.autoResumeEnabled else {
            stoppedAt = nil
            countdownSeconds = 0
            return
        }

        // isRunning is a fast NSWorkspace query — safe on main thread.
        guard SpotifyController.shared.isRunning else {
            currentState = .notRunning
            currentTrack = nil
            stoppedAt = nil
            countdownSeconds = 0
            return
        }

        // Suspend here — AppleScript runs on ScriptExecutor's background thread.
        // The main thread is freed until the result comes back.
        let (newState, track) = await SpotifyController.shared.getStateAndTrack()

        // Back on MainActor — safe to update @Published properties.
        currentState = newState
        currentTrack = track

        // Trigger countdown whenever Spotify is paused/stopped and running, regardless
        // of whether it was previously playing (covers the already-paused-on-launch case).
        // previousState == .notRunning means this is either the first poll or Spotify
        // just launched — treat finding it paused as a reason to resume.
        let nowNonPlaying = newState != .playing && newState != .notRunning
        if nowNonPlaying && stoppedAt == nil {
            stoppedAt = Date()
            countdownSeconds = Int(settings.resumeDelay)
            LogManager.shared.log("Playback stopped — will resume in \(Int(settings.resumeDelay))s.")
        } else if newState == .playing {
            stoppedAt = nil
            countdownSeconds = 0
        } else if newState == .notRunning {
            stoppedAt = nil
            countdownSeconds = 0
        }

        if let stopped = stoppedAt {
            let elapsed = Date().timeIntervalSince(stopped)
            if elapsed >= settings.resumeDelay {
                await triggerAutoResume()
            } else {
                countdownSeconds = max(0, Int(settings.resumeDelay - elapsed))
            }
        }

    }

    // MARK: - Auto-resume

    private func triggerAutoResume() async {
        guard stoppedAt != nil else { return }
        stoppedAt = nil
        countdownSeconds = 0

        let settings = SettingsManager.shared
        let spotify = SpotifyController.shared

        if let playlist = settings.preferredPlaylist {
            await spotify.playPlaylist(playlist)
            LogManager.shared.log("Auto-resumed playlist \"\(playlist.name)\".")
        } else {
            await spotify.resume()
            if let track = currentTrack {
                LogManager.shared.log("Auto-resumed \"\(track.name)\" by \(track.artist).")
            } else {
                LogManager.shared.log("Auto-resumed playback.")
            }
        }

        lastResumeTime = Date()
    }
}
