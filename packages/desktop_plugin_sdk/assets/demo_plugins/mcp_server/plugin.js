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
  const copyAntigravityBtn = document.getElementById('copyAntigravityBtn');
  const copyClaudeBtn = document.getElementById('copyClaudeBtn');
  const configCode = document.getElementById('configCode');
  const protectProdCheck = document.getElementById('protectProdCheck');
  const notifyCallsCheck = document.getElementById('notifyCallsCheck');
  const popoutLogsBtn = document.getElementById('popoutLogsBtn');
  const exportLogsBtn = document.getElementById('exportLogsBtn');
  const copyLogsBtn = document.getElementById('copyLogsBtn');
  const clearLogsBtn = document.getElementById('clearLogsBtn');
  const logList = document.getElementById('logList');

  let currentAuditLogs = [];

  // Localization Support for Language Plugins (Zero Hardcoded UI Strings)
  const I18N_FALLBACKS = {
    'mcp.logs.title': 'Live AI Activity Log',
    'mcp.logs.tooltip_popout': 'Open detached log monitor on second monitor',
    'mcp.logs.tooltip_save': 'Save logs to .log file',
    'mcp.logs.tooltip_copy': 'Copy all logs to clipboard',
    'mcp.logs.tooltip_clear': 'Clear activity logs',
  };
  let currentTranslations = {};

  async function initI18n() {
    try {
      const res = await callRpc('i18n.getTranslations', {
        keys: Object.keys(I18N_FALLBACKS),
      });
      if (res && res.translations) {
        currentTranslations = res.translations;
      }
    } catch (e) {
      // Graceful fallback per Localization Guide Section 5
    }
    applyI18n();
  }

  function tr(key) {
    return currentTranslations[key] || I18N_FALLBACKS[key] || key;
  }

  function applyI18n() {
    document.querySelectorAll('[data-i18n-tooltip]').forEach((el) => {
      const key = el.getAttribute('data-i18n-tooltip');
      const text = tr(key);
      el.setAttribute('aria-label', text);
      el.dataset.tooltipText = text;
    });
    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      el.textContent = tr(key);
    });
  }

  // Reliable In-DOM Floating Tooltip Engine (bypasses Windows WebView2 HWND tooltip suppression)
  const tooltipEl = document.getElementById('pluginTooltip');
  let activeTooltipTarget = null;

  function showTooltip(el) {
    if (!tooltipEl) return;
    const key = el.getAttribute('data-i18n-tooltip');
    const text = key ? tr(key) : (el.dataset.tooltipText || el.getAttribute('title') || el.getAttribute('aria-label'));
    if (!text) return;

    activeTooltipTarget = el;
    if (el.hasAttribute('title')) {
      el.dataset.nativeTitle = el.getAttribute('title');
      el.removeAttribute('title');
    }

    tooltipEl.textContent = text;
    tooltipEl.classList.add('visible');

    const rect = el.getBoundingClientRect();
    const ttRect = tooltipEl.getBoundingClientRect();

    let top = rect.bottom + 6;
    let left = rect.left + (rect.width / 2) - (ttRect.width / 2);

    if (left < 6) left = 6;
    if (left + ttRect.width > window.innerWidth - 6) {
      left = window.innerWidth - ttRect.width - 6;
    }
    if (top + ttRect.height > window.innerHeight - 6) {
      top = rect.top - ttRect.height - 6;
    }

    tooltipEl.style.top = top + 'px';
    tooltipEl.style.left = left + 'px';
  }

  function hideTooltip(el) {
    if (!tooltipEl) return;
    tooltipEl.classList.remove('visible');
    if (el && el.dataset.nativeTitle) {
      el.setAttribute('title', el.dataset.nativeTitle);
      delete el.dataset.nativeTitle;
    }
    activeTooltipTarget = null;
  }

  document.addEventListener('mouseover', (e) => {
    const target = e.target.closest('[data-i18n-tooltip], [data-tooltip]');
    if (target) {
      showTooltip(target);
    }
  });

  document.addEventListener('mouseout', (e) => {
    const target = e.target.closest('[data-i18n-tooltip], [data-tooltip]');
    if (target) {
      hideTooltip(target);
    }
  });

  document.addEventListener('mousedown', () => {
    if (activeTooltipTarget) {
      hideTooltip(activeTooltipTarget);
    }
  });

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
          } else if (method === 'i18n.getTranslations') {
            resolve({ locale: 'en', translations: I18N_FALLBACKS });
          } else {
            resolve({ status: 'ok' });
          }
        }, 100);
      }
    });
  }

  // Receive JSON-RPC responses and notifications from Shellit host
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.addEventListener('message', (event) => {
      try {
        let msg = event.data;
        if (typeof msg === 'string') {
          msg = JSON.parse(msg);
        }

        // Notification from host (e.g. locale change)
        if (msg.method === 'i18n.localeChanged') {
          initI18n();
          return;
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
            // Antigravity IDE uses 'serverUrl' for SSE transport
            serverUrl: sseUrl,
          },
        },
      },
      null,
      2
    );
    // Strip comments from displayed JSON (JSON.stringify doesn't include them)
    configCode.textContent = JSON.stringify(
      { mcpServers: { shellit: { serverUrl: sseUrl } } },
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
        currentAuditLogs = res.logs;
        renderLogs(currentAuditLogs);
      }
    } catch (_) {}
  }

  function renderLogs(logs) {
    if (!logs || logs.length === 0) {
      logList.innerHTML = '<div class="empty-logs">Waiting for incoming tool calls from Antigravity, Claude, Cursor...</div>';
      return;
    }

    logList.innerHTML = '';
    logs.slice(0, 50).forEach((entry) => {
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

  function formatLogsAsText(logs) {
    return logs
      .map((entry) => {
        const time = entry.timestamp ? new Date(entry.timestamp).toISOString() : '';
        const status = entry.isSuccess ? 'SUCCESS' : 'FAILED';
        const client = entry.clientName || 'AI Client';
        const tool = entry.toolName || 'tool';
        const args = JSON.stringify(entry.arguments || {}, null, 2);
        const result = entry.errorMessage || entry.resultSnippet || '';

        return [
          `================================================================================`,
          `[${time}] [${status}] [${client}] TOOL: ${tool}`,
          `ARGUMENTS:`,
          args,
          `RESULT / OUTPUT:`,
          result,
          `================================================================================\n`,
        ].join('\n');
      })
      .join('\n');
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

  copyAntigravityBtn.addEventListener('click', () => {
    copyToClipboard(configCode.textContent, 'Copied Antigravity MCP configuration');
  });

  copyClaudeBtn.addEventListener('click', () => {
    const claudeJson = JSON.stringify(
      {
        mcpServers: {
          shellit: {
            // Claude Desktop uses 'url' for SSE transport
            url: `http://127.0.0.1:${currentPort}/sse`,
          },
        },
      },
      null,
      2
    );
    // Clean JSON (no comments)
    const cleanClaudeJson = JSON.stringify(
      { mcpServers: { shellit: { url: `http://127.0.0.1:${currentPort}/sse` } } },
      null,
      2
    );
    copyToClipboard(cleanClaudeJson, 'Copied Claude Desktop configuration');
  });

  popoutLogsBtn.addEventListener('click', () => {
    callRpc('mcp.openDetachedLogs').catch(() => {
      window.open('logs.html', 'ShellitMcpLogs', 'width=1020,height=740');
    });
  });

  exportLogsBtn.addEventListener('click', () => {
    if (currentAuditLogs.length === 0) {
      callRpc('notifications.show', {
        title: 'Shellit MCP Server',
        message: 'No logs to export',
      });
      return;
    }
    const logText = formatLogsAsText(currentAuditLogs);
    const blob = new Blob([logText], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    a.href = url;
    a.download = `shellit-ai-activity-${timestamp}.log`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    callRpc('notifications.show', {
      title: 'Shellit MCP Server',
      message: 'Saved logs to file',
    });
  });

  copyLogsBtn.addEventListener('click', () => {
    if (currentAuditLogs.length === 0) {
      callRpc('notifications.show', {
        title: 'Shellit MCP Server',
        message: 'No logs to copy',
      });
      return;
    }
    const logText = formatLogsAsText(currentAuditLogs);
    copyToClipboard(logText, `Copied ${currentAuditLogs.length} log entries`);
  });

  if (logList) {
    logList.addEventListener('wheel', (e) => {
      e.stopPropagation();
      logList.scrollTop += e.deltaY;
    }, { passive: false });
  }

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
    currentAuditLogs = [];
    renderLogs([]);
  });

  // Initial Run
  initI18n();
  updateUiState();
  refreshStatus();
  refreshLogs();

  // Periodic Refresh
  setInterval(() => {
    refreshStatus();
    refreshLogs();
  }, 2500);
})();
