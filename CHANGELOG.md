# Changelog

All notable changes to MediaDL will be documented in this file.

## [v5.1.0] - 2026-08-03

- Added: Facebook MQTT/GraphQL WebSocket frame extraction for HD Reels URLs.
- Changed: Facebook extraction now uses seven ranked layers and rescans after captured WebSocket media.
- Added: Instagram-specific extraction for Stories, Highlights, Reels, and embedded CDN video JSON.
- Added: TikTok SSR extraction with watermark-free play URL priority and wmplay fallback.
- Added: X/Twitter Spaces HLS audio discovery and audio-element scanning.
- Added: Optional YouTube chapter splitting with section-numbered output files.
- Added: Live YouTube/Twitch detection with a record-from-now action and protocol fallback.
- Added: SQLite WAL queue journal with interrupted-item restoration across server restarts.
- Added: Bandwidth throttle slider and per-site concurrency enforcement for active downloads.
- Added: Authenticated pause/resume endpoints that suspend and resume yt-dlp process trees.
- Added: Local `/ui` queue viewer with drag-handle priority reordering and download controls.
- Added: Priority persistence and migration in the SQLite queue journal.
- Added: Site/video/channel content identity deduplication across userscript, server, and protocol-handler paths.
- Added: Opt-in post-processing to extract MP3 audio, tag it with MusicBrainz, and move it to the configured Music folder.
- Added: Editable per-site format presets with codec selection, SoundCloud audio fallback, and a floating-pill quality picker for 720p, 1080p, and 4K requests.
- Added: Optional SRT subtitle downloads with automatic-caption support and MKV subtitle muxing.
- Added: Opt-in NVENC/QSV hardware transcode pass with safe no-op behavior when the encoder or container is unsupported.
- Added: Unsigned MV3 Chrome and Firefox extension variants generated from the userscript, plus an Edge side-panel queue viewer.
- Added: Mobile Kiwi Browser/Orion userscript with direct-media downloads and explicit blob/HLS desktop-only messaging.
- Added: Authenticated newline-delimited JSON named-pipe transport alongside the localhost HTTP server.
- Added: Opt-in native Windows completion toasts from the background server with fail-safe WinRT handling.
- Added: Daily yt-dlp and ffmpeg updates with GitHub release asset origin and SHA-256 digest verification.
- Added: Trusted local extractor plugin SDK with registration, load limits, `/plugins` discovery, and normal queue integration.
- Added: Explicit channel and playlist collection detection with archive-backed resume, rate limiting, and collection-aware output folders.

## [v5.0.0] - 2026-08-03

- Added: Add @updateURL and @downloadURL to userscripts
- Removed: Delete screenshot.png
- Changed: Update README.md
- Added: Add screenshot to README
- Added: Add files via upload
- Added: Add files via upload
- Added: Add files via upload
- Create test
- Added: Add files via upload
- Added: Add files via upload

## Roadmap archive — 2026-08-10 — ROADMAP.md

<details>
<summary>Original roadmap snapshot</summary>

```markdown
# Roadmap

Universal media downloader: userscript + background PowerShell HTTP server wrapping yt-dlp/ffmpeg for 1800+ sites. Roadmap focuses on extractor resilience, queue intelligence, and cross-browser reach.

## Planned Features

### Extractor Hardening

### Download Queue

### Format Control

### Cross-Browser

### Server Infrastructure

## Competitive Research
- **yt-dlp** — the engine; track breakage in supportedsites.md and ship yt-dlp pin updates within 24h.
- **JDownloader 2** — reference for queue UX, captcha handling, and host plugin architecture.
- **Video DownloadHelper** — best Firefox integration we don't match yet (context-menu + on-page pills).
- **Cobalt.tools** — minimalist UX with excellent site coverage; lessons for the pill overlay simplicity.

## Nice-to-Haves

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
```

</details>
