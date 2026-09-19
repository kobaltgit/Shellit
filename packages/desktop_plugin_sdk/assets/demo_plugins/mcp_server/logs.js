/**
 * Shellit MCP Detached Log Monitor Script
 */
(function () {
  const urlParams = new URLSearchParams(window.location.search);
  const mcpPort = parseInt(urlParams.get('port'), 10) || 4422;
  const mcpBaseUrl = `http://127.0.0.1:${mcpPort}`;

  let allLogs = [];
  let currentFilter = 'all';
  let searchQuery = '';
  let autoScroll = true;

  // DOM Elements
  const logsWrapper = document.getElementById('logsWrapper');
  const searchInput = document.getElementById('searchInput');
  const filterBtns = document.querySelectorAll('.filter-btn');
  const autoScrollCheck = document.getElementById('autoScrollCheck');
  const exportLogsBtn = document.getElementById('exportLogsBtn');
  const copyAllBtn = document.getElementById('copyAllBtn');
  const clearLogsBtn = document.getElementById('clearLogsBtn');
  const statusBadge = document.getElementById('statusBadge');
  const statusText = document.getElementById('statusText');
  const clientsCount = document.getElementById('clientsCount');
  const toast = document.getElementById('toast');

  function showToast(message) {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add('show');
    setTimeout(() => {
      toast.classList.remove('show');
    }, 2500);
  }

  async function fetchServerStatus() {
    try {
      const res = await fetch(`${mcpBaseUrl}/health`);
      if (res.ok) {
        const data = await res.json();
        statusBadge.className = 'status-badge';
        statusText.textContent = 'ACTIVE';
        clientsCount.textContent = `${data.activeClients || 0} clients`;
      } else {
        statusBadge.className = 'status-badge stopped';
        statusText.textContent = 'OFFLINE';
      }
    } catch (_) {
      statusBadge.className = 'status-badge stopped';
      statusText.textContent = 'OFFLINE';
    }
  }

  async function fetchLogs() {
    try {
      const res = await fetch(`${mcpBaseUrl}/logs`);
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data.logs)) {
          const countBefore = allLogs.length;
          allLogs = data.logs;
          renderLogs();
          if (autoScroll && allLogs.length > countBefore) {
            logsWrapper.scrollTop = 0;
          }
        }
      }
    } catch (_) {}
  }

  function renderLogs() {
    let filtered = allLogs;

    // Filter by status
    if (currentFilter === 'success') {
      filtered = filtered.filter((l) => l.isSuccess);
    } else if (currentFilter === 'error') {
      filtered = filtered.filter((l) => !l.isSuccess);
    }

    // Filter by search query
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter((l) => {
        const tool = (l.toolName || '').toLowerCase();
        const client = (l.clientName || '').toLowerCase();
        const args = JSON.stringify(l.arguments || {}).toLowerCase();
        const snippet = (l.resultSnippet || l.errorMessage || '').toLowerCase();
        return tool.includes(q) || client.includes(q) || args.includes(q) || snippet.includes(q);
      });
    }

    if (filtered.length === 0) {
      logsWrapper.innerHTML = `
        <div class="empty-state">
          <span>${searchQuery ? 'No log entries match your filter.' : 'Waiting for incoming tool calls from AI clients...'}</span>
        </div>
      `;
      return;
    }

    logsWrapper.innerHTML = '';
    filtered.forEach((entry) => {
      const card = document.createElement('div');
      card.className = 'log-card' + (entry.isSuccess ? '' : ' error');

      const time = entry.timestamp
        ? new Date(entry.timestamp).toLocaleString()
        : 'Unknown time';
      const client = entry.clientName || 'AI Client';
      const tool = entry.toolName || 'tool';
      const argsFormatted = JSON.stringify(entry.arguments || {}, null, 2);
      const resultText = entry.errorMessage
        ? `ERROR: ${entry.errorMessage}`
        : entry.resultSnippet || '(No output returned)';

      card.innerHTML = `
        <div class="log-card-header">
          <div class="log-meta-left">
            <span class="log-tool ${entry.isSuccess ? '' : 'error'}">${escapeHtml(tool)}</span>
            <span class="log-client">${escapeHtml(client)}</span>
            <span class="log-time">${escapeHtml(time)}</span>
          </div>
          <span class="log-status-badge ${entry.isSuccess ? 'success' : 'failed'}">
            ${entry.isSuccess ? 'SUCCESS' : 'FAILED'}
          </span>
        </div>

        <div>
          <div class="log-section-label">Arguments:</div>
          <pre class="code-block">${escapeHtml(argsFormatted)}</pre>
        </div>

        <div>
          <div class="log-section-label">${entry.isSuccess ? 'Result Output:' : 'Error Message:'}</div>
          <pre class="code-block" style="${entry.isSuccess ? '' : 'color: var(--accent-red);'}">${escapeHtml(resultText)}</pre>
        </div>
      `;

      logsWrapper.appendChild(card);
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

  // Export to .log file
  exportLogsBtn.addEventListener('click', () => {
    if (allLogs.length === 0) {
      showToast('No logs to export');
      return;
    }

    const logText = formatLogsAsText(allLogs);
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
    showToast('Saved logs to file');
  });

  // Copy All to Clipboard
  copyAllBtn.addEventListener('click', () => {
    if (allLogs.length === 0) {
      showToast('No logs to copy');
      return;
    }
    const logText = formatLogsAsText(allLogs);
    navigator.clipboard.writeText(logText).then(() => {
      showToast(`Copied ${allLogs.length} log entries to clipboard`);
    }).catch(() => {
      const ta = document.createElement('textarea');
      ta.value = logText;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      showToast(`Copied ${allLogs.length} log entries to clipboard`);
    });
  });

  // Clear Logs
  clearLogsBtn.addEventListener('click', async () => {
    try {
      await fetch(`${mcpBaseUrl}/api/logs/clear`, { method: 'POST' });
    } catch (_) {}
    allLogs = [];
    renderLogs();
    showToast('Logs cleared');
  });

  // Filter Buttons
  filterBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      filterBtns.forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      currentFilter = btn.dataset.filter;
      renderLogs();
    });
  });

  // Search Input
  searchInput.addEventListener('input', (e) => {
    searchQuery = e.target.value.trim();
    renderLogs();
  });

  // Auto Scroll Check
  autoScrollCheck.addEventListener('change', (e) => {
    autoScroll = e.target.checked;
  });

  // Initial Fetch and Polling
  fetchServerStatus();
  fetchLogs();
  setInterval(() => {
    fetchServerStatus();
    fetchLogs();
  }, 1500);
})();
