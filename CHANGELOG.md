# Changelog

All notable changes to MediaDL will be documented in this file.

## [Unreleased]

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

## [v4.0.0] - %Y->- (HEAD -> main, origin/main, origin/HEAD)

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
