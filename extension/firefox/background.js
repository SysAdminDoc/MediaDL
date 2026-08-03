const api = globalThis.browser || globalThis.chrome;

const sendHttpResponse = async (request) => {
    const method = request.method || 'GET';
    const init = { method, headers: request.headers || {} };
    if (request.data && method !== 'GET' && method !== 'HEAD') init.body = request.data;
    const response = await fetch(request.url, init);
    const responseText = await response.text();
    return {
        status: response.status,
        statusText: response.statusText,
        responseText,
        response: responseText,
        readyState: 4
    };
};

api.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message?.type === 'http') {
        sendHttpResponse(message.request)
            .then(sendResponse)
            .catch((error) => sendResponse({ error: String(error?.message || error) }));
        return true;
    }
    if (message?.type === 'download') {
        const download = message.download || {};
        api.downloads.download({
            url: download.url,
            filename: download.filename || undefined,
            conflictAction: 'uniquify',
            saveAs: false
        }).then((id) => sendResponse({ id }))
            .catch((error) => sendResponse({ error: String(error?.message || error) }));
        return true;
    }
    return false;
});
