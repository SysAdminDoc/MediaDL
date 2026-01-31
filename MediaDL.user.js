// ==UserScript==
// @name         MediaDL - Universal Media Downloader
// @namespace    https://github.com/SysAdminDoc/MediaDL
// @version      1.0.0
// @description  Download videos and extract audio from 1800+ sites - powered by yt-dlp
// @author       SysAdminDoc
// @license      MIT
// @match        *://*.youtube.com/*
// @match        *://*.youtu.be/*
// @match        *://*.vimeo.com/*
// @match        *://*.dailymotion.com/*
// @match        *://*.twitch.tv/*
// @match        *://*.twitter.com/*
// @match        *://*.x.com/*
// @match        *://*.instagram.com/*
// @match        *://*.tiktok.com/*
// @match        *://*.facebook.com/*
// @match        *://*.soundcloud.com/*
// @match        *://*.bandcamp.com/*
// @match        *://*.reddit.com/*
// @match        *://*.tumblr.com/*
// @match        *://*.bilibili.com/*
// @match        *://*.nicovideo.jp/*
// @match        *://*.pornhub.com/*
// @match        *://*.xvideos.com/*
// @match        *://*.crunchyroll.com/*
// @match        *://*.spotify.com/*
// @match        *://*.mixcloud.com/*
// @match        *://*.rumble.com/*
// @match        *://*.odysee.com/*
// @match        *://*.bitchute.com/*
// @match        *://*.streamable.com/*
// @match        *://*.gfycat.com/*
// @match        *://*.imgur.com/*
// @match        *://*.giphy.com/*
// @match        *://*.coub.com/*
// @match        *://*.vlive.tv/*
// @match        *://*.veoh.com/*
// @match        *://*.metacafe.com/*
// @match        *://*.ted.com/*
// @match        *://*.cnn.com/*
// @match        *://*.bbc.com/*
// @match        *://*.nbcnews.com/*
// @match        *://*.cbsnews.com/*
// @match        *://*.abcnews.go.com/*
// @match        *://*.foxnews.com/*
// @match        *://*.nytimes.com/*
// @match        *://*.washingtonpost.com/*
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%2300b894'%3E%3Cpath d='M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z'/%3E%3C/svg%3E
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @run-at       document-idle
// @noframes
// ==/UserScript==

(function() {
    'use strict';

    // =========================================================================
    // CONFIGURATION
    // =========================================================================

    const CONFIG = {
        version: '1.0.0',
        debounceMs: 300,
        protocol: 'ytdl'
    };

    // =========================================================================
    // SITE CONFIGURATIONS
    // =========================================================================

    const SITE_CONFIGS = {
        'youtube.com': {
            name: 'YouTube',
            urlPattern: /youtube\.com\/(watch|shorts|live)/,
            getVideoUrl: () => {
                const urlParams = new URLSearchParams(window.location.search);
                const videoId = urlParams.get('v');
                if (videoId) return `https://www.youtube.com/watch?v=${videoId}`;
                if (location.pathname.includes('/shorts/')) return location.href;
                if (location.pathname.includes('/live/')) return location.href;
                return null;
            },
            getVideoTitle: () => {
                return document.querySelector('h1.ytd-video-primary-info-renderer, h1.ytd-watch-metadata')?.textContent?.trim() 
                    || document.title.replace(' - YouTube', '');
            }
        },
        'youtu.be': { inherit: 'youtube.com' },
        'vimeo.com': {
            name: 'Vimeo',
            urlPattern: /vimeo\.com\/\d+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || document.title
        },
        'twitter.com': {
            name: 'Twitter',
            urlPattern: /twitter\.com\/\w+\/status\/\d+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('article h2')?.textContent?.trim() || 'twitter_video'
        },
        'x.com': { inherit: 'twitter.com', name: 'X' },
        'tiktok.com': {
            name: 'TikTok',
            urlPattern: /tiktok\.com\/@[\w.]+\/video\/\d+|tiktok\.com\/t\/\w+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'tiktok_video'
        },
        'instagram.com': {
            name: 'Instagram',
            urlPattern: /instagram\.com\/(p|reel|tv)\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => 'instagram_video'
        },
        'twitch.tv': {
            name: 'Twitch',
            urlPattern: /twitch\.tv\/videos\/\d+|twitch\.tv\/\w+\/clip\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1, h2[data-a-target="stream-title"]')?.textContent?.trim() || 'twitch_video'
        },
        'reddit.com': {
            name: 'Reddit',
            urlPattern: /reddit\.com\/r\/\w+\/comments\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'reddit_video'
        },
        'dailymotion.com': {
            name: 'Dailymotion',
            urlPattern: /dailymotion\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'dailymotion_video'
        },
        'soundcloud.com': {
            name: 'SoundCloud',
            urlPattern: /soundcloud\.com\/[\w-]+\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'soundcloud_audio',
            audioOnly: true
        },
        'bandcamp.com': {
            name: 'Bandcamp',
            urlPattern: /bandcamp\.com\/(track|album)\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h2.trackTitle, .trackTitle')?.textContent?.trim() || 'bandcamp_audio',
            audioOnly: true
        },
        'rumble.com': {
            name: 'Rumble',
            urlPattern: /rumble\.com\/v[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'rumble_video'
        },
        'odysee.com': {
            name: 'Odysee',
            urlPattern: /odysee\.com\/@[\w-]+:\w\/[\w-]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'odysee_video'
        },
        'bilibili.com': {
            name: 'Bilibili',
            urlPattern: /bilibili\.com\/video\//,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('h1')?.textContent?.trim() || 'bilibili_video'
        },
        'facebook.com': {
            name: 'Facebook',
            urlPattern: /facebook\.com\/.*\/videos\/|facebook\.com\/watch/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => 'facebook_video'
        },
        'streamable.com': {
            name: 'Streamable',
            urlPattern: /streamable\.com\/\w+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('title')?.textContent?.replace(' - Streamable', '') || 'streamable_video'
        },
        'imgur.com': {
            name: 'Imgur',
            urlPattern: /imgur\.com\/(a\/|gallery\/)?[\w]+/,
            getVideoUrl: () => location.href,
            getVideoTitle: () => document.querySelector('.post-title, h1')?.textContent?.trim() || 'imgur'
        }
    };

    // =========================================================================
    // STYLES
    // =========================================================================

    const STYLES = `
        /* ===== SIDE DRAWER ===== */
        #mediadl-drawer {
            position: fixed;
            right: 0;
            top: 50%;
            transform: translateY(-50%);
            z-index: 2147483647;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            align-items: center;
        }

        #mediadl-drawer .drawer-content {
            display: flex;
            align-items: center;
            background: #1a1a1a;
            border-radius: 8px 0 0 8px;
            overflow: hidden;
            box-shadow: -4px 0 20px rgba(0, 0, 0, 0.4);
            transform: translateX(calc(100% - 8px));
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        #mediadl-drawer:hover .drawer-content,
        #mediadl-drawer.expanded .drawer-content {
            transform: translateX(0);
        }

        #mediadl-drawer .drawer-lip {
            width: 8px;
            height: 80px;
            background: linear-gradient(180deg, #00b894, #00a085);
            cursor: pointer;
            flex-shrink: 0;
            border-radius: 8px 0 0 8px;
        }

        #mediadl-drawer .drawer-lip:hover {
            background: linear-gradient(180deg, #00d4aa, #00b894);
        }

        #mediadl-drawer .drawer-buttons {
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 12px 16px 12px 12px;
        }

        #mediadl-drawer .drawer-btn {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            color: white;
            white-space: nowrap;
            transition: all 0.2s ease;
        }

        #mediadl-drawer .drawer-btn:hover {
            transform: scale(1.03);
            filter: brightness(1.15);
        }

        #mediadl-drawer .drawer-btn.video {
            background: linear-gradient(135deg, #00b894, #00a085);
        }

        #mediadl-drawer .drawer-btn.audio {
            background: linear-gradient(135deg, #6c5ce7, #5b4cdb);
        }

        #mediadl-drawer .drawer-btn svg {
            width: 18px;
            height: 18px;
            fill: currentColor;
        }

        /* ===== TOAST NOTIFICATIONS ===== */
        #mediadl-toast {
            position: fixed;
            bottom: 24px;
            right: 24px;
            background: #1a1a2e;
            color: white;
            padding: 14px 20px;
            border-radius: 10px;
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
            z-index: 2147483647;
            display: flex;
            align-items: center;
            gap: 12px;
            animation: toastSlide 0.3s ease;
            font-size: 14px;
        }

        @keyframes toastSlide {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        #mediadl-toast.success { border-left: 4px solid #00b894; }
        #mediadl-toast.error { border-left: 4px solid #ff7675; }
        #mediadl-toast.info { border-left: 4px solid #0984e3; }
    `;

    // =========================================================================
    // ICONS
    // =========================================================================

    const ICONS = {
        download: '<svg viewBox="0 0 24 24"><path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/></svg>',
        audio: '<svg viewBox="0 0 24 24"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>'
    };

    // =========================================================================
    // UTILITY FUNCTIONS
    // =========================================================================

    function showToast(message, type = 'info', duration = 3000) {
        const existing = document.getElementById('mediadl-toast');
        if (existing) existing.remove();

        const toast = document.createElement('div');
        toast.id = 'mediadl-toast';
        toast.className = type;
        toast.textContent = message;
        document.body.appendChild(toast);

        setTimeout(() => toast.remove(), duration);
    }

    // =========================================================================
    // SITE DETECTION
    // =========================================================================

    function getCurrentSiteConfig() {
        const hostname = location.hostname.replace('www.', '');

        for (const [domain, config] of Object.entries(SITE_CONFIGS)) {
            if (hostname.includes(domain.replace('www.', ''))) {
                if (config.inherit) {
                    const parent = SITE_CONFIGS[config.inherit];
                    return { ...parent, ...config, domain };
                }
                return { ...config, domain };
            }
        }
        return null;
    }

    function isVideoPage(config) {
        if (!config) return false;
        if (!config.urlPattern) return true;
        return config.urlPattern.test(location.href);
    }

    // =========================================================================
    // DOWNLOAD ACTIONS
    // =========================================================================

    function triggerDownload(action, url, title) {
        if (!url) {
            showToast('No video URL found on this page', 'error');
            return;
        }

        const encodedUrl = encodeURIComponent(url);
        let protocol;

        switch (action) {
            case 'video':
                protocol = `${CONFIG.protocol}://${encodedUrl}`;
                showToast('Starting video download...', 'info');
                break;
            case 'audio':
                protocol = `${CONFIG.protocol}://${encodedUrl}?ytyt_audio_only=1`;
                showToast('Starting audio extraction...', 'info');
                break;
            default:
                return;
        }

        window.location.href = protocol;
    }

    // =========================================================================
    // UI CREATION - SIDE DRAWER
    // =========================================================================

    function createDrawer(config) {
        if (document.getElementById('mediadl-drawer')) return;

        const isAudioSite = config?.audioOnly;
        
        const drawer = document.createElement('div');
        drawer.id = 'mediadl-drawer';

        let buttonsHtml = '';
        
        if (!isAudioSite) {
            buttonsHtml += `
                <button class="drawer-btn video" data-action="video">
                    ${ICONS.download}
                    <span>Video</span>
                </button>
            `;
        }
        
        buttonsHtml += `
            <button class="drawer-btn audio" data-action="audio">
                ${ICONS.audio}
                <span>${isAudioSite ? 'Audio' : 'MP3'}</span>
            </button>
        `;

        drawer.innerHTML = `
            <div class="drawer-content">
                <div class="drawer-lip" title="MediaDL"></div>
                <div class="drawer-buttons">
                    ${buttonsHtml}
                </div>
            </div>
        `;

        document.body.appendChild(drawer);

        // Button click handlers
        drawer.querySelectorAll('.drawer-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                const url = config?.getVideoUrl?.() || location.href;
                const title = config?.getVideoTitle?.() || document.title;
                triggerDownload(action, url, title);
            });
        });
    }

    // =========================================================================
    // INITIALIZATION
    // =========================================================================

    function cleanup() {
        const drawer = document.getElementById('mediadl-drawer');
        if (drawer) drawer.remove();
    }

    function init() {
        cleanup();

        const config = getCurrentSiteConfig();
        
        if (!config || !isVideoPage(config)) {
            return;
        }

        createDrawer(config);
    }

    // Debounced init for SPA navigation
    const debouncedInit = (() => {
        let timeout;
        return () => {
            clearTimeout(timeout);
            timeout = setTimeout(init, CONFIG.debounceMs);
        };
    })();

    // =========================================================================
    // EVENT LISTENERS
    // =========================================================================

    // Inject styles
    GM_addStyle(STYLES);

    // Initial load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Handle SPA navigation (YouTube, Twitter, etc.)
    window.addEventListener('yt-navigate-finish', debouncedInit);
    window.addEventListener('popstate', debouncedInit);
    
    // Watch for URL changes
    let lastUrl = location.href;
    new MutationObserver(() => {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            debouncedInit();
        }
    }).observe(document.body, { childList: true, subtree: true });

    // Also run after full page load
    window.addEventListener('load', () => setTimeout(init, 1000));

    console.log('MediaDL: Universal Media Downloader loaded');
})();
