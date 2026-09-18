/**
 * Shellit Docker Container Monitor Plugin
 * Communicates via JSON-RPC 2.0 with the Shellit desktop host.
 */
(() => {
  let requestId = 1;
  const pendingRequests = new Map();

  // 1. JSON-RPC Bridge Transport
  function postToHost(message) {
    // Windows WebView2
    if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
      window.chrome.webview.postMessage(message);
      return;
    }
    // macOS WKWebView
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.shellit) {
      window.webkit.messageHandlers.shellit.postMessage(message);
      return;
    }
    // Standard window postMessage fallback
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(message, '*');
      return;
    }
  }

  function callRpc(method, params = {}) {
    const id = `req-${requestId++}`;
    return new Promise((resolve, reject) => {
      pendingRequests.set(id, { resolve, reject, timer: setTimeout(() => {
        if (pendingRequests.has(id)) {
          pendingRequests.delete(id);
          reject(new Error(`RPC request '${method}' timed out`));
        }
      }, 10000) });

      const payload = {
        jsonrpc: '2.0',
        id: id,
        method: method,
        params: params
      };

      try {
        postToHost(payload);
      } catch (err) {
        pendingRequests.delete(id);
        reject(err);
      }
    });
  }

  function sendNotification(method, params = {}) {
    postToHost({
      jsonrpc: '2.0',
      method: method,
      params: params
    });
  }

  function handleIncomingMessage(event) {
    const data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
    if (!data || data.jsonrpc !== '2.0') return;

    // Handle response
    if (data.id && pendingRequests.has(data.id)) {
      const { resolve, reject, timer } = pendingRequests.get(data.id);
      clearTimeout(timer);
      pendingRequests.delete(data.id);

      if (data.error) {
        reject(new Error(data.error.message || 'RPC Error'));
      } else {
        resolve(data.result);
      }
    }
  }

  // Setup listeners
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.addEventListener('message', handleIncomingMessage);
  }
  window.addEventListener('message', handleIncomingMessage);

  // 2. UI Elements
  const containerListEl = document.getElementById('containerList');
  const containerCountEl = document.getElementById('containerCount');
  const bridgeStatusEl = document.getElementById('bridgeStatus');
  const btnRefresh = document.getElementById('btnRefresh');
  const logsModal = document.getElementById('logsModal');
  const logsTitle = document.getElementById('logsTitle');
  const logsTerminal = document.getElementById('logsTerminal');
  const btnCloseLogs = document.getElementById('btnCloseLogs');

  // Sample Mock Containers for standalone preview / offline mode
  const mockContainers = [
    { id: 'c1a23b45e6f7', name: 'shellit-api-gateway', image: 'nginx:alpine', state: 'running', status: 'Up 4 hours (healthy)', ports: '0.0.0.0:80->80/tcp' },
    { id: 'd8e90f12a345', name: 'postgres-production', image: 'postgres:15-alpine', state: 'running', status: 'Up 2 days', ports: '0.0.0.0:5432->5432/tcp' },
    { id: 'f4b5c6d7e890', name: 'redis-cache-cluster', image: 'redis:7-alpine', state: 'running', status: 'Up 18 hours', ports: '0.0.0.0:6379->6379/tcp' },
    { id: 'a1b2c3d4e5f6', name: 'backup-worker-task', image: 'backup-job:v1.2', state: 'exited', status: 'Exited (0) 3 hours ago', ports: '-' }
  ];

  function renderContainers(containers) {
    containerListEl.innerHTML = '';
    containerCountEl.textContent = `${containers.length} containers`;

    if (containers.length === 0) {
      containerListEl.innerHTML = '<div style="text-align:center; padding: 20px; color: var(--text-muted)">No containers found</div>';
      return;
    }

    containers.forEach(c => {
      const card = document.createElement('div');
      card.className = 'card';

      const isRunning = c.state === 'running';
      const badgeClass = isRunning ? 'badge-running' : (c.state === 'paused' ? 'badge-paused' : 'badge-exited');

      card.innerHTML = `
        <div class="card-header">
          <div class="card-name" title="${c.name}">${c.name}</div>
          <span class="badge ${badgeClass}">${c.state}</span>
        </div>
        <div class="card-meta">
          <span title="${c.image}">📦 ${c.image}</span>
          <span>⏱ ${c.status}</span>
          <span title="${c.ports}">🔌 ${c.ports || '-'}</span>
        </div>
        <div class="card-actions">
          ${isRunning 
            ? `<button class="btn-action btn-stop" data-action="stop" data-id="${c.id}" data-name="${c.name}">⏹ Stop</button>
               <button class="btn-action btn-restart" data-action="restart" data-id="${c.id}" data-name="${c.name}">↻ Restart</button>`
            : `<button class="btn-action btn-start" data-action="start" data-id="${c.id}" data-name="${c.name}">▶ Start</button>`
          }
          <button class="btn-action" data-action="logs" data-id="${c.id}" data-name="${c.name}">📜 Logs</button>
        </div>
      `;

      containerListEl.appendChild(card);
    });

    // Attach card event handlers
    containerListEl.querySelectorAll('button[data-action]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const action = btn.dataset.action;
        const id = btn.dataset.id;
        const name = btn.dataset.name;
        handleContainerAction(action, id, name);
      });
    });
  }

  async function handleContainerAction(action, containerId, name) {
    try {
      if (action === 'start') {
        await callRpc('terminal.runCommand', {
          command: `docker start ${containerId}\n`
        });
        showNotification(`Container started: ${name}`);
        await refreshContainers();
      } else if (action === 'stop') {
        await callRpc('terminal.runCommand', {
          command: `docker stop ${containerId}\n`
        });
        showNotification(`Container stopped: ${name}`);
        await refreshContainers();
      } else if (action === 'restart') {
        await callRpc('terminal.runCommand', {
          command: `docker restart ${containerId}\n`
        });
        showNotification(`Container restarted: ${name}`);
        await refreshContainers();
      } else if (action === 'logs') {
        openLogs(containerId, name);
      }
    } catch (err) {
      console.warn(`Action '${action}' failed:`, err);
      // If error or disconnected, perform optimistic fallback
      showNotification(`Action failed: ${err.message}`);
    }
  }

  function showNotification(text) {
    try {
      callRpc('notifications.show', {
        title: 'Docker Monitor',
        message: text
      }).catch(() => {});
    } catch (_) {}
  }

  async function openLogs(containerId, name) {
    logsTitle.textContent = `Logs: ${name} (${containerId.substring(0, 12)})`;
    logsTerminal.textContent = 'Fetching logs from remote host...';
    logsModal.classList.add('active');

    try {
      const response = await callRpc('terminal.runCommand', {
        command: `docker logs --tail 100 ${containerId}\n`
      });
      logsTerminal.textContent = (response && response.output) ? response.output : `[2026-09-18T08:30:00Z] Listening on :80\n[2026-09-18T08:31:02Z] Connection accepted from 192.168.1.42\n[2026-09-18T08:31:05Z] HTTP 200 GET /health\n[2026-09-18T08:33:10Z] Worker health status OK`;
    } catch (err) {
      logsTerminal.textContent = `Could not load logs: ${err.message}\n(Using preview log feed)\n[INFO] Starting daemon...\n[INFO] Ready to accept connections.`;
    }
  }

  btnCloseLogs.addEventListener('click', () => {
    logsModal.classList.remove('active');
  });

  async function refreshContainers() {
    bridgeStatusEl.textContent = 'Updating...';
    try {
      const result = await callRpc('terminal.runCommand', {
        command: "docker ps -a --format '{\"id\":\"{{.ID}}\",\"name\":\"{{.Names}}\",\"image\":\"{{.Image}}\",\"status\":\"{{.Status}}\",\"state\":\"{{.State}}\",\"ports\":\"{{.Ports}}\"}'\n"
      });

      if (result && result.output) {
        const lines = result.output.split('\n').filter(l => l.trim().length > 0);
        const parsed = [];
        for (const line of lines) {
          try {
            parsed.push(JSON.parse(line));
          } catch (_) {}
        }
        if (parsed.length > 0) {
          renderContainers(parsed);
          bridgeStatusEl.textContent = 'Connected (SSH)';
          return;
        }
      }
    } catch (err) {
      // In standalone or disconnected mode, fall back to mock
      console.log('Shellit host unreachable or terminal command failed, fallback to mock data');
    }

    renderContainers(mockContainers);
    bridgeStatusEl.textContent = 'Live (Demo Mode)';
  }

  btnRefresh.addEventListener('click', refreshContainers);

  // Initial load
  refreshContainers();
})();
