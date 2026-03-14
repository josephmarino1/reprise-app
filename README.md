# Reprise

**Reprise keeps your music playing, even when it shouldn't have stopped.**

When Spotify pauses unexpectedly — after a call, a system interruption, when your headphones disconnect, or a moment of silence — Reprise quietly detects it and resumes playback automatically. No tapping, no fumbling, no silence.

---

## Features

- 🎵 **Lives discreetly in your menu bar**, out of the way
- ▶️ **Automatically resumes** after a customizable delay
- 🎧 **Resume where you left off**, or kick off a specific playlist
- 📋 **Full activity log** so you always know when Reprise stepped in
- 🚀 **Launches at login**, works silently in the background

Set it once. Forget it exists. Just enjoy uninterrupted music.

---

## Requirements

- macOS 13 Ventura or later
- Spotify desktop app

---

## Installation

1. Download `Reprise-1.0.dmg` from the [latest release](../../releases/latest)
2. Open the DMG and drag **Reprise** into your Applications folder
3. Launch Reprise — it will appear in your menu bar
4. When prompted, allow Reprise to control Spotify in **System Settings → Privacy & Security → Automation**

---

## Usage

Click the **♩** icon in your menu bar to open Reprise.

| Setting | Description |
|---|---|
| **Toggle** | Enable or disable auto-resume |
| **Resume after** | How many seconds to wait before resuming (1–30s) |
| **Set Playlist** | Optionally resume a specific playlist instead of the last track |
| **Launch at login** | Start Reprise automatically when you log in |
| **Open Settings** | Jump to System Settings → Automation if you need to re-grant access |

### Setting a Playlist

1. Click **Set Playlist** in the Reprise menu
2. In Spotify, right-click any playlist → **Share → Copy link**
3. Paste the link into Reprise and give it a name
4. Reprise will start that playlist whenever it auto-resumes

---

## Privacy

Reprise runs entirely on your device. It uses AppleScript to communicate with the Spotify desktop app locally — no data is sent anywhere, no Spotify account credentials are accessed, and no network requests are made by Reprise itself.

---

## Distribution

Reprise is distributed outside the Mac App Store because Apple's App Sandbox blocks the local Apple Events that Reprise uses to communicate with Spotify. The app is notarized by Apple, so Gatekeeper will trust it on any Mac running macOS 13+.

---

## Building from Source

```bash
git clone https://github.com/josephmarino1/reprise-app.git
cd reprise-app
open SpotifyAutoResume.xcodeproj
```

Requires Xcode 15+ and macOS 13 SDK.

---

## License

MIT
