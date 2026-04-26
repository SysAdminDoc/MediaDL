# Roadmap

Universal media downloader: userscript + background PowerShell HTTP server wrapping yt-dlp/ffmpeg for 1800+ sites. Roadmap focuses on extractor resilience, queue intelligence, and cross-browser reach.

## Planned Features

### Extractor Hardening
- 7th Facebook extraction layer: MQTT/GraphQL WebSocket frame sniffing for Reels HD URLs
- Instagram Stories/Highlights extraction (currently Reels only)
- TikTok watermark-free MP4 via web-SSR + wmplay fallback
- Twitter/X Space audio extraction (HLS m3u8 of live audio rooms)
- Chapter-split mode: honor YouTube `Chapters:` metadata, emit per-chapter files
- Live-stream record mode: detect live YouTube / Twitch and offer "record from now" window

### Download Queue
- Persistent queue across server restarts (SQLite journal at `%LOCALAPPDATA%\MediaDL\queue.db`)
- Bandwidth throttle slider + per-site concurrency cap
- Pause / resume individual downloads via `X-Auth-Token` protected REST
- Priority re-order with drag handles in a queue-viewer page served at `127.0.0.1:9751/ui`
- Duplicate detection by video ID + channel (not just URL SHA256)
- Post-processing chain: auto-extract audio → auto-tag with MusicBrainz → move to Music folder

### Format Control
- Per-site format preset (YouTube: 1080p AV1, Twitter: best MP4, SoundCloud: FLAC fallback → MP3)
- Quality picker overlay on the floating pill (click-hold to pick 720p/1080p/4K)
- Subtitle auto-download + SRT mux into MKV
- Hardware-accelerated transcode path (NVENC/QSV) behind a checkbox

### Cross-Browser
- Firefox MV3 parity (manifest_version 3 + background scripts signing for AMO)
- Chrome extension variant (promotes the userscript to real MV3)
- Edge-specific vertical-tab integration (sidebar queue viewer)
- Mobile Userscripts (Kiwi Browser / Orion) — strip Windows-specific paths

### Server Infrastructure
- Named-pipe transport in addition to HTTP (avoid 9751 port collisions)
- Windows Toast notifications on completion (background server firing into WinRT)
- Auto-update yt-dlp + ffmpeg with cryptographic signature check
- Plugin SDK: drop a `.ps1` file in `%LOCALAPPDATA%\MediaDL\plugins\` exposing a new extractor

## Competitive Research
- **yt-dlp** — the engine; track breakage in supportedsites.md and ship yt-dlp pin updates within 24h.
- **JDownloader 2** — reference for queue UX, captcha handling, and host plugin architecture.
- **Video DownloadHelper** — best Firefox integration we don't match yet (context-menu + on-page pills).
- **Cobalt.tools** — minimalist UX with excellent site coverage; lessons for the pill overlay simplicity.

## Nice-to-Haves
- IPFS output mode: auto-pin downloaded media to a local IPFS node and emit CID
- Plex/Jellyfin post-hook: move to library and trigger scan via local API
- Discord webhook per completion (thumbnail + duration + size)
- Clipboard monitor: paste a URL anywhere → offer download via toast
- "Download channel" mode: queue entire playlist/channel with rate-limit and resume
- Shared-link mode: HTTPS-only external bearer token for LAN-based phone downloads

## Open-Source Research (Round 2)

### Related OSS Projects
- https://github.com/yt-dlp/yt-dlp — upstream engine, 1800+ sites, three release channels (stable/nightly/master)
- https://github.com/jely2002/youtube-dl-gui — Tauri + Vue 3 + Rust, cross-platform, auto-update for app + yt-dlp
- https://github.com/dsymbol/yt-dlp-gui — PySide6 cross-platform, GitHub Actions release pipeline
- https://github.com/ErrorFlynn/ytdlp-interface — Nana C++ Windows GUI, libjpeg-turbo + libpng + bit7z
- https://github.com/database64128/youtube-dl-wpf — WPF GUI, GPLv3, BYO-downloader pattern
- https://github.com/kannagi0303/yt-dlp-gui — Windows GUI, presets
- https://github.com/vokrob/yt-dlp-gui — desktop GUI
- https://github.com/himanshuxd/HXD-yt-dlp-GUI — clipboard-triggered download workflow
- https://github.com/JunkFood02/Seal — Android yt-dlp wrapper with Material You

### Features to Borrow
- Clipboard-watch mode that auto-queues a download when a supported URL is copied (HXD-yt-dlp-GUI) — big UX win for MediaDL users working across browser tabs
- Auto-update both the wrapper and yt-dlp binary on launch (jely2002/youtube-dl-gui) — yt-dlp breaks weekly, stale binaries are MediaDL's #1 support burden
- Smart queue balancing with per-host concurrency caps (jely2002) — avoids YouTube ratelimits when downloading playlists
- Format matrix UI (click cells to pick webm/mkv/mp4 × audio/video) instead of dropdowns (HXD-yt-dlp-GUI)
- Post-processing pipeline toggles: embed subtitles, embed thumbnail, write metadata JSON (jely2002) — already supported in yt-dlp CLI, surface in GUI
- Release channel selector (stable / nightly / master) matching yt-dlp's three channels (yt-dlp docs)
- BYO-downloader path config for users who want specific yt-dlp forks (database64128) — useful for custom extractors

### Patterns & Architectures Worth Studying
- Tauri + Rust backend wrapping the yt-dlp binary (jely2002) — 5MB installer vs Electron's 100MB, same UX — consider as v5 rewrite target if PowerShell UI hits limits
- JSON-schema-backed preset format that can be shared between users (Axiom-style config) — lets MediaDL publish a preset library
- Per-site extractor plugin manifest (yt-dlp `--extractor-args`) — expose as GUI dropdowns for sites with known quirks (Twitter auth, Instagram cookies)
- GitHub Actions workflow with matrix builds (Windows/macOS/Linux) + auto-release (dsymbol/yt-dlp-gui) — template for MediaDL CI
