# MediaDL - Universal Media Downloader

Download videos and extract audio from **1800+ websites** with a single click.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Sites](https://img.shields.io/badge/sites-1800+-brightgreen)

## Quick Install (Windows)

```powershell
irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/refs/heads/main/Install-MediaDL.ps1 | iex
```

## Supported Sites

MediaDL includes **1,138 explicit domain patterns** covering all [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md):

| Category | Examples |
|----------|----------|
| **Video Platforms** | YouTube, Vimeo, Dailymotion, TikTok, Twitch, Rumble, Odysee, Bitchute, Bilibili, PeerTube, Streamable |
| **Social Media** | Twitter/X, Instagram, Facebook, Reddit, Tumblr, Bluesky, LinkedIn |
| **Music & Audio** | SoundCloud, Bandcamp, Spotify, Mixcloud, Audiomack, Last.fm |
| **News & Media** | CNN, BBC, NBC, CBS, ABC, Fox News, NYTimes, Washington Post, Guardian, Reuters |
| **Sports** | ESPN, NFL, NBA, MLB, NHL, FIFA, Formula 1, UFC |
| **Education** | Khan Academy, TED, Coursera, Udemy, MIT OpenCourseWare |
| **Streaming** | Crunchyroll, Twitch VODs, Kick, Floatplane |
| **Regional** | NHK (Japan), ARD/ZDF (Germany), France.tv, RAI (Italy), SVT (Sweden), NRK (Norway), BBC iPlayer |
| **Adult** | All major sites supported (PornHub, XVideos, XHamster, etc.) |

## Features

- **One-Click Downloads** - Video (MP4) or Audio (MP3) with a single click
- **Side Drawer UI** - Minimal, unobtrusive interface that slides out on hover
- **Universal Support** - Works on 1800+ sites without configuration
- **SPA Compatible** - Handles YouTube, Twitter, and other single-page apps
- **Protocol Handler** - Seamless browser-to-desktop integration

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

1. Visit any supported site
2. Hover over the green lip on the right edge
3. Click **Video** or **MP3**
4. File downloads to your Videos folder

## Screenshots

### Side Drawer Interface

```
                                          │  ← Green lip (always visible)
                                          │
    [hover]  ────────────────────────────┐│
             │  ┌─────────┐              ││
             │  │  Video  │  ← Green     ││
             │  └─────────┘              ││
             │  ┌─────────┐              ││
             │  │   MP3   │  ← Purple    ││
             │  └─────────┘              ││
             └───────────────────────────┘│
                                          │
    [mouse away]  ────────────────────────│  ← Collapses automatically
```

## Installation

### Automatic (Recommended)

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/refs/heads/main/Install-MediaDL.ps1 | iex
   ```
3. Follow the GUI installer
4. Install the userscript when prompted

### Manual

1. **Install a userscript manager:**
   - [Tampermonkey](https://www.tampermonkey.net/) (Chrome, Firefox, Edge)
   - [Violentmonkey](https://violentmonkey.github.io/) (Chrome, Firefox)

2. **Install the userscript:**
   
   **[Click to Install MediaDL](https://github.com/SysAdminDoc/MediaDL/raw/refs/heads/main/MediaDL.user.js)**

3. **Install backend dependencies:**
   - [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
   - [ffmpeg](https://ffmpeg.org/download.html)

4. **Register protocol handler** (see below)

## Protocol Handler

The installer creates a `ytdl://` protocol handler. For manual setup:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Classes\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CURRENT_USER\Software\Classes\ytdl\shell\open\command]
@="powershell.exe -ExecutionPolicy Bypass -File \"C:\\Path\\To\\ytdl-handler.ps1\" \"%1\""
```

## File Locations

| Item | Path |
|------|------|
| Installation | `%LOCALAPPDATA%\YTYT-Downloader\` |
| Downloads | `%USERPROFILE%\Videos\YouTube\` |
| yt-dlp | `%LOCALAPPDATA%\YTYT-Downloader\yt-dlp.exe` |
| ffmpeg | `%LOCALAPPDATA%\YTYT-Downloader\ffmpeg.exe` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Drawer doesn't appear | Refresh page; site may not be on a video page |
| "Protocol not recognized" | Re-run installer or check registry entries |
| Download fails | Run `yt-dlp --version` to verify installation |
| Site not working | Update yt-dlp: `yt-dlp -U` |

### Debug

Open browser console (F12) and look for `MediaDL:` log messages.

## Adding Custom Sites

The userscript already matches 1,138 domains. For custom site behavior:

```javascript
// In SITE_CONFIGS object:
'example.com': {
    name: 'Example Site',
    urlPattern: /example\.com\/video\/\d+/,
    getVideoUrl: () => location.href,
    getVideoTitle: () => document.querySelector('h1')?.textContent || 'video'
}
```

## Uninstalling

1. Delete: `%LOCALAPPDATA%\YTYT-Downloader`
2. Remove registry: `HKCU:\Software\Classes\ytdl`
3. Remove userscript from Tampermonkey/Violentmonkey

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Download engine (1800+ sites)
- [ffmpeg](https://ffmpeg.org/) - Audio/video processing

## License

MIT License - see [LICENSE](LICENSE)

---

**[Report Issues](https://github.com/SysAdminDoc/MediaDL/issues)** | **[SysAdminDoc](https://github.com/SysAdminDoc)**
