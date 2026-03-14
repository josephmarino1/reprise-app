import SwiftUI

struct PlaylistPickerView: View {
    let onSelect: (SpotifyPlaylist) -> Void
    var onDismiss: () -> Void = {}

    @State private var playlistName: String = ""
    @State private var playlistLink: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Set Playlist")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { onDismiss() }
                    .font(.subheadline)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Playlist Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("My Playlist", text: $playlistName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Spotify Link or URI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("https://open.spotify.com/playlist/…", text: $playlistLink)
                        .textFieldStyle(.roundedBorder)
                    Text("In Spotify: right-click a playlist → Share → Copy link")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(playlistName.trimmingCharacters(in: .whitespaces).isEmpty ||
                              playlistLink.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func save() {
        let name = playlistName.trimmingCharacters(in: .whitespaces)
        guard let uri = parseSpotifyURI(from: playlistLink) else {
            errorMessage = "Invalid Spotify link or URI. Paste the link from Spotify's Share menu."
            return
        }
        onSelect(SpotifyPlaylist(id: uri, name: name, uri: uri))
    }

    /// Accepts a Spotify share URL or a raw spotify: URI and returns a spotify:playlist:XXX string.
    private func parseSpotifyURI(from input: String) -> String? {
        let s = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Already a proper URI.
        if s.hasPrefix("spotify:playlist:") { return s }

        // https://open.spotify.com/playlist/ID  or  /playlist/ID?si=…
        if let url = URL(string: s),
           let host = url.host, host.contains("spotify.com") {
            let parts = url.pathComponents          // ["", "playlist", "ID"]
            if let idx = parts.firstIndex(of: "playlist"), idx + 1 < parts.count {
                return "spotify:playlist:\(parts[idx + 1])"
            }
        }

        return nil
    }
}
