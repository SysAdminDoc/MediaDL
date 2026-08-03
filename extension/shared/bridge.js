// MV3 content-script adapter for the userscript's GM_* surface.
(() => {
    const api = globalThis.browser || globalThis.chrome;
    const cache = Object.create(null);

    if (api?.storage?.local) {
        try {
            const loaded = api.storage.local.get(null);
            if (loaded && typeof loaded.then === 'function') {
                loaded.then((values) => Object.assign(cache, values || {})).catch(() => {});
            }
        } catch {}
    }

    const sendMessage = (message) => new Promise((resolve, reject) => {
        if (!api?.runtime?.sendMessage) { reject(new Error('MediaDL extension runtime unavailable')); return; }
        let settled = false;
        const finish = (callback, value) => {
            if (settled) return;
            settled = true;
            callback(value);
        };
        const callback = (response) => finish(resolve, response);
        try {
            const result = api.runtime.sendMessage(message, callback);
            if (result && typeof result.then === 'function') {
                result.then((response) => finish(resolve, response)).catch((error) => finish(reject, error));
            }
        } catch (error) {
            finish(reject, error);
        }
    });

    globalThis.GM_getValue = (key, fallback) => (
        Object.prototype.hasOwnProperty.call(cache, key) ? cache[key] : fallback
    );
    globalThis.GM_setValue = (key, value) => {
        cache[key] = value;
        try { api?.storage?.local?.set({ [key]: value }); } catch {}
    };
    globalThis.GM_addStyle = (css) => {
        const style = document.createElement('style');
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
        return style;
    };
    globalThis.GM_xmlhttpRequest = (options = {}) => {
        const timeoutMs = Number(options.timeout) || 0;
        let finished = false;
        let timeoutId = null;
        const finish = (callback, value) => {
            if (finished) return;
            finished = true;
            if (timeoutId) clearTimeout(timeoutId);
            if (typeof callback === 'function') callback(value);
        };
        if (timeoutMs > 0) {
            timeoutId = setTimeout(() => finish(options.ontimeout), timeoutMs);
        }
        sendMessage({
            type: 'http',
            request: {
                method: options.method || 'GET',
                url: options.url,
                headers: options.headers || {},
                data: options.data || null
            }
        }).then((response) => {
            if (response?.error) finish(options.onerror, response);
            else finish(options.onload, response);
        }).catch((error) => finish(options.onerror, { error: String(error?.message || error) }));
    };
    globalThis.GM_download = (options = {}) => {
        sendMessage({
            type: 'download',
            download: { url: options.url, filename: options.name || '', headers: options.headers || {} }
        }).then(() => options.onload?.()).catch((error) => options.onerror?.({ error: String(error?.message || error) }));
    };
})();
