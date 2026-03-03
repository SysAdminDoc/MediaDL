<div align="center">

<!-- HERO BANNER -->
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://capsule-render.vercel.app/api?type=waving&color=0:00b894,50:0984e3,100:6c5ce7&height=220&section=header&text=MediaDL&fontSize=48&fontColor=ffffff&fontAlignY=35&desc=Universal%20Media%20Downloader%20for%201800%2B%20Websites&descSize=18&descAlignY=55&descColor=cccccc&animation=fadeIn" />
  <source media="(prefers-color-scheme: light)" srcset="https://capsule-render.vercel.app/api?type=waving&color=0:00b894,50:0984e3,100:6c5ce7&height=220&section=header&text=MediaDL&fontSize=48&fontColor=ffffff&fontAlignY=35&desc=Universal%20Media%20Downloader%20for%201800%2B%20Websites&descSize=18&descAlignY=55&descColor=eeeeee&animation=fadeIn" />
  <img width="100%" alt="MediaDL" src="https://capsule-render.vercel.app/api?type=waving&color=0:00b894,50:0984e3,100:6c5ce7&height=220&section=header&text=MediaDL&fontSize=48&fontColor=ffffff&fontAlignY=35&desc=Universal%20Media%20Downloader%20for%201800%2B%20Websites&descSize=18&descAlignY=55&descColor=cccccc&animation=fadeIn" />
</picture>

<br>

<img width="654" height="366" alt="MediaDL" src="https://github.com/user-attachments/assets/d5892a79-c6ff-47c6-ab63-cacfb8e78622" />

<br><br>

<!-- BADGES -->
[![Version](https://img.shields.io/badge/v4.0.0-00b894?style=for-the-badge&logo=semanticrelease&logoColor=white&label=Version)](https://github.com/SysAdminDoc/YTYT-Downloader/releases)
&nbsp;
[![Sites](https://img.shields.io/badge/1800+-e17055?style=for-the-badge&logo=youtube&logoColor=white&label=Sites)](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
&nbsp;
[![PowerShell](https://img.shields.io/badge/5.1+-0078D4?style=for-the-badge&logo=powershell&logoColor=white&label=PowerShell)](https://docs.microsoft.com/en-us/powershell/)
&nbsp;
[![License](https://img.shields.io/badge/MIT-6c5ce7?style=for-the-badge&logo=opensourceinitiative&logoColor=white&label=License)](LICENSE)

<br>

**Download videos and extract audio from YouTube, Facebook, Twitter/X, TikTok, Instagram, and 1800+ more.**
<br>
**Auto-detects media on any page. Floating download pills. Zero configuration.**

<br>

**3-tier failover** &nbsp;·&nbsp; **hidden background server** &nbsp;·&nbsp; **real-time progress** &nbsp;·&nbsp; **6-layer Facebook extraction**

<br>

<!-- NAVIGATION -->
[<kbd> <br> &nbsp;&nbsp;🚀 Quick Install&nbsp;&nbsp; <br> </kbd>](#-quick-install)&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;✨ Features&nbsp;&nbsp; <br> </kbd>](#-features)&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;🌍 Sites&nbsp;&nbsp; <br> </kbd>](#-supported-sites)&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;🏗️ Architecture&nbsp;&nbsp; <br> </kbd>](#%EF%B8%8F-architecture)&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;🔧 Troubleshoot&nbsp;&nbsp; <br> </kbd>](#-troubleshooting)

</div>

---

<br>

## 🚀 Quick Install

> **One command. Everything configured. No manual setup.**

```powershell
irm https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/src/Install-MediaDL.ps1 | iex
```

<sub>Run in an elevated PowerShell window. The installer downloads yt-dlp, ffmpeg, registers protocol handlers, deploys the background download server, creates a Scheduled Task for auto-start, and installs the userscript.</sub>

<br>

## 🌍 Supported Sites

MediaDL has optimized detection for these platforms, plus **generic `<video>` detection** for any site yt-dlp supports:

<div align="center">

| | Platform | Video | Audio | | Platform | Video | Audio |
|:--|:--|:--:|:--:|:--|:--|:--:|:--:|
| ▶️ | **YouTube** | ✅ | ✅ | 🔵 | **Vimeo** | ✅ | ✅ |
| 📘 | **Facebook** | ✅ | ✅ | 🔊 | **SoundCloud** | — | ✅ |
| 🐦 | **Twitter / X** | ✅ | ✅ | 🎸 | **Bandcamp** | — | ✅ |
| 🎵 | **TikTok** | ✅ | ✅ | 📺 | **Dailymotion** | ✅ | ✅ |
| 📷 | **Instagram** | ✅ | ✅ | 🅱️ | **Bilibili** | ✅ | ✅ |
| 🟣 | **Twitch** | ✅ | ✅ | 🏴 | **Rumble / Odysee** | ✅ | ✅ |
| 🔴 | **Reddit** | ✅ | ✅ | 🍿 | **Crunchyroll / Nebula** | ✅ | ✅ |

<sub>+ Kick, Floatplane, Streamable, Imgur, Arte, Tagesschau, and <b>1800+ more via yt-dlp</b></sub>

</div>

<br>

## ✨ Features

### 🌐 MediaDL Userscript

<table>
<tr>
<td width="33%" valign="top">

#### 🔍 Auto-Detect
Scans every page for video and audio elements. Attaches floating download pills automatically — no clicking required.

#### 🛡️ 3-Tier Failover
HTTP server → protocol handler → GM_download. If one method fails, the next activates seamlessly.

</td>
<td width="33%" valign="top">

#### ⚡ Background Server
Lightweight HTTP server on `127.0.0.1:9751`. Concurrent downloads, progress tracking, queue management. Starts on login.

#### 🔑 Zero-Config Auth
Server token negotiated automatically via `X-MDL-Client` header handshake. No manual setup.

</td>
<td width="33%" valign="top">

#### 📊 Progress Toasts
In-page progress bars with download speed and ETA. Appear at the bottom-right of the browser window.

#### 🔄 SPA Compatible
MutationObserver + URL change detection handles single-page navigation on YouTube, Facebook, Twitter, and all modern SPAs.

</td>
</tr>
</table>

### 🖥️ Download Handler

<table>
<tr>
<td width="33%" valign="top">

#### 🧵 Async UI
Title and thumbnail fetched in background jobs. The progress popup renders instantly and never freezes.

#### 🎯 Duplicate Prevention
SHA256 URL lock prevents accidental double-downloads from rapid clicking.

#### 📈 Smooth Progress
Animated bar with eased interpolation. Reads only last 4KB via `FileStream.Seek`.

</td>
<td width="33%" valign="top">

#### 🔪 Cancel Kills All
Cancelling kills both the PowerShell wrapper and child `yt-dlp.exe` / `ffmpeg.exe` via CIM process lookup.

#### 🖼️ Universal Thumbnails
YouTube via direct API. All other sites via `yt-dlp --get-thumbnail`. Both non-blocking.

#### 📂 Open on Complete
Click "Complete!" to open Explorer with the downloaded file pre-selected.

</td>
<td width="33%" valign="top">

#### 🪟 Win11 Native
DWM rounded corners via `DwmSetWindowAttribute`. Degrades gracefully on Windows 10.

#### 🔄 yt-dlp Auto-Update
Self-update throttled to once per 24 hours via timestamp file.

#### 🛑 Crash-Proof
4-layer exception handling: closing flag, nuclear try/catch, control guards, and global `Application.ThreadException`.

</td>
</tr>
</table>

<br>

## 📸 Screenshots

<details>
<summary><h3>Installer Wizard</h3></summary>
<br>
<div align="center">
<img width="984" height="892" alt="Installer - Welcome" src="https://github.com/user-attachments/assets/86cc4732-25ad-47de-9b0a-9b562b6b9b94" />
<br><br>
<img width="984" height="892" alt="Installer - Config" src="https://github.com/user-attachments/assets/db2ce562-fa7a-44b5-ad57-a414cd01e5e9" />
<br><br>
<img width="984" height="892" alt="Installer - Complete" src="https://github.com/user-attachments/assets/6d2fefc3-5445-4390-adc0-e3e3c2d64e54" />
</div>
<br>
</details>

<br>

## 🏗️ Architecture

```
 ┌─ Browser ───────────────────────┐    ┌─ Windows ──────────────────────────┐
 │                                 │    │                                    │
 │  MediaDL Userscript             │    │  ┌─ Tier 1: Download Server ────┐  │
 │  ├─ Auto-detect <video>         │HTTP│  │  ytdl-server.ps1              │  │
 │  ├─ Floating download pills     │◀──▶│  │  127.0.0.1:9751              │  │
 │  ├─ Facebook 6-layer extraction │    │  │  ├─ Concurrent downloads (3x) │  │
 │  ├─ In-page progress toasts     │    │  │  ├─ Real-time progress        │  │
 │  └─ SPA navigation handling     │    │  │  └─ Auto-start on login      │  │
 │                                 │    │  └───────────────────────────────  │
 │         ┌──────────────┐   ytdl://   │                                    │
 │         │ Click pill    │────────▶│  ┌─ Tier 2: Protocol Handler ────┐  │
 │         └──────────────┘        │    │  │  ytdl-handler.ps1            │  │
 │                                 │    │  │  ├─ Progress popup           │  │
 │         ┌──────────────┐   GM_dl│    │  │  ├─ Thumbnail + title        │  │
 │         │ CDN direct    │───────▶│  │  └─ Auto-retry (3x)           │  │
 │         └──────────────┘        │    │  └──────────────────────────────  │
 └─────────────────────────────────┘    └────────────────────────────────────┘
                                                      │
                                          Scheduled Task: MediaDL-Server
                                          (auto-start on login, hidden)
```

| Tier | Method | How | Progress | Activates When |
|:--:|:--|:--|:--:|:--|
| **1** | HTTP Server | `GM_xmlhttpRequest` to `127.0.0.1:9751` | ✅ Real-time polling | Server is running *(default)* |
| **2** | Protocol Handler | `ytdl://` URL triggers `ytdl-handler.ps1` | ✅ Popup window | Server is offline |
| **3** | Browser Direct | `GM_download` for CDN URLs | ❌ None | Both 1 & 2 fail, URL is direct CDN |

<br>

<details>
<summary><h3>🔬 Facebook 6-Layer Extraction</h3></summary>
<br>

Facebook aggressively obfuscates video URLs. MediaDL defeats this with **six extraction layers** tried in priority order:

| # | Layer | Technique |
|:--:|:--|:--|
| 1 | **XHR/Fetch Intercept** | Hooks `window.fetch` and `XMLHttpRequest` at `document-start` to capture `playable_url_quality_hd` from GraphQL responses |
| 2 | **Performance Resource Timing** | Scans `performance.getEntriesByType('resource')` for `fbcdn.net` video entries, sorted by transfer size |
| 3 | **React Fiber Tree Walk** | Traverses `__reactFiber` from the `<video>` element upward through `memoizedProps` searching for `browser_native_hd_url` |
| 4 | **Embedded JSON Scrape** | Searches `<script type="application/json">` blocks for HD video URL patterns |
| 5 | **DOM Permalink Walk** | Climbs the DOM tree from the video element to find a `/videos/`, `/watch/`, or `/reel/` link |
| 6 | **Page URL Fallback** | Uses `window.location.href` if it matches a Facebook video/reel/story URL pattern |

</details>

<details>
<summary><h3>🔌 Server API Reference</h3></summary>
<br>

The download server runs on `127.0.0.1:9751` (localhost only, not exposed to network).

| Method | Endpoint | Auth | Response |
|:--|:--|:--:|:--|
| `GET` | `/health` | — | Server status. Returns auth token when `X-MDL-Client: MediaDL` header is present |
| `POST` | `/download` | 🔐 | Start download. Body: `{url, title, audioOnly, referer}`. Returns `{id}` |
| `GET` | `/status/:id` | 🔐 | `{status, progress, speed, eta, filename}` |
| `GET` | `/queue` | 🔐 | Array of all active downloads with status |
| `DELETE` | `/cancel/:id` | 🔐 | Cancel and clean up a download |
| `GET` | `/shutdown` | 🔐 | Gracefully stop the server |

<sub>🔐 = Requires <code>X-Auth-Token</code> header (auto-negotiated by the userscript)</sub>

</details>

<br>

## 📂 Project Files

| File | Description |
|:--|:--|
| `Install-MediaDL.ps1` | PowerShell WPF installer wizard (dark-themed GUI) |
| `MediaDL.user.js` | Userscript — auto-detect on all websites |
| `ytdl-server.ps1` | Hidden HTTP download server (`127.0.0.1:9751`) |
| `ytdl-handler.ps1` | Protocol handler with async progress popup |
| `ytdl-server-launcher.vbs` | Windowless server launcher |
| `ytdl-launcher.vbs` | Silent handler launcher |
| `config.json` | Paths, server port/token, preferences |

<br>

## 💻 Installation

### Option 1 — Automatic Installer *(recommended)*

```powershell
# Open PowerShell as Administrator, then run:
irm https://raw.githubusercontent.com/SysAdminDoc/YTYT-Downloader/refs/heads/main/src/Install-MediaDL.ps1 | iex
```

The installer creates a **`MediaDL-Server`** Scheduled Task that auto-starts the background server on login. No console windows will appear.

### Option 2 — Manual Installation

1. Install [Tampermonkey](https://www.tampermonkey.net/) or [Violentmonkey](https://violentmonkey.github.io/)
2. Install the userscript:
   - **[MediaDL — Universal Media Downloader](https://github.com/SysAdminDoc/YTYT-Downloader/raw/refs/heads/main/src/MediaDL.user.js)**
3. Install [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [ffmpeg](https://ffmpeg.org/)
4. Set up protocol handlers manually *(see below)*

<details>
<summary><b>Protocol Handler Registry Entry</b></summary>

```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\ytdl]
@="URL:YTDL Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\ytdl\shell\open\command]
@="wscript.exe \"C:\\Path\\To\\ytdl-launcher.vbs\" \"%1\""
```

</details>

<br>

## 📋 Requirements

<table>
<tr>
<td width="50%">

### 🤖 Automatic *(recommended)*

The installer handles everything:

| | Component | Status |
|:--|:--|:--|
| ✅ | yt-dlp | Auto-downloaded |
| ✅ | ffmpeg | Auto-downloaded |
| ✅ | Protocol handler | Auto-registered |
| ✅ | Download server | Auto-deployed |
| ✅ | Scheduled Task | Auto-created |

</td>
<td width="50%">

### 🔧 Manual

If installing without the wizard:

| | Component | Link |
|:--|:--|:--|
| 📌 | Userscript manager | [Tampermonkey](https://www.tampermonkey.net/) |
| 📌 | yt-dlp | [GitHub](https://github.com/yt-dlp/yt-dlp) |
| 📌 | ffmpeg | [ffmpeg.org](https://ffmpeg.org/) |

</td>
</tr>
</table>

<br>

## 🔧 Troubleshooting

| Issue | Solution |
|:--|:--|
| Download pills don't appear | Refresh the page. Verify userscript is enabled with `@match *://*/*` |
| Server not running | Check Task Scheduler for `MediaDL-Server`, or run `ytdl-server-launcher.vbs` manually |
| Facebook downloads fail | Click the video to trigger playback first (populates CDN URLs for extraction) |
| Download fails silently | Verify yt-dlp and ffmpeg are installed and paths are correct in `config.json` |
| JIT debugging dialog | Update to the latest handler (4-layer crash prevention) |
| Duplicate downloads | Update to the latest handler (SHA256 URL lock) |

<br>

## 🗑️ Uninstalling

> Run the installer again — it auto-removes the previous installation before reinstalling.

For full manual removal:

1. **Task Scheduler** → Delete the `MediaDL-Server` task
2. **Delete** `%LOCALAPPDATA%\MediaDL`
3. **Registry** → Remove `HKCU:\Software\Classes\ytdl`
4. **Browser** → Remove the userscript from Tampermonkey

<br>

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

<br>

---

<div align="center">

### Built With

<br>

[![yt-dlp](https://img.shields.io/badge/yt--dlp-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://github.com/yt-dlp/yt-dlp)
&nbsp;&nbsp;
[![ffmpeg](https://img.shields.io/badge/ffmpeg-007808?style=for-the-badge&logo=ffmpeg&logoColor=white)](https://ffmpeg.org/)
&nbsp;&nbsp;
[![PowerShell](https://img.shields.io/badge/PowerShell-0078D4?style=for-the-badge&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)

<br><br>

[<kbd> <br> &nbsp;&nbsp;🐛 Report Issues&nbsp;&nbsp; <br> </kbd>](https://github.com/SysAdminDoc/YTYT-Downloader/issues)&nbsp;&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;⭐ Star on GitHub&nbsp;&nbsp; <br> </kbd>](https://github.com/SysAdminDoc/YTYT-Downloader)&nbsp;&nbsp;&nbsp;&nbsp;
[<kbd> <br> &nbsp;&nbsp;👤 SysAdminDoc&nbsp;&nbsp; <br> </kbd>](https://github.com/SysAdminDoc)

<br>

<sub>Made with ❤️ by <a href="https://github.com/SysAdminDoc">SysAdminDoc</a></sub>

<br>

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:00b894,50:0984e3,100:6c5ce7&height=100&section=footer" />

</div>
