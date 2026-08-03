const api = globalThis.browser || globalThis.chrome;
const endpoint = 'http://127.0.0.1:9751';
const queue = document.getElementById('queue');
const connection = document.getElementById('connection');
let token = '';

async function loadToken() {
    try {
        const stored = await api.storage.local.get('mdl_server_token');
        token = stored?.mdl_server_token || '';
    } catch {}
}

async function connect() {
    const response = await fetch(`${endpoint}/health`, { headers: { 'X-MDL-Client': 'MediaDL' } });
    const health = await response.json();
    if (health?.token && health.token !== token) {
        token = health.token;
        await api.storage.local.set({ mdl_server_token: token });
    }
    if (health?.status !== 'ok') throw new Error('MediaDL server is not ready');
}

async function request(path, init = {}) {
    const headers = { ...(init.headers || {}), 'X-Auth-Token': token };
    const response = await fetch(`${endpoint}${path}`, { ...init, headers });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(body.error || `HTTP ${response.status}`);
    return body;
}

function actionButton(label, action, id) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = label;
    button.addEventListener('click', async () => {
        button.disabled = true;
        try {
            await request(action === 'cancel' ? `/cancel/${encodeURIComponent(id)}` : `/${action}/${encodeURIComponent(id)}`, { method: action === 'cancel' ? 'DELETE' : 'POST' });
            await refresh();
        } catch (error) {
            connection.textContent = `Action failed: ${error.message}`;
            button.disabled = false;
        }
    });
    return button;
}

function render(items) {
    queue.replaceChildren();
    if (!items.length) {
        const empty = document.createElement('li');
        empty.className = 'empty';
        empty.textContent = 'No queued downloads';
        queue.appendChild(empty);
        return;
    }
    for (const item of items) {
        const row = document.createElement('li');
        row.className = 'item';
        const title = document.createElement('div');
        title.className = 'title';
        title.textContent = item.title || 'Untitled download';
        const meta = document.createElement('div');
        meta.className = 'meta';
        meta.textContent = `${item.status || 'unknown'} · ${Math.round(Number(item.progress) || 0)}%${item.site ? ` · ${item.site}` : ''}`;
        const bar = document.createElement('div');
        bar.className = 'bar';
        const fill = document.createElement('div');
        fill.className = 'fill';
        fill.style.width = `${Math.max(0, Math.min(100, Number(item.progress) || 0))}%`;
        bar.appendChild(fill);
        const actions = document.createElement('div');
        actions.className = 'actions';
        if (item.status === 'paused') actions.appendChild(actionButton('Resume', 'resume', item.id));
        else if (!/complete|failed|cancelled/.test(item.status || '')) actions.appendChild(actionButton('Pause', 'pause', item.id));
        if (!/complete|failed|cancelled/.test(item.status || '')) actions.appendChild(actionButton('Cancel', 'cancel', item.id));
        row.append(title, meta, bar, actions);
        queue.appendChild(row);
    }
}

async function refresh() {
    try {
        await connect();
        const body = await request('/queue');
        render(Array.isArray(body.downloads) ? body.downloads : []);
        connection.textContent = `Connected · ${body.count || 0} item(s) · refreshed ${new Date().toLocaleTimeString()}`;
    } catch (error) {
        connection.textContent = `Server unavailable: ${error.message}`;
        render([]);
    }
}

document.getElementById('refresh').addEventListener('click', refresh);
loadToken().then(refresh);
setInterval(refresh, 3000);
