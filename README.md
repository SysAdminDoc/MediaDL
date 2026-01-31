# MediaDL - Universal Media Downloader

Download videos and extract audio from **1800+ websites** - all from browser buttons.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Sites](https://img.shields.io/badge/sites-1800+-brightgreen)

## Supported Sites

MediaDL uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) as its backend, supporting:

| Category | Sites |
|----------|-------|
| **Video** | YouTube, Vimeo, Dailymotion, TikTok, Twitch, Rumble, Odysee, Bilibili, Streamable |
| **Social** | Twitter/X, Instagram, Facebook, Reddit, Tumblr |
| **Audio** | SoundCloud, Bandcamp, Spotify, Mixcloud |
| **News** | CNN, BBC, NBC, CBS, ABC, Fox, NYT, Washington Post |
| **Adult** | Most major sites supported |
| **Other** | [1800+ total sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) |

## Quick Install (Windows)

```powershell
irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/refs/heads/main/Install-MediaDL.ps1 | iex
```

## Features

### Core Features
- **Download Video** - One-click MP4 downloads (up to 1080p)
- **Extract Audio** - Convert any video to MP3

### UI
- **Side Drawer** - Minimal slide-out panel on the right edge
- **Hover to Expand** - Just hover over the lip to reveal buttons
- **Auto-Hide** - Collapses when you move away

### Smart Features
- **Site Detection** - Automatically recognizes supported sites
- **SPA Navigation** - Handles YouTube/Twitter single-page navigation
- **Persistent Settings** - Your preferences save across sessions
- **Auto-Retry** - Failed downloads automatically retry

## Screenshots

### Side Drawer
A minimal slide-out drawer on the right edge of the screen:

```
                                        |  <- Thin green lip (always visible)
                                        |
    [hover over lip]  ─────────────────┐|
                      │ [Video]        │|
                      │ [MP3]          │|
                      └────────────────┘|
    
    [hover away] ───────────────────────|  <- Slides back, only lip visible
```

- Hover over the lip to expand
- Click a button to download
- Move mouse away to collapse

## Installation

### Option 1: Automatic (Recommended)

1. Open PowerShell as Administrator
2. Run the one-liner:
   ```powershell
   irm https://raw.githubusercontent.com/SysAdminDoc/MediaDL/refs/heads/main/Install-MediaDL.ps1 | iex
   ```
3. Follow the GUI installer
4. Install the userscript when prompted

### Option 2: Manual

1. **Install a userscript manager:**
   - [Tampermonkey](https://www.tampermonkey.net/) (Chrome, Firefox, Edge)
   - [Violentmonkey](https://violentmonkey.github.io/) (Chrome, Firefox)

2. **Install the userscript:**
   
   **[Click to Install MediaDL](https://github.com/SysAdminDoc/MediaDL/raw/refs/heads/main/MediaDL.user.js)**

3. **Install dependencies:**
   - [yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)
   - [ffmpeg](https://ffmpeg.org/download.html)

4. **Register protocol handlers** (see Protocol Handlers section)

## How It Works

```
Browser                    Windows                     Output
+-----------------+       +-----------------+        +----------+
|  MediaDL        |       |  Protocol       |        |          |
|  Userscript     |------>|  Handler        |------> |  Video/  |
|                 |       |  (PowerShell)   |        |  Audio   |
|  Detects site   |       |                 |        |  Files   |
|  Shows buttons  |       |  Calls yt-dlp   |        |          |
|  Sends URL      |       |  with URL       |        |          |
+-----------------+       +-----------------+        +----------+
        |                         |
        |  ytdl://URL             |  yt-dlp -f best URL
```

1. **Userscript detects** you're on a supported video page
2. **Buttons appear** (native or floating panel)
3. **Click triggers** a custom protocol URL (`ytdl://`)
4. **Windows launches** the protocol handler script
5. **yt-dlp downloads** the media to your Downloads folder

## Protocol Handlers

The installer creates this protocol handler:

| Protocol | Purpose | Handler |
|----------|---------|---------|
| `ytdl://` | Download video/audio | `ytdl-handler.ps1` |

### Manual Protocol Setup

If not using the installer, create this registry entry:

```reg
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Classes\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CURRENT_USER\Software\Classes\ytdl\shell\open\command]
@="powershell.exe -ExecutionPolicy Bypass -File \"C:\\Path\\To\\ytdl-handler.ps1\" \"%1\""
```

## Adding New Sites

The userscript uses a simple site configuration system. To add a new site:

```javascript
// In SITE_CONFIGS object:
'example.com': {
    name: 'Example Site',
    urlPattern: /example\.com\/video\/\d+/,
    getVideoUrl: () => location.href,
    getVideoTitle: () => document.querySelector('h1')?.textContent || 'video'
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Drawer doesn't appear | Refresh page, check if URL matches a video page |
| "Protocol not recognized" | Re-run installer or check registry entries |
| Download fails | Check yt-dlp is installed: `yt-dlp --version` |
| Site not supported | Check [yt-dlp supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) |

### Debug Mode

Open browser console (F12) and check for `MediaDL` log messages.

## File Locations

| Item | Path |
|------|------|
| Installation | `%LOCALAPPDATA%\YTYT-Downloader\` |
| Downloads | `%USERPROFILE%\Videos\YouTube\` |
| yt-dlp | `%LOCALAPPDATA%\YTYT-Downloader\yt-dlp.exe` |
| ffmpeg | `%LOCALAPPDATA%\YTYT-Downloader\ffmpeg.exe` |
| Handlers | `%LOCALAPPDATA%\YTYT-Downloader\*.ps1` |

## Uninstalling

1. Delete installation folder: `%LOCALAPPDATA%\YTYT-Downloader`
2. Remove registry key:
   - `HKCU:\Software\Classes\ytdl`
3. Remove userscript from Tampermonkey/Violentmonkey
4. Delete desktop shortcut if created

## Contributing

Contributions welcome! Areas of interest:

- [ ] Add more site-specific integrations
- [ ] macOS/Linux support
- [ ] Playlist support
- [ ] Quality selection UI

## Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [ffmpeg](https://ffmpeg.org/) - Audio/video processing

## License

MIT License - see [LICENSE](LICENSE)

---

**[Report Issues](https://github.com/SysAdminDoc/MediaDL/issues)** | **[SysAdminDoc](https://github.com/SysAdminDoc)**
