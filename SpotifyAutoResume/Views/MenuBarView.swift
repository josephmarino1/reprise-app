import SwiftUI

// Page-based navigation within the MenuBarExtra window.
// Sheets cause the extra to lose focus and close on dismiss — inline
// page switching avoids any external window lifecycle interaction.
private enum MenuPage {
    case main, log, playlistPicker
}

struct MenuBarView: View {
    @EnvironmentObject var monitor: PlaybackMonitor
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var logManager: LogManager

    @State private var page: MenuPage = .main

    var body: some View {
        Group {
            switch page {
            case .main:
                mainContent
            case .log:
                LogView(onDismiss: { page = .main })
                    .environmentObject(logManager)
            case .playlistPicker:
                PlaylistPickerView(
                    onSelect: { playlist in
                        settings.preferredPlaylist = playlist
                        page = .main
                    },
                    onDismiss: { page = .main }
                )
            }
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Main content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            trackSection
            Divider()
            settingsSection
            Divider()
            logSection
            Divider()
            footerSection
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(settings.autoResumeEnabled ? .green : .secondary)

            Text("Reprise")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Toggle("", isOn: $settings.autoResumeEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Track Section

    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    if monitor.currentState == .notRunning {
                        Text("Spotify not running")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let track = monitor.currentTrack {
                        Text(track.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Nothing playing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(stateLabel)
                    .font(.caption2)
                    .foregroundColor(stateColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(stateColor.opacity(0.15))
                    .cornerRadius(4)
            }

            if monitor.stoppedAt != nil && settings.autoResumeEnabled {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Resuming in \(monitor.countdownSeconds)s...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.leading, 18)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var stateColor: Color {
        switch monitor.currentState {
        case .playing:    return .green
        case .paused:     return .orange
        case .stopped:    return .red
        case .notRunning: return .gray
        }
    }

    private var stateLabel: String {
        switch monitor.currentState {
        case .playing:    return "Playing"
        case .paused:     return "Paused"
        case .stopped:    return "Stopped"
        case .notRunning: return "Offline"
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Resume delay stepper
            HStack {
                Label("Resume after", systemImage: "clock")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: { if settings.resumeDelay > 1 { settings.resumeDelay -= 1 } }) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(settings.resumeDelay))s")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 28, alignment: .center)
                        .monospacedDigit()

                    Button(action: { if settings.resumeDelay < 30 { settings.resumeDelay += 1 } }) {
                        Image(systemName: "plus.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Preferred playlist
            HStack(spacing: 6) {
                Label(
                    settings.preferredPlaylist?.name ?? "Resume last track",
                    systemImage: "music.note.list"
                )
                .font(.subheadline)
                .lineLimit(1)
                .foregroundColor(settings.preferredPlaylist != nil ? .primary : .secondary)

                Spacer()

                Button(settings.preferredPlaylist != nil ? "Change" : "Set Playlist") {
                    page = .playlistPicker
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)

                if settings.preferredPlaylist != nil {
                    Button(action: { settings.preferredPlaylist = nil }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Launch at login
            HStack {
                Label("Launch at login", systemImage: "arrow.up.right.square")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
            }

            // Spotify automation permission
            HStack {
                Label("Spotify access", systemImage: "lock.shield")
                    .font(.subheadline)
                Spacer()
                Button("Re-prompt") {
                    Task { await SpotifyController.shared.resetAutomationPermission() }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Clears the Automation permission and asks macOS to prompt again.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Log Section

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Recent Activity")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Button("View All") { page = .log }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }

            if logManager.entries.isEmpty {
                Text("No activity yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(logManager.entries.prefix(3)) { entry in
                    HStack(alignment: .top, spacing: 6) {
                        Text(shortTimeString(entry.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(minWidth: 50, alignment: .leading)
                            .monospacedDigit()
                        Text(entry.message)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Button("Quit") { NSApp.terminate(nil) }
                .font(.subheadline)
                .foregroundColor(.red)
                .buttonStyle(.plain)

            Spacer()

            if let lastResume = monitor.lastResumeTime {
                Text("Last resume: \(shortTimeString(lastResume))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func shortTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

}
