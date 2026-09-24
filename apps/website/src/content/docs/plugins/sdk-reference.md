---
title: Desktop Plugin SDK API Reference
description: Complete JavaScript API specification for Shellit extensions.
---

Every Shellit desktop plugin runs inside an isolated browser sandbox and interacts with the host application via the global `window.shellit` bridge.

:::note[Sandbox Security Model]
Plugins cannot make direct raw TCP socket calls or access the host filesystem directly. All operations pass through asynchronous message serialization verified against permissions explicitly granted in `manifest.json`.
:::

## The `window.shellit` Interface

### Module `shellit.terminal`

Programmatic terminal interaction and buffer inspection.

#### `shellit.terminal.sendInput(sessionId: string, data: string): Promise<void>`
Sends keystrokes or ANSI control sequences into an active PTY session.
* **Permission:** `terminal:write`
* **Parameters:**
  * `sessionId`: String UUID of the target terminal session.
  * `data`: String to inject (e.g., `"top -b -n 1\n"`).

#### `shellit.terminal.getBuffer(sessionId: string, linesCount: number): Promise<string[]>`
Retrieves the most recent lines from the terminal scrollback buffer.
* **Permission:** `terminal:read`
* **Returns:** Array of plain text strings stripped of ANSI color codes.

#### `shellit.terminal.onData(sessionId: string, callback: (chunk: string) => void): () => void`
Subscribes to live streaming terminal output. Returns an unsubscribe teardown function.

---

### Module `shellit.hosts`

Access to the sanitized server catalog.

#### `shellit.hosts.list(): Promise<HostSummary[]>`
Retrieves saved servers for the current vault profile without exposing sensitive credentials.
* **Permission:** `hosts:read`
* **Return Type:**
```typescript
interface HostSummary {
  id: string;
  label: string;
  hostname: string;
  port: number;
  username: string;
  environment: 'PROD' | 'STAGE' | 'DEV';
  tags: string[];
  latencyMs: number | null; // Real-time RTT latency in milliseconds
}
```

#### `shellit.hosts.connect(hostId: string): Promise<string>`
Opens a new SSH tab connected to the specified host.
* **Permission:** `ssh:connect`
* **Returns:** Newly initialized `sessionId`.

---

### Module `shellit.sftp`

Remote file browsing and transfer.

#### `shellit.sftp.listDirectory(sessionId: string, remotePath: string): Promise<RemoteFileInfo[]>`
Lists directory contents on the remote server.
* **Permission:** `sftp:read`

#### `shellit.sftp.readFile(sessionId: string, remotePath: string): Promise<Uint8Array>`
Reads a remote file as raw binary bytes.
* **Permission:** `sftp:read`

#### `shellit.sftp.writeFile(sessionId: string, remotePath: string, data: Uint8Array): Promise<void>`
Writes binary data to a remote file path.
* **Permission:** `sftp:write`

---

### Module `shellit.ui`

Integration with Shellit's cyberpunk user interface.

#### `shellit.ui.showToast(message: string, type?: 'info' | 'success' | 'warning' | 'error'): void`
Renders an animated cyberpunk notification banner.

#### `shellit.ui.openModal(title: string, htmlContent: string): Promise<boolean>`
Opens a native Shellit modal dialog hosting custom HTML content.
