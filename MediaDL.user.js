// ==UserScript==
// @name         MediaDL - Universal Media Downloader
// @namespace    https://github.com/SysAdminDoc/MediaDL
// @version      4.0.0
// @description  Download videos and extract audio from 1800+ sites - powered by yt-dlp. Auto-scans all pages for media.
// @author       SysAdminDoc
// @license      MIT
// @match        *://*/*
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2300b894'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z'/%3E%3C/svg%3E
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @grant        GM_download
// @connect      localhost
// @connect      127.0.0.1
// @run-at       document-start
// @noframes
// ==/UserScript==

(function() {
    'use strict';

    // =========================================================================
    // ANTI-FOUC
    // =========================================================================
    const antiFouc = document.createElement('style');
    antiFouc.textContent = '.mdl-pill, #mediadl-toast { display: none !important; }';
    (document.head || document.documentElement).appendChild(antiFouc);

    // =========================================================================
    // CONFIGURATION
    // =========================================================================
    const CONFIG = {
        version: '4.0.0',
        debounceMs: 300,
        scanIntervalMs: 2000,
        positionIntervalMs: 200,
        protocol: 'ytdl',
        attr: 'data-mdl',
        pillIdAttr: 'data-mdl-pill',
        serverPort: 9751,
        serverUrl: 'http://127.0.0.1:9751',
        pollIntervalMs: 800,
        maxPollTime: 600000 // 10 minutes
    };

    // Server state
    let serverAlive = false;
    let serverToken = GM_getValue('mdl_server_token', '');

    // =========================================================================
    // FACEBOOK XHR/FETCH INTERCEPT
    // Inject into page context to capture video CDN URLs from API responses
    // =========================================================================
    if (location.hostname.includes('facebook.com') || location.hostname.includes('fb.com')) {
        try {
            const interceptScript = document.createElement('script');
            interceptScript.textContent = `(function(){
                if(window.__mdl_intercepted) return;
                window.__mdl_intercepted = true;
                window.__mdl_captured_urls = [];
                const _fetch = window.fetch;
                window.fetch = function(){
                    return _fetch.apply(this, arguments).then(function(r){
                        try {
                            var cl = r.clone();
                            cl.text().then(function(t){
                                try {
                                    var m = t.match(/https?:\\\\/\\\\/[^"\\\\s]*?fbcdn\\\\.net[^"\\\\s]*?(mp4|video)[^"\\\\s]*/g);
                                    if(m) {
                                        m.forEach(function(u){
                                            u = u.replace(/\\\\\\\\/g,'/').replace(/\\\\\\\\u0025/g,'%');
                                            if(window.__mdl_captured_urls.indexOf(u)===-1 && u.length < 2000)
                                                window.__mdl_captured_urls.push(u);
                                        });
                                    }
                                    var hd = t.match(/"(?:browser_native_hd_url|playable_url_quality_hd|hd_src)":"(https?:[^"]+)"/g);
                                    if(hd) {
                                        hd.forEach(function(s){
                                            var val = s.split('":"')[1];
                                            if(val) {
                                                val = val.slice(0,-1).replace(/\\\\\\\\/g,'/').replace(/\\\\\\\\u0025/g,'%');
                                                if(window.__mdl_captured_urls.indexOf(val)===-1)
                                                    window.__mdl_captured_urls.push(val);
                                            }
                                        });
                                    }
                                } catch(e){}
                            }).catch(function(){});
                        } catch(e){}
                        return r;
                    });
                };
                var _open = XMLHttpRequest.prototype.open;
                var _send = XMLHttpRequest.prototype.send;
                XMLHttpRequest.prototype.open = function(m,u){ this.__mdl_url = u; return _open.apply(this,arguments); };
                XMLHttpRequest.prototype.send = function(){
                    this.addEventListener('load', function(){
                        try {
                            if(this.responseText && this.responseText.length > 100) {
                                var m = this.responseText.match(/"(?:browser_native_hd_url|playable_url_quality_hd|hd_src|sd_src|playable_url)":"(https?:[^"]+)"/g);
                                if(m) {
                                    m.forEach(function(s){
                                        var val = s.split('":"')[1];
                                        if(val) {
                                            val = val.slice(0,-1).replace(/\\\\\\\\/g,'/').replace(/\\\\\\\\u0025/g,'%');
                                            if(window.__mdl_captured_urls.indexOf(val)===-1)
                                                window.__mdl_captured_urls.push(val);
                                        }
                                    });
                                }
                            }
                        } catch(e){}
                    });
                    return _send.apply(this,arguments);
                };
            })();`;
            (document.head || document.documentElement).appendChild(interceptScript);
            interceptScript.remove();
        } catch(e) { console.log('MediaDL: XHR intercept injection failed:', e); }
    }

    // =========================================================================
    // REFERER SITES
    // =========================================================================
    const REFERER_SITES = {
        'vimeo.com': 'https://vimeo.com/',
        'www.vimeo.com': 'https://vimeo.com/',
        'player.vimeo.com': 'https://vimeo.com/',
        'instagram.com': 'https://www.instagram.com/',
        'www.instagram.com': 'https://www.instagram.com/',
    };

    // =========================================================================
    // SITE CONFIGS
    // =========================================================================
    const SITE_CONFIGS = {
        'youtube.com': { name: 'YouTube' }, 'm.youtube.com': { name: 'YouTube' },
        'music.youtube.com': { name: 'YouTube Music' }, 'youtu.be': { name: 'YouTube' },
        'vimeo.com': { name: 'Vimeo' }, 'player.vimeo.com': { name: 'Vimeo' },
        'twitter.com': { name: 'Twitter' }, 'x.com': { name: 'X' },
        'tiktok.com': { name: 'TikTok' }, 'instagram.com': { name: 'Instagram' },
        'twitch.tv': { name: 'Twitch' }, 'reddit.com': { name: 'Reddit' },
        'dailymotion.com': { name: 'Dailymotion' },
        'soundcloud.com': { name: 'SoundCloud', audioOnly: true },
        'bandcamp.com': { name: 'Bandcamp', audioOnly: true },
        'rumble.com': { name: 'Rumble' }, 'odysee.com': { name: 'Odysee' },
        'bilibili.com': { name: 'Bilibili' },
        'facebook.com': { name: 'Facebook' }, 'fb.com': { name: 'Facebook' },
        'streamable.com': { name: 'Streamable' }, 'imgur.com': { name: 'Imgur' },
        'arte.tv': { name: 'Arte' }, 'tagesschau.de': { name: 'Tagesschau' },
        'nebula.tv': { name: 'Nebula' }, 'floatplane.com': { name: 'Floatplane' },
        'kick.com': { name: 'Kick' }, 'crunchyroll.com': { name: 'Crunchyroll' }
    };

    // =========================================================================
    // STYLES
    // =========================================================================
    const STYLES = `
        .mdl-pill, #mediadl-toast { display: flex !important; }
        .mdl-pill {
            position: fixed; z-index: 2147483647;
            display: flex; align-items: center; gap: 4px;
            background: rgba(0,0,0,0.85); backdrop-filter: blur(8px);
            border-radius: 8px; padding: 4px; cursor: default;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            box-shadow: 0 2px 12px rgba(0,0,0,0.5); pointer-events: auto;
            transition: opacity 0.2s;
        }
        .mdl-pill-btn {
            display: flex; align-items: center; justify-content: center;
            width: 32px; height: 28px; border: none; border-radius: 5px;
            cursor: pointer; transition: all 0.15s; padding: 0;
        }
        .mdl-pill-btn:hover { transform: scale(1.08); filter: brightness(1.2); }
        .mdl-pill-btn svg { width: 16px; height: 16px; fill: currentColor; }
        .mdl-pill-btn.video { background: linear-gradient(135deg, #00b894, #00a085); color: white; }
        .mdl-pill-btn.audio { background: linear-gradient(135deg, #6c5ce7, #5b4cdb); color: white; }
        .mdl-pill-label {
            font-size: 10px; color: rgba(255,255,255,0.6); padding: 0 4px;
            max-width: 80px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        }

        #mediadl-toast {
            position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%);
            z-index: 2147483647; padding: 10px 20px; border-radius: 8px;
            font: 13px/1.4 -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            color: white; pointer-events: none; opacity: 0;
            transition: opacity 0.3s; backdrop-filter: blur(10px);
            max-width: 500px; text-align: center;
        }
        #mediadl-toast.show { opacity: 1; pointer-events: auto; }
        #mediadl-toast.info { background: rgba(0,184,148,0.9); }
        #mediadl-toast.error { background: rgba(214,48,49,0.9); }
        #mediadl-toast.warn { background: rgba(253,203,110,0.9); color: #333; }
        #mediadl-toast .mdl-progress-wrap {
            margin-top: 6px; height: 4px; background: rgba(255,255,255,0.2);
            border-radius: 2px; overflow: hidden;
        }
        #mediadl-toast .mdl-progress-bar {
            height: 100%; background: white; border-radius: 2px;
            transition: width 0.3s ease; width: 0%;
        }
    `;

    // =========================================================================
    // ICONS
    // =========================================================================
    const ICONS = {
        dl: '<svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm-1 14.5v-9l6 4.5-6 4.5z"/></svg>',
        audio: '<svg viewBox="0 0 24 24"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55C7.79 13 6 14.79 6 17s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>'
    };

    // =========================================================================
    // SERVER COMMUNICATION
    // =========================================================================
    function serverRequest(method, path, data) {
        return new Promise((resolve, reject) => {
            const opts = {
                method: method,
                url: `${CONFIG.serverUrl}${path}`,
                headers: { 'Content-Type': 'application/json' },
                timeout: 5000,
                onload: (r) => {
                    try { resolve(JSON.parse(r.responseText)); }
                    catch { resolve(null); }
                },
                onerror: () => reject(new Error('Network error')),
                ontimeout: () => reject(new Error('Timeout'))
            };
            if (serverToken) opts.headers['X-Auth-Token'] = serverToken;
            if (data) opts.data = JSON.stringify(data);
            GM_xmlhttpRequest(opts);
        });
    }

    async function checkServer() {
        try {
            // Use X-MDL-Client header so server returns token
            const r = await new Promise((resolve, reject) => {
                GM_xmlhttpRequest({
                    method: 'GET',
                    url: `${CONFIG.serverUrl}/health`,
                    headers: { 'X-MDL-Client': 'MediaDL' },
                    timeout: 3000,
                    onload: (resp) => {
                        try { resolve(JSON.parse(resp.responseText)); } catch { resolve(null); }
                    },
                    onerror: () => reject(new Error('Network error')),
                    ontimeout: () => reject(new Error('Timeout'))
                });
            });
            if (r && r.status === 'ok') {
                serverAlive = true;
                // Auto-cache token
                if (r.token && r.token !== serverToken) {
                    serverToken = r.token;
                    GM_setValue('mdl_server_token', serverToken);
                    console.log('MediaDL: Server token auto-configured');
                }
                console.log(`MediaDL: Server connected (port ${r.port}, ${r.downloads} active)`);
                return true;
            }
        } catch {}
        serverAlive = false;
        return false;
    }

    async function serverDownload(url, title, audioOnly, referer) {
        try {
            const r = await serverRequest('POST', '/download', {
                url, title, audioOnly: !!audioOnly, referer: referer || null
            });
            if (r && r.id) {
                console.log(`MediaDL: Server download started: ${r.id}`);
                pollProgress(r.id, title);
                return true;
            }
            if (r && r.error) {
                console.log(`MediaDL: Server error: ${r.error}`);
                if (r.error === 'Unauthorized') {
                    showToast('Server auth failed - check token', 'error');
                }
            }
        } catch(e) {
            console.log(`MediaDL: Server request failed: ${e.message}`);
        }
        return false;
    }

    function pollProgress(id, title) {
        const shortTitle = title ? (title.length > 40 ? title.substring(0, 38) + '...' : title) : 'Download';
        let toastEl = null;
        let progressEl = null;
        const startTime = Date.now();

        const poll = async () => {
            if (Date.now() - startTime > CONFIG.maxPollTime) {
                updateToast(toastEl, `${shortTitle} - timed out`, 'warn');
                return;
            }
            try {
                const r = await serverRequest('GET', `/status/${id}`);
                if (!r) { setTimeout(poll, CONFIG.pollIntervalMs); return; }

                if (!toastEl) {
                    toastEl = showProgressToast(`${shortTitle}`, 'info');
                    progressEl = toastEl?.querySelector('.mdl-progress-bar');
                }

                const pct = Math.round(r.progress || 0);
                const statusText = r.status === 'merging' ? 'Merging...'
                    : r.status === 'extracting' ? 'Extracting audio...'
                    : r.speed ? `${pct}% | ${r.speed}` : `${pct}%`;

                if (toastEl) {
                    const msgEl = toastEl.querySelector('.mdl-toast-msg');
                    if (msgEl) msgEl.textContent = `${shortTitle} - ${statusText}`;
                    if (progressEl) progressEl.style.width = `${pct}%`;
                }

                if (r.status === 'complete') {
                    if (progressEl) progressEl.style.width = '100%';
                    updateToast(toastEl, `${shortTitle} - Complete!`, 'info', 3000);
                    return;
                }
                if (r.status === 'failed') {
                    updateToast(toastEl, `${shortTitle} - Failed`, 'error', 5000);
                    return;
                }
                if (r.status === 'cancelled') {
                    updateToast(toastEl, `${shortTitle} - Cancelled`, 'warn', 3000);
                    return;
                }
                setTimeout(poll, CONFIG.pollIntervalMs);
            } catch {
                setTimeout(poll, CONFIG.pollIntervalMs * 2);
            }
        };
        setTimeout(poll, 300);
    }

    // =========================================================================
    // TOAST SYSTEM
    // =========================================================================
    function showToast(msg, type = 'info', dur = 3000) {
        let el = document.getElementById('mediadl-toast');
        if (!el) { el = document.createElement('div'); el.id = 'mediadl-toast'; document.body.appendChild(el); }
        el.className = `show ${type}`;
        el.innerHTML = `<span class="mdl-toast-msg">${msg}</span>`;
        clearTimeout(el._t);
        if (dur > 0) el._t = setTimeout(() => { el.className = ''; }, dur);
        return el;
    }

    function showProgressToast(msg, type = 'info') {
        let el = document.getElementById('mediadl-toast');
        if (!el) { el = document.createElement('div'); el.id = 'mediadl-toast'; document.body.appendChild(el); }
        el.className = `show ${type}`;
        el.innerHTML = `<span class="mdl-toast-msg">${msg}</span>
            <div class="mdl-progress-wrap"><div class="mdl-progress-bar"></div></div>`;
        clearTimeout(el._t);
        return el;
    }

    function updateToast(el, msg, type, autoDismiss) {
        if (!el) return;
        el.className = `show ${type}`;
        const msgEl = el.querySelector('.mdl-toast-msg');
        if (msgEl) msgEl.textContent = msg;
        clearTimeout(el._t);
        if (autoDismiss) el._t = setTimeout(() => { el.className = ''; }, autoDismiss);
    }

    // =========================================================================
    // URL RESOLUTION
    // =========================================================================
    function resolveDownloadUrl(rawUrl) {
        let url = rawUrl;
        // Vimeo: convert to player URL
        const vm = url.match(/vimeo\.com\/(\d+)/);
        if (vm && !url.includes('player.vimeo.com')) url = `https://player.vimeo.com/video/${vm[1]}`;
        // YouTube: normalize
        const yp = new URLSearchParams(new URL(url, location.href).search);
        if ((url.includes('youtube.com/watch') || url.includes('youtu.be/')) && yp.get('v')) {
            url = `https://www.youtube.com/watch?v=${yp.get('v')}`;
        }
        return url;
    }

    function getPageTitle() {
        let title = document.title || '';
        title = title
            .replace(/^\(\d+\)\s*/, '')
            .replace(/\s*[|\-]\s*Facebook\s*$/i, '')
            .replace(/\s*[|\-]\s*Instagram\s*$/i, '')
            .replace(/\s*[|\-]\s*X\s*$/i, '')
            .replace(/\s*[|\-]\s*Twitter\s*$/i, '')
            .replace(/\s*[|\-]\s*YouTube\s*$/i, '')
            .replace(/\s*[|\-]\s*Reddit\s*$/i, '')
            .replace(/\s*[|\-]\s*TikTok\s*$/i, '')
            .trim();
        return title;
    }

    function getReferer(url) {
        if (url && url.includes('fbcdn.net')) return 'https://www.facebook.com/';
        return REFERER_SITES[location.hostname] || REFERER_SITES[location.hostname.replace('www.','')] || null;
    }

    // =========================================================================
    // 3-TIER DOWNLOAD SYSTEM
    // Tier 1: HTTP Server (bidirectional, progress tracking)
    // Tier 2: Protocol Handler (fire-and-forget, needs handler installed)
    // Tier 3: GM_download (direct CDN URLs only, no yt-dlp needed)
    // =========================================================================
    async function triggerDownload(action, url) {
        if (!url) { showToast('No media URL found', 'error'); return; }
        url = resolveDownloadUrl(url);

        const title = getPageTitle();
        const audioOnly = action === 'audio';
        const referer = getReferer(url);
        const isDirect = /fbcdn\.net|\.mp4\?|\.webm\?/.test(url);

        let urlType = 'page URL';
        if (url.includes('fbcdn.net')) urlType = 'direct CDN URL';
        else if (url.includes('player.vimeo.com')) urlType = 'Vimeo player URL';
        console.log(`MediaDL: Download ${action} via ${urlType}:`, url.substring(0, 120));

        // --- TIER 1: HTTP Server ---
        if (serverAlive) {
            showToast(`Starting ${action} download via server...`, 'info', 1500);
            const ok = await serverDownload(url, title, audioOnly, referer);
            if (ok) return;
            console.log('MediaDL: Server download failed, trying protocol handler...');
        }

        // --- TIER 2: Protocol Handler ---
        const enc = encodeURIComponent(url);
        let params = '';
        if (audioOnly) params += 'ytyt_audio_only=1&';
        if (referer) params += `ytyt_referer=${encodeURIComponent(referer)}&`;
        if (title) params += `ytyt_title=${encodeURIComponent(title)}&`;

        let proto;
        if (params) {
            proto = `${CONFIG.protocol}://${enc}?${params.slice(0, -1)}`;
        } else {
            proto = `${CONFIG.protocol}://${enc}`;
        }

        // Check if protocol handler works by trying it, with GM_download fallback
        if (!isDirect || !canGMDownload(url)) {
            showToast(`Starting ${action} download...`, 'info', 2000);
            console.log('MediaDL: Protocol URL length:', proto.length);
            const a = document.createElement('a');
            a.href = proto;
            a.style.display = 'none';
            document.body.appendChild(a);
            a.click();
            setTimeout(() => a.remove(), 1000);
            return;
        }

        // --- TIER 3: GM_download (direct CDN URLs only) ---
        if (isDirect && !audioOnly) {
            console.log('MediaDL: Attempting GM_download for direct CDN URL');
            const ext = url.includes('.mp4') ? '.mp4' : '.mp4';
            const safeName = (title || 'video').replace(/[<>:"/\\|?*]/g, '_').substring(0, 100);
            showToast(`Downloading ${safeName}${ext}...`, 'info', 3000);
            try {
                GM_download({
                    url: url,
                    name: `${safeName}${ext}`,
                    headers: referer ? { Referer: referer } : {},
                    onload: () => showToast('Download complete!', 'info', 3000),
                    onerror: (e) => {
                        console.log('MediaDL: GM_download failed:', e);
                        showToast('Direct download failed', 'error', 3000);
                        // Final fallback: protocol handler
                        const a = document.createElement('a');
                        a.href = proto;
                        document.body.appendChild(a);
                        a.click();
                        setTimeout(() => a.remove(), 1000);
                    }
                });
                return;
            } catch(e) {
                console.log('MediaDL: GM_download exception:', e);
            }
        }

        // Final fallback
        showToast(`Starting ${action} download...`, 'info', 2000);
        const a2 = document.createElement('a');
        a2.href = proto;
        a2.style.display = 'none';
        document.body.appendChild(a2);
        a2.click();
        setTimeout(() => a2.remove(), 1000);
    }

    function canGMDownload(url) {
        // GM_download only works for direct URLs, not pages yt-dlp needs to process
        return /fbcdn\.net.*\.(mp4|webm)|\.mp4\?|\.webm\?/.test(url);
    }

    // =========================================================================
    // UTILITIES
    // =========================================================================
    function debounce(fn, ms) { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; }

    // =========================================================================
    // VIDEO DETECTION
    // =========================================================================
    const pillMap = new Map(); // id -> { pill, anchorEl }
    let pillCounter = 0;

    function isNativePlayer(el) {
        while (el) {
            if (el.classList && (el.classList.contains('html5-video-player') ||
                el.classList.contains('ytp-player') || el.id === 'movie_player'))
                return true;
            el = el.parentElement;
        }
        return false;
    }

    function createPill(url, label, color, audioOnly) {
        const pill = document.createElement('div');
        pill.className = 'mdl-pill';

        if (!audioOnly) {
            const dlBtn = document.createElement('button');
            dlBtn.className = 'mdl-pill-btn video';
            dlBtn.title = 'Download Video';
            dlBtn.innerHTML = ICONS.dl;
            dlBtn.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); triggerDownload('video', url); });
            pill.appendChild(dlBtn);
        }

        const mp3Btn = document.createElement('button');
        mp3Btn.className = 'mdl-pill-btn audio';
        mp3Btn.title = audioOnly ? 'Download Audio' : 'Extract MP3';
        mp3Btn.innerHTML = ICONS.audio;
        mp3Btn.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); triggerDownload('audio', url); });
        pill.appendChild(mp3Btn);

        if (label) {
            const lbl = document.createElement('span');
            lbl.className = 'mdl-pill-label';
            lbl.textContent = label;
            pill.appendChild(lbl);
        }

        return pill;
    }

    function registerPill(anchorEl, url, label, color, audioOnly) {
        const id = 'mdl-' + (++pillCounter);
        anchorEl.setAttribute(CONFIG.pillIdAttr, id);
        const pill = createPill(url, label, color, audioOnly);
        pill.setAttribute('data-pill-id', id);
        document.body.appendChild(pill);
        pillMap.set(id, { pill, anchorEl });
        positionPill(id);
        return pill;
    }

    function positionPill(id) {
        const entry = pillMap.get(id);
        if (!entry) return;
        const { pill, anchorEl } = entry;
        if (!document.body.contains(anchorEl)) return;
        const r = anchorEl.getBoundingClientRect();
        if (r.width < 40 || r.height < 30) { pill.style.opacity = '0'; return; }
        const visible = r.bottom > 0 && r.top < window.innerHeight && r.right > 0 && r.left < window.innerWidth;
        if (!visible) { pill.style.opacity = '0'; return; }
        pill.style.opacity = '1';
        pill.style.left = (r.left + 8) + 'px';
        pill.style.top = (r.top + 8) + 'px';
    }

    function positionAllPills() { for (const id of pillMap.keys()) positionPill(id); }

    function pruneOrphanedPills() {
        for (const [id, entry] of pillMap.entries()) {
            if (!document.body.contains(entry.anchorEl)) {
                entry.pill.remove();
                pillMap.delete(id);
            }
        }
    }

    // =========================================================================
    // EMBED + VIDEO SCANNING
    // =========================================================================
    function scanForEmbeds() {
        if (!document.body) return;
        scanVideoElements();
        // Scan iframes with known video sources
        document.querySelectorAll('iframe[src]').forEach(el => {
            if (el.hasAttribute(CONFIG.attr)) return;
            const src = el.src;
            let match = false;
            for (const [domain] of Object.entries(SITE_CONFIGS)) {
                if (src.includes(domain)) { match = true; break; }
            }
            if (!match) return;
            el.setAttribute(CONFIG.attr, '1');
            registerPill(el, src, getSiteLabel(src), '#00b894', false);
        });
    }

    function scanVideoElements() {
        document.querySelectorAll('video').forEach(video => {
            if (video.hasAttribute(CONFIG.attr)) return;
            // Skip tiny/hidden videos (ads, trackers)
            const r = video.getBoundingClientRect();
            if (r.width < 80 && r.height < 60 && r.width > 0) return;
            // Skip native YouTube player (has its own controls)
            if (isNativePlayer(video)) return;

            const url = extractPlatformUrl(video);
            if (!url) { video.setAttribute(CONFIG.attr, 'skip'); return; }

            video.setAttribute(CONFIG.attr, '1');
            const anchor = findVideoContainer(video) || video;
            if (anchor.hasAttribute(CONFIG.attr) && anchor !== video) return;
            if (anchor !== video) anchor.setAttribute(CONFIG.attr, '1');

            const label = getSiteLabel(url);
            const isAudio = SITE_CONFIGS[location.hostname.replace('www.','')]?.audioOnly;
            registerPill(anchor, url, label, '#00b894', isAudio);
        });
    }

    function getSiteLabel(url) {
        try {
            const h = new URL(url, location.href).hostname.replace('www.','');
            for (const [domain, cfg] of Object.entries(SITE_CONFIGS)) {
                if (h === domain || h.endsWith('.' + domain)) return cfg.name;
            }
        } catch {}
        return '';
    }

    // =========================================================================
    // PLATFORM-SPECIFIC URL EXTRACTION
    // =========================================================================
    function extractPlatformUrl(video) {
        const host = location.hostname.replace('www.', '');

        // Facebook - multi-strategy extraction
        if (host === 'facebook.com' || host === 'fb.com' || host.endsWith('.facebook.com')) {
            return extractFacebookUrl(video);
        }

        // Direct src (non-blob)
        const src = video.src || video.currentSrc || '';
        if (src && !src.startsWith('blob:') && src.startsWith('http')) {
            console.log('MediaDL: Direct video src:', src.substring(0, 80));
            return src;
        }

        // Source elements
        const sourceEl = video.querySelector('source[src]');
        if (sourceEl && sourceEl.src && !sourceEl.src.startsWith('blob:')) {
            return sourceEl.src;
        }

        // Known site - use page URL
        for (const [domain] of Object.entries(SITE_CONFIGS)) {
            if (host === domain || host.endsWith('.' + domain)) {
                return location.href;
            }
        }

        // Unknown site with blob: - try page URL
        if (src.startsWith('blob:')) return location.href;

        return null;
    }

    // =========================================================================
    // FACEBOOK EXTRACTION - 6-LAYER STRATEGY
    // 1. XHR intercepted URLs (highest quality, from API responses)
    // 2. Performance Resource Timing API (CDN URLs browser fetched)
    // 3. React fiber tree (component props)
    // 4. GraphQL-style data extraction (embedded JSON)
    // 5. DOM walk for permalink
    // 6. Page URL fallback
    // =========================================================================
    function extractFacebookUrl(video) {
        console.log('MediaDL [FB]: Starting 6-layer extraction');

        // Layer 1: XHR Intercepted URLs
        const intercepted = getInterceptedUrls();
        if (intercepted) {
            console.log('MediaDL [FB]: Layer 1 HIT - XHR intercepted URL');
            return intercepted;
        }

        // Layer 2: Performance API
        const cdnUrl = findFbCdnUrl(video);
        if (cdnUrl) {
            console.log('MediaDL [FB]: Layer 2 HIT - Performance API CDN URL');
            return cdnUrl;
        }

        // Layer 3: React fiber
        const reactUrl = extractFacebookReactUrl(video);
        if (reactUrl) {
            console.log('MediaDL [FB]: Layer 3 HIT - React fiber URL');
            return reactUrl;
        }

        // Layer 4: Embedded JSON data
        const jsonUrl = extractFbJsonUrl();
        if (jsonUrl) {
            console.log('MediaDL [FB]: Layer 4 HIT - Embedded JSON URL');
            return jsonUrl;
        }

        // Layer 5: DOM walk for permalink
        const permalink = findFbPermalink(video);
        if (permalink) {
            console.log('MediaDL [FB]: Layer 5 HIT - Permalink:', permalink);
            return permalink;
        }

        // Layer 6: Page URL (works on direct video pages)
        if (/\/videos\/|\/watch\/?\?v=|\/reel\/|\/stories\//.test(location.href)) {
            console.log('MediaDL [FB]: Layer 6 - Direct page URL');
            return location.href;
        }

        console.log('MediaDL [FB]: All layers failed, using page URL');
        return location.href;
    }

    // Layer 1: Get best URL from XHR intercept
    function getInterceptedUrls() {
        try {
            const urls = window.__mdl_captured_urls;
            if (!urls || urls.length === 0) return null;
            // Prefer HD urls
            const hd = urls.find(u => /hd|quality_hd|browser_native_hd/.test(u) || /\.mp4/.test(u));
            if (hd && isFbVideoUrl(hd)) return hd;
            // Any video URL
            const any = urls.find(u => isFbVideoUrl(u));
            if (any) return any;
        } catch {}
        return null;
    }

    // Layer 2: Performance Resource Timing API
    function findFbCdnUrl(video) {
        try {
            const entries = performance.getEntriesByType('resource');
            const candidates = entries
                .filter(e => e.name && e.name.includes('fbcdn.net') && isFbVideoUrl(e.name))
                .map(e => ({ url: e.name, size: e.transferSize || 0, time: e.startTime }));

            console.log(`MediaDL [FB]: Found ${candidates.length} fbcdn video URL(s) in performance entries`);
            if (candidates.length === 0) return null;

            // Sort by size desc (largest = main video), then by time desc (newest)
            candidates.sort((a, b) => (b.size - a.size) || (b.time - a.time));
            const best = candidates[0].url;
            console.log('MediaDL [FB]: Best CDN URL:', best.substring(0, 100));
            return best;
        } catch(e) {
            console.log('MediaDL [FB]: Performance API error:', e);
        }
        return null;
    }

    // Layer 3: React fiber tree
    function extractFacebookReactUrl(videoEl) {
        const fiberKeys = ['__reactFiber', '__reactInternalInstance', '__reactProps', '__reactContainer'];
        let fiber = null;

        // Check video element and parents
        let el = videoEl;
        for (let d = 0; d < 8 && el; d++) {
            for (const prefix of fiberKeys) {
                const key = Object.keys(el).find(k => k.startsWith(prefix));
                if (key) { fiber = el[key]; break; }
            }
            if (fiber) break;
            el = el.parentElement;
        }
        if (!fiber) return null;

        return searchFiberTree(fiber);
    }

    function searchFiberTree(startFiber) {
        const HD_PROPS = ['browser_native_hd_url', 'playable_url_quality_hd', 'hd_src'];
        const SD_PROPS = ['browser_native_sd_url', 'playable_url', 'sd_src', 'progressive_url'];

        let current = startFiber;
        for (let hops = 0; hops < 60 && current; hops++) {
            for (const propsKey of ['memoizedProps', 'pendingProps']) {
                const props = current[propsKey];
                if (props) {
                    const url = findVideoUrlInProps(props, new Set(), 0);
                    if (url) return url;
                }
            }
            if (current.stateNode && current.stateNode.props) {
                const url = findVideoUrlInProps(current.stateNode.props, new Set(), 0);
                if (url) return url;
            }
            current = current.return;
        }
        return null;
    }

    function findVideoUrlInProps(obj, visited, depth) {
        if (!obj || depth > 12 || typeof obj !== 'object') return null;
        if (visited.has(obj)) return null;
        visited.add(obj);

        const HD_PROPS = ['browser_native_hd_url', 'playable_url_quality_hd', 'hd_src'];
        const SD_PROPS = ['browser_native_sd_url', 'playable_url', 'sd_src', 'progressive_url'];
        const SKIP_KEYS = new Set(['_owner', '_store', 'ref', 'key', 'children', 'props', 'type',
            'stateNode', '__reactFiber', '__reactInternalInstance']);

        // Check HD props first
        for (const p of HD_PROPS) {
            if (obj[p] && typeof obj[p] === 'string' && isFbVideoUrl(obj[p])) return obj[p];
        }
        for (const p of SD_PROPS) {
            if (obj[p] && typeof obj[p] === 'string' && isFbVideoUrl(obj[p])) return obj[p];
        }

        // Scan all string values for fbcdn video patterns
        for (const key of Object.keys(obj)) {
            if (SKIP_KEYS.has(key)) continue;
            const val = obj[key];
            if (typeof val === 'string' && val.length > 30 && val.length < 3000 && isFbVideoUrl(val)) {
                return val;
            }
            if (typeof val === 'object' && val !== null && !(val instanceof HTMLElement)) {
                const found = findVideoUrlInProps(val, visited, depth + 1);
                if (found) return found;
            }
        }

        // Arrays
        if (Array.isArray(obj)) {
            for (const item of obj) {
                if (typeof item === 'object' && item !== null) {
                    const found = findVideoUrlInProps(item, visited, depth + 1);
                    if (found) return found;
                }
            }
        }

        return null;
    }

    // Layer 4: Embedded JSON (script tags with video data)
    function extractFbJsonUrl() {
        try {
            const scripts = document.querySelectorAll('script[type="application/json"]');
            for (const script of scripts) {
                const text = script.textContent;
                if (!text || text.length < 100) continue;
                const hdMatch = text.match(/"(?:browser_native_hd_url|playable_url_quality_hd|hd_src)":"(https?:[^"]+)"/);
                if (hdMatch) {
                    const url = hdMatch[1].replace(/\\\//g, '/').replace(/\\u0025/g, '%');
                    if (isFbVideoUrl(url)) return url;
                }
                const sdMatch = text.match(/"(?:playable_url|sd_src)":"(https?:[^"]+)"/);
                if (sdMatch) {
                    const url = sdMatch[1].replace(/\\\//g, '/').replace(/\\u0025/g, '%');
                    if (isFbVideoUrl(url)) return url;
                }
            }
        } catch {}
        return null;
    }

    // Layer 5: DOM walk for permalink
    function findFbPermalink(video) {
        let el = video;
        for (let d = 0; d < 25 && el; d++) {
            const links = el.querySelectorAll ? el.querySelectorAll('a[href]') : [];
            for (const a of links) {
                const h = a.href;
                if (/\/videos\/\d+|\/watch\/?\?v=\d+|\/reel\/\d+/.test(h)) return h;
            }
            if (el.getAttribute?.('role') === 'article' || el.getAttribute?.('data-pagelet')?.includes('Feed')) {
                break;
            }
            el = el.parentElement;
        }
        return null;
    }

    // =========================================================================
    // FACEBOOK HELPERS
    // =========================================================================
    function isFbVideoUrl(url) {
        if (!url) return false;
        if (!url.includes('fbcdn.net')) return false;
        if (/\.(jpg|jpeg|png|webp|gif|svg)(\?|$)/i.test(url)) return false;
        if (url.includes('.mp4')) return true;
        if (/\/v\/t2\//.test(url)) return true;
        if (url.includes('video') && url.includes('/o1/')) return true;
        if (/efg=.*encod/.test(url)) return true;
        return false;
    }

    // =========================================================================
    // GENERIC HELPERS
    // =========================================================================
    function findVideoContainer(video) {
        let el = video.parentElement;
        let depth = 0;
        while (el && depth < 8) {
            if (el.tagName === 'A' && el.href) return el;
            const r = el.getBoundingClientRect();
            const vr = video.getBoundingClientRect();
            if (r.width > vr.width * 1.5 && r.height > vr.height * 1.5) break;
            if (el.classList.contains('video-container') || el.classList.contains('player') ||
                el.getAttribute('data-testid')?.includes('video')) return el;
            el = el.parentElement;
            depth++;
        }
        return null;
    }

    // =========================================================================
    // INITIALIZATION
    // =========================================================================
    async function fullInit() {
        if (!document.body) return;

        // Check server on first load
        await checkServer();

        // Load saved token
        if (!serverToken) {
            // Try to read from a well-known location
            serverToken = GM_getValue('mdl_server_token', '');
        }

        scanForEmbeds();
    }

    const debouncedScan = debounce(scanForEmbeds, CONFIG.scanIntervalMs);

    // =========================================================================
    // STYLE INJECTION + BOOT
    // =========================================================================
    function injectStyles() {
        if (document.head || document.documentElement) { GM_addStyle(STYLES); antiFouc.remove(); }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => { injectStyles(); fullInit(); });
    } else {
        injectStyles(); fullInit();
    }

    // SPA navigation
    window.addEventListener('yt-navigate-finish', debouncedScan);
    window.addEventListener('popstate', debouncedScan);

    // MutationObserver
    let lastUrl = location.href;
    function startObserver() {
        if (!document.body) { requestAnimationFrame(startObserver); return; }
        new MutationObserver((muts) => {
            if (location.href !== lastUrl) {
                lastUrl = location.href;
                // Re-check server on navigation (SPA)
                checkServer();
            }
            let hasNew = false;
            for (const m of muts) { if (m.addedNodes.length) { hasNew = true; break; } }
            if (hasNew) debouncedScan();
        }).observe(document.body, { childList: true, subtree: true });
    }
    startObserver();

    // Position loop + periodic rescan
    setInterval(positionAllPills, CONFIG.positionIntervalMs);
    setInterval(() => { if (document.body) { pruneOrphanedPills(); scanForEmbeds(); } }, CONFIG.scanIntervalMs);

    window.addEventListener('scroll', positionAllPills, { passive: true });
    window.addEventListener('resize', positionAllPills, { passive: true });
    window.addEventListener('load', () => setTimeout(fullInit, 1000));

    // Periodic server re-check (every 30s)
    setInterval(checkServer, 30000);

    console.log(`MediaDL v${CONFIG.version}: Universal Media Downloader loaded (server: ${serverAlive ? 'connected' : 'offline'})`);
})();