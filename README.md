# MediaDL - Universal Media Downloader

Download videos and extract audio from **1800+ websites** with a single click.

[![Version](https://img.shields.io/badge/version-1.0.0-00b894)](https://github.com/SysAdminDoc/MediaDL/releases)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![yt-dlp](https://img.shields.io/badge/powered%20by-yt--dlp-red)](https://github.com/yt-dlp/yt-dlp)
[![Sites](https://img.shields.io/badge/supported%20sites-1800+-brightgreen)](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)

---

## Quick Install (Windows)

```powershell
irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/main/Install-MediaDL.ps1 | iex
```

---

## Features

- **One-Click Downloads** - Video (MP4) or Audio (MP3) with a single click
- **Universal Support** - Works on 1800+ sites via yt-dlp
- **Side Drawer UI** - Minimal, unobtrusive interface on the right edge
- **SPA Compatible** - Handles YouTube, Twitter, TikTok and other single-page apps
- **Auto-Updates** - Userscript updates automatically via Tampermonkey/Violentmonkey

## Supported Sites

MediaDL supports all [yt-dlp extractors](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) including:

| Category | Examples |
|----------|----------|
| **Video** | YouTube, Vimeo, Dailymotion, TikTok, Twitch, Rumble, Odysee, Bitchute, Bilibili |
| **Social** | Twitter/X, Instagram, Facebook, Reddit, Tumblr, LinkedIn |
| **Music** | SoundCloud, Bandcamp, Spotify, Mixcloud, Audiomack |
| **News** | CNN, BBC, NBC, CBS, ABC, Fox News, NYTimes, Washington Post |
| **Sports** | ESPN, NFL, NBA, MLB, NHL, FIFA, Formula 1 |
| **Education** | Khan Academy, TED, Coursera, Udemy, MIT OpenCourseWare |
| **Adult** | All major sites supported |

---

## How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Browser       │     │   Windows       │     │   Output        │
│                 │     │                 │     │                 │
│  MediaDL        │────>│  ytdl://        │────>│  Video.mp4      │
│  Userscript     │     │  Protocol       │     │  Audio.mp3      │
│                 │     │  Handler        │     │                 │
│  [Video] [MP3]  │     │  (yt-dlp)       │     │  ~/Videos/      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. Visit any supported site with video/audio content
2. Hover over the **green lip** on the right edge of your screen
3. Click **Video** or **MP3**
4. File downloads to your Videos folder

## User Interface

```
                                          │  <- Green lip (always visible)
                                          │
    [hover]  ────────────────────────────┐│
             │  ┌─────────┐              ││
             │  │  Video  │  <- Green    ││
             │  └─────────┘              ││
             │  ┌─────────┐              ││
             │  │   MP3   │  <- Purple   ││
             │  └─────────┘              ││
             └───────────────────────────┘│
                                          │
    [mouse away]  ────────────────────────│  <- Collapses automatically
```

---

## Installation

### Automatic (Recommended)

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/main/Install-MediaDL.ps1 | iex
   ```
3. Follow the setup wizard
4. Install the userscript when prompted

### Manual Installation

1. **Install a userscript manager:**
   - [Tampermonkey](https://www.tampermonkey.net/) (Chrome, Firefox, Edge)
   - [Violentmonkey](https://violentmonkey.github.io/) (Chrome, Firefox)

2. **Install the userscript:**
   
   [![Install MediaDL](https://img.shields.io/badge/Install-MediaDL-00b894?style=for-the-badge)](https://github.com/SysAdminDoc/MediaDL/raw/main/MediaDL.user.js)

3. **Install backend tools:**
   - [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases) - Download engine
   - [ffmpeg](https://ffmpeg.org/download.html) - Audio/video processing

4. **Register protocol handler** - See [Protocol Handler](#protocol-handler) section

---

## Protocol Handler

The installer registers a `ytdl://` protocol handler. For manual setup:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Classes\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CURRENT_USER\Software\Classes\ytdl\shell\open\command]
@="powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"C:\\Path\\To\\ytdl-handler.ps1\" \"%1\""
```

## File Locations

| Item | Path |
|------|------|
| Installation | `%LOCALAPPDATA%\MediaDL\` |
| Downloads | `%USERPROFILE%\Videos\MediaDL\` |
| yt-dlp | `%LOCALAPPDATA%\MediaDL\yt-dlp.exe` |
| ffmpeg | `%LOCALAPPDATA%\MediaDL\ffmpeg.exe` |
| Config | `%LOCALAPPDATA%\MediaDL\config.json` |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Drawer doesn't appear | Refresh the page; ensure you're on a video page |
| "Protocol not recognized" | Re-run the installer or check registry entries |
| Download fails | Update yt-dlp: Open PowerShell and run `yt-dlp -U` |
| Site not working | Check if the site is [supported by yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) |

### Debug Mode

Open browser console (F12) and look for `MediaDL:` log messages.

---

## Uninstalling

**Via Installer:** Run the installer again and click "Uninstall"

**Manual:**
1. Delete: `%LOCALAPPDATA%\MediaDL`
2. Remove registry key: `HKCU:\Software\Classes\ytdl`
3. Remove userscript from Tampermonkey/Violentmonkey

---

## Changelog

### v1.0.0 (Initial Release)
- Side drawer UI with hover-to-expand
- Video (MP4) and Audio (MP3) download buttons
- 1,138 explicit site patterns
- Windows installer with 3-step wizard
- Protocol handler for browser-to-desktop integration
- Auto-update support for userscript

---

## Contributing

Contributions welcome! Ideas for improvement:

- [ ] macOS/Linux support
- [ ] Quality selection UI
- [ ] Playlist support
- [ ] Download queue management

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [ffmpeg](https://ffmpeg.org/) - Audio/video processing

## License

[MIT License](LICENSE) - feel free to use, modify, and distribute.

---

**[Report Issues](https://github.com/SysAdminDoc/MediaDL/issues)** | **[SysAdminDoc](https://github.com/SysAdminDoc)**
