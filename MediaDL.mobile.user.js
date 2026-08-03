// ==UserScript==
// @name         MediaDL Mobile - Direct Media Downloader
// @namespace    https://github.com/SysAdminDoc/MediaDL
// @version      5.0.0
// @description  Lightweight direct-media downloader for Kiwi Browser and Orion.
// @author       SysAdminDoc
// @license      MIT
// @match        *://*/*
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2300b894'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z'/%3E%3C/svg%3E
// @grant        GM_download
// @grant        GM_addStyle
// @run-at       document-start
// @noframes
// @compatible   Kiwi Browser
// @compatible   Orion
// ==/UserScript==

(function () {
    'use strict';

    const STYLE = `
        .mdl-mobile-pill {
            position: fixed; z-index: 2147483647; display: flex; gap: 4px;
            padding: 4px; border-radius: 8px; background: rgba(0,0,0,.88);
            box-shadow: 0 2px 12px rgba(0,0,0,.45); font: 11px -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
        }
        .mdl-mobile-pill button {
            border: 0; border-radius: 5px; padding: 6px 8px; color: #fff;
            background: #00a085; cursor: pointer; font: inherit;
        }
        .mdl-mobile-pill button.audio { background: #5b4cdb; }
        .mdl-mobile-pill button:hover { filter: brightness(1.15); }
        #mdl-mobile-toast {
            position: fixed; z-index: 2147483647; left: 50%; bottom: 18px; transform: translateX(-50%);
            max-width: min(92vw, 420px); padding: 9px 14px; border-radius: 7px;
            background: rgba(17,24,39,.94); color: #fff; font: 12px/1.35 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;
            opacity: 0; pointer-events: none; transition: opacity .2s;
        }
        #mdl-mobile-toast.show { opacity: 1; }
    `;

    function addStyle() {
        if (typeof GM_addStyle === 'function') GM_addStyle(STYLE);
        else {
            const style = document.createElement('style');
            style.textContent = STYLE;
            (document.head || document.documentElement).appendChild(style);
        }
    }

    let toastTimer = null;
    function showToast(message, error = false) {
        let toast = document.getElementById('mdl-mobile-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'mdl-mobile-toast';
            document.documentElement.appendChild(toast);
        }
        toast.textContent = message;
        toast.style.border = error ? '1px solid #ef4444' : '1px solid #00b894';
        toast.classList.add('show');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => toast.classList.remove('show'), 3200);
    }

    function safeName(value) {
        return (value || 'media').replace(/[<>:"/\\|?*]/g, '_').replace(/\s+/g, ' ').trim().slice(0, 100) || 'media';
    }

    function mediaUrl(media) {
        if (media.currentSrc) return media.currentSrc;
        if (media.src) return media.src;
        const source = media.querySelector('source[src]');
        return source ? source.src : '';
    }

    function extensionFor(url, media) {
        try {
            const extension = new URL(url, location.href).pathname.match(/\.([a-z0-9]{2,5})$/i)?.[1]?.toLowerCase();
            if (['mp4', 'webm', 'm4v', 'mp3', 'm4a', 'ogg', 'opus', 'wav'].includes(extension)) return extension;
        } catch {}
        return media.tagName.toLowerCase() === 'audio' ? 'mp3' : 'mp4';
    }

    function downloadDirect(url, media) {
        if (!/^https?:\/\//i.test(url)) {
            showToast('This player uses a page-managed stream; use the desktop build for extraction.', true);
            return;
        }
        if (/\.m3u8(?:$|\?)/i.test(url)) {
            showToast('HLS playlists need the desktop server; this mobile build downloads direct files only.', true);
            return;
        }
        const title = safeName(document.title || 'media');
        const extension = extensionFor(url, media);
        const name = `${title}.${extension}`;
        const onload = () => showToast(`Saved ${name}`);
        const onerror = () => showToast('Direct download failed on this browser', true);
        if (typeof GM_download === 'function') {
            try {
                GM_download({ url, name, saveAs: false, onload, onerror });
                showToast(`Downloading ${name}`);
                return;
            } catch {}
        }
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = name;
        anchor.rel = 'noopener';
        anchor.target = '_blank';
        anchor.style.display = 'none';
        document.documentElement.appendChild(anchor);
        anchor.click();
        setTimeout(() => anchor.remove(), 1000);
        showToast(`Opening ${name}`);
    }

    const entries = new Map();
    function position(entry) {
        const rect = entry.media.getBoundingClientRect();
        const visible = rect.width > 20 && rect.height > 20 && rect.bottom > 0 && rect.top < innerHeight;
        entry.pill.style.display = visible ? 'flex' : 'none';
        if (!visible) return;
        entry.pill.style.left = `${Math.max(6, Math.min(innerWidth - entry.pill.offsetWidth - 6, rect.right - entry.pill.offsetWidth))}px`;
        entry.pill.style.top = `${Math.max(6, Math.min(innerHeight - entry.pill.offsetHeight - 6, rect.top + 6))}px`;
    }

    function addMedia(media) {
        if (entries.has(media)) return entries.get(media);
        const pill = document.createElement('div');
        pill.className = 'mdl-mobile-pill';
        const button = document.createElement('button');
        const isAudio = media.tagName.toLowerCase() === 'audio';
        button.className = isAudio ? 'audio' : '';
        button.textContent = isAudio ? '♪ Audio' : '↓ Video';
        button.title = 'Download the direct media file';
        button.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            downloadDirect(mediaUrl(media), media);
        });
        pill.appendChild(button);
        document.documentElement.appendChild(pill);
        const entry = { media, pill };
        entries.set(media, entry);
        position(entry);
        return entry;
    }

    function scan() {
        document.querySelectorAll('video, audio').forEach(addMedia);
        for (const [media, entry] of entries) {
            if (!document.documentElement.contains(media)) {
                entry.pill.remove();
                entries.delete(media);
            }
        }
    }

    function positionAll() {
        for (const entry of entries.values()) position(entry);
    }

    function boot() {
        addStyle();
        scan();
        new MutationObserver(scan).observe(document.documentElement, { childList: true, subtree: true });
        setInterval(scan, 1800);
        addEventListener('scroll', positionAll, { passive: true });
        addEventListener('resize', positionAll, { passive: true });
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot, { once: true });
    else boot();
})();
