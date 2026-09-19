/**
 * Shellit MCP Server Plugin Frontend (JSON-RPC 2.0 Bridge)
 */
(function () {
  let requestId = 1;
  const pendingRequests = new Map();

  let isRunning = true;
  let currentPort = 4422;

  // DOM Elements
  const statusBadge = document.getElementById('statusBadge');
  const statusText = document.getElementById('statusText');
  const endpointBox = document.getElementById('endpointBox');
  const endpointUrl = document.getElementById('endpointUrl');
  const portInput = document.getElementById('portInput');
  const toggleBtn = document.getElementById('toggleBtn');
  const clientsCount = document.getElementById('clientsCount');
  const copyCursorBtn = document.getElementById('copyCursorBtn');
  const copyClaudeBtn = document.getElementById('copyClaudeBtn');
  const configCode = document.getElementById('configCode');
  const protectProdCheck = document.getElementById('protectProdCheck');
  const notifyCallsCheck = document.getElementById('notifyCallsCheck');
  const clearLogsBtn = document.getElementById('clearLogsBtn');
  const logList = document.getElementById('logList');

  // JSON-RPC 2.0 Call Helper
  function callRpc(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = 'req_' + (requestId++);
      pendingRequests.set(id, { resolve, reject });

      const payload = {
        jsonrpc: '2.0',
        id: id,
        method: method,
        params: params,
      };

      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(JSON.stringify(payload));
      } else {
        // Fallback for direct browser testing
        console.log('[Mock RPC Call]:', payload);
        setTimeout(() => {
          if (method === 'mcp.getStatus') {
            resolve({ running: true, port: currentPort, activeClients: 0 });
          } else if (method === 'mcp.getAuditLogs') {
            resolve({ logs: [] });
          } else {
            resolve({ status: 'ok' });
          }
        }, 100);
      }
    });
  }

  // Receive JSON-RPC responses from Shellit host
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.addEventListener('message', (event) => {
      try {
        let msg = event.data;
        if (typeof msg === 'string') {
          msg = JSON.parse(msg);
        }

        if (msg.id && pendingRequests.has(msg.id)) {
          const { resolve, reject } = pendingRequests.get(msg.id);
          pendingRequests.delete(msg.id);

          if (msg.error) {
            reject(msg.error);
          } else {
            resolve(msg.result);
          }
        }
      } catch (err) {
        console.error('Error handling message from host:', err);
      }
    });
  }

  function updateUiState() {
    const sseUrl = `http://127.0.0.1:${currentPort}/sse`;
    endpointUrl.textContent = sseUrl;

    if (isRunning) {
      statusBadge.className = 'status-badge';
      statusText.textContent = 'ACTIVE';
      toggleBtn.className = 'btn btn-danger';
      toggleBtn.textContent = 'Stop Server';
      portInput.disabled = true;
    } else {
      statusBadge.className = 'status-badge stopped';
      statusText.textContent = 'STOPPED';
      toggleBtn.className = 'btn btn-primary';
      toggleBtn.textContent = 'Start Server';
      portInput.disabled = false;
    }

    configCode.textContent = JSON.stringify(
      {
        mcpServers: {
          shellit: {
            type: 'sse',
            url: sseUrl,
          },
        },
      },
      null,
      2
    );
  }

  async function refreshStatus() {
    try {
      const res = await callRpc('mcp.getStatus');
      if (res) {
        isRunning = res.running !== false;
        if (res.port) {
          currentPort = res.port;
          portInput.value = currentPort;
        }
        clientsCount.textContent = `${res.activeClients || 0} clients`;
        updateUiState();
      }
    } catch (_) {}
  }

  async function refreshLogs() {
    try {
      const res = await callRpc('mcp.getAuditLogs');
      if (res && Array.isArray(res.logs)) {
        renderLogs(res.logs);
      }
    } catch (_) {}
  }

  function renderLogs(logs) {
    if (!logs || logs.length === 0) {
      logList.innerHTML = '<div class="empty-logs">Waiting for incoming tool calls from Cursor, Windsurf, or Claude...</div>';
      return;
    }

    logList.innerHTML = '';
    logs.slice(0, 30).forEach((entry) => {
      const item = document.createElement('div');
      item.className = 'log-item' + (entry.isSuccess ? '' : ' error');

      const time = entry.timestamp
        ? new Date(entry.timestamp).toLocaleTimeString()
        : '';
      const client = entry.clientName || 'AI Client';
      const tool = entry.toolName || 'tool';
      const snippet = entry.resultSnippet || entry.errorMessage || JSON.stringify(entry.arguments);

      item.innerHTML = `
        <div class="log-header">
          <span class="log-tool ${entry.isSuccess ? '' : 'error'}">${escapeHtml(tool)}</span>
          <span>${escapeHtml(client)} · ${escapeHtml(time)}</span>
        </div>
        <div class="log-snippet" title="${escapeHtml(snippet)}">${escapeHtml(snippet)}</div>
      `;

      logList.appendChild(item);
    });
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function copyToClipboard(text, notice) {
    navigator.clipboard.writeText(text).then(() => {
      callRpc('notifications.show', {
        title: 'Shellit MCP Server',
        message: notice || 'Copied to clipboard',
      });
    }).catch(() => {
      // Fallback
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      callRpc('notifications.show', {
        title: 'Shellit MCP Server',
        message: notice || 'Copied to clipboard',
      });
    });
  }

  // Event Listeners
  endpointBox.addEventListener('click', () => {
    copyToClipboard(`http://127.0.0.1:${currentPort}/sse`, 'Copied MCP SSE URL to clipboard');
  });

  copyCursorBtn.addEventListener('click', () => {
    copyToClipboard(configCode.textContent, 'Copied Cursor MCP configuration');
  });

  copyClaudeBtn.addEventListener('click', () => {
    const claudeJson = JSON.stringify(
      {
        mcpServers: {
          shellit: {
            url: `http://127.0.0.1:${currentPort}/sse`,
          },
        },
      },
      null,
      2
    );
    copyToClipboard(claudeJson, 'Copied Claude Desktop configuration');
  });

  toggleBtn.addEventListener('click', async () => {
    const desiredRunning = !isRunning;
    const port = parseInt(portInput.value, 10) || 4422;
    try {
      const res = await callRpc('mcp.toggleServer', {
        running: desiredRunning,
        port: port,
      });
      if (res) {
        isRunning = res.running;
        currentPort = res.port || port;
        updateUiState();
      }
    } catch (e) {
      console.error('Failed to toggle MCP server:', e);
    }
  });

  clearLogsBtn.addEventListener('click', () => {
    callRpc('mcp.clearLogs');
    renderLogs([]);
  });

  // Initial Run
  updateUiState();
  refreshStatus();
  refreshLogs();

  // Periodic Refresh
  setInterval(() => {
    refreshStatus();
    refreshLogs();
  }, 2500);
})();
