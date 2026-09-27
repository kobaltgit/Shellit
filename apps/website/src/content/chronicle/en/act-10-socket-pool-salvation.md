---
title: "Act X: Socket Pool Salvation — 16,000 Leaked Ports, the OpenSSH Banner, and v0.8.8 Release"
description: "The story of an unexpected network blackout: how background RTT telemetry in shellit.exe exhausted 16,071 Windows ports due to the subtle difference between socket.close() and socket.destroy(), how OpenSSH banners trap half-closed sockets, SQLite telemetry decoupling, and the v0.8.8 release."
actNumber: 10
period: "September 27, 2026, 20:10 — 20:45"
pubDate: 2026-09-27
readingTime: "7 min"
stage: "v0.8.8 Socket Pool Salvation"
relatedBugs: ["BUG-043", "BUG-044"]
tags: ["networking", "sockets", "ephemeral-ports", "dart-io", "ssh", "telemetry", "v0.8.8"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> A sudden network blackout on the workstation: background `shellit.exe` held 16,071 active TCP sockets open, depleting the entire operating system network pool (WSAENOBUFS). Investigation revealed a treacherous trap in `dart:io` when interacting with OpenSSH daemons: calling `socket.close()` only shuts down writes, while the server immediately delivers an identification banner. The resolution rescued the OS port pool via `socket.destroy()`, decoupled telemetry from redundant SQLite disk writes, and stabilized releases v0.8.7/v0.8.8.
</div>

## Entry 51. The GitHub Releases 404 Riddle: Bridge from v0.8.6 to v0.8.7

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 26, 2026, 18:20 — 18:35 (~15 minutes)
</span>

### 1. The Trigger & Detective Investigation

The prelude to this act unfolded right after deploying release v0.8.6 with Universal Command Guard. We tested the "Check for updates" feature in the Shellit settings card. Clicking the button returned an unperturbed message: *"No remote releases found. You are running the latest preview build"*.

How could that be? Releases were present on GitHub, the tag `v0.8.6` was live, yet the client completely ignored them.

A second observation concerned the website chronicle: pages stated "8 thematic chapters". Incrementing this number manually across templates and RSS feeds with every new act was an invitation to recurrent desynchronization.

---

### 2. The Nuances of the GitHub REST API

We inspected the API call in `AboutSettingsCard.releasesApiUrl`. It used the standard canonical URL:  
`https://api.github.com/repos/kobaltgit/Shellit/releases/latest`

It seemed like the most intuitive endpoint to query. However, reviewing the GitHub REST API specification revealed an unexpected catch:

> The `/releases/latest` endpoint returns **strictly** releases marked as Stable. If all releases in a repository are tagged as **Pre-release** (as is standard for Shellit's alpha stage), this endpoint consistently responds with **HTTP 404 Not Found**!

Receiving a 404 status, our client concluded that no remote releases existed (`BUG-043`).

---

### 3. Resolution & Stabilization

1. **Honest Release Queries (`BUG-043`):**  
   We changed the endpoint to `https://api.github.com/repos/kobaltgit/Shellit/releases?per_page=5`. The client now fetches the latest releases, filters out drafts (`r['draft'] != true`), and picks the most recent release regardless of whether it is pre-release or stable.

2. **Dynamic Wording on the Website:**  
   In Astro templates (`ru/chronicle/index.astro`, `chronicle/index.astro`), RSS feeds `rss.xml.ts`, and `llms.txt`, the hardcoded number "8" was replaced with descriptive wording ("Thematic chapters..."). The portal remains perpetually accurate as new acts arrive.

3. **Release v0.8.7:**  
   All changes were verified against the unit test suite (7/7 in `about_settings_card_test.dart`), and the application version was incremented to **v0.8.7**.

---

## Entry 52. 16,000 Open Sockets: How Background Ping Exhausted the Windows Network Pool and What `socket.destroy()` Taught Us

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 27, 2026, 20:10 — 20:45 (~35 minutes)
</span>

### 1. The Trigger and an Alarm from the System Monitor

It began with an abrupt workstation network outage. Web pages failed to load, browsers threw connection errors, background services timed out, and the OS system monitor showed an alarming anomaly:

The background process `shellit.exe` (PID 5932) was caught in a socket leak loop, holding **16,071 active TCP sockets** open and thoroughly exhausting the Windows network pool. Terminating the process immediately dropped occupied network sockets from 16,602 down to 533.

The count 16,071 immediately stood out:
- By default, Windows allocates ephemeral client ports in the dynamic range 49152 to 65535.
- That equals exactly **16,384 ports**.
- Accounting for normal system services, Shellit had consumed 100% of the remaining Windows ephemeral ports, triggering OS-wide `WSAENOBUFS` (No buffer space available) failures.

---

### 2. The Gotchas: Half-Closed Sockets in Dart (`dart:io`)

Diagnostics revealed a subtle intricacy in Dart's socket handling when paired with OpenSSH servers:

1. **The Divergence Between `close()` and `destroy()`:**  
   In `SshClientService.pingHost`, host RTT latency was sampled by establishing a socket via `Socket.connect(hostname, port)` and subsequently invoking `await socket.close()`.  
   In Dart, `socket.close()` only shuts down the **write half-duplex** (`shutdown(SHUT_WR)`), sending a TCP FIN packet to the remote endpoint. The read stream remains open, waiting for the remote server to close its end.

2. **The OpenSSH Version Banner:**  
   Upon completing a TCP handshake on port 22, an OpenSSH daemon immediately transmits its identification string (`SSH-2.0-OpenSSH...`). This banner reached the Windows TCP stack. Because Shellit did not consume those incoming bytes and did not call `socket.destroy()`, the socket lingered in a half-closed state with unread buffer data. Dart VM and the Windows kernel retained the socket handle and its bound ephemeral port.

3. **Background Telemetry Timer:**  
   The host latency monitor routinely polled hosts every 15 seconds. Each poll left behind an abandoned socket handle in the OS kernel. Over hours of continuous runtime, these leaked ports accumulated steadily until the entire dynamic port pool was depleted.

4. **Reactive SQLite Storms:**  
   Each latency measurement wrote the ping result to the Drift `hostsTable`. This triggered continuous emissions from the reactive `watchAllHosts()` stream, forcing redundant widget rebuilds across the UI.

---

### 3. Remediation & Architecture Stabilization (BUG-044)

We deployed a 3-tier remedy:

#### 1. Guaranteed `socket.destroy()`
In `SshClientService.pingHost`, the half-close call was replaced with a strict `finally` block:
```dart
Socket? socket;
try {
  socket = await Socket.connect(hostname, port, timeout: effectiveTimeout);
  stopwatch.stop();
  return PingResult.success(latencyMs: stopwatch.elapsedMilliseconds);
} finally {
  socket?.destroy();
}
```
Invoking `destroy()` sends a bidirectional reset (RST), discards kernel buffers, and instantly returns the ephemeral port to the operating system pool.

#### 2. Guarding Terminal and SFTP Sessions Against Auth Leaks
In `createTerminalSession` and `openSftpSession`, we added fail-safe `finally` blocks: if authentication fails, a host key is rejected, or a handshake times out, `client?.close()` and `socket?.destroy()` are guaranteed to execute before the method exits.

#### 3. Decoupling SQLite from Transient Telemetry
In `HostsNotifier.updateHostLatency`, we introduced `persist: false`. RTT latency updates now occur in memory for UI rendering without disk I/O overhead and without triggering reactive database storms.

---

### 4. Summary: Release v0.8.8

- Resolved `BUG-044` (P0 Blocker: OS network pool exhaustion).
- Added a regression unit test simulating OpenSSH banner transmission (`ssh_client_service_test.dart`).
- All 430+ unit tests across the monorepo passed (100% green):
  - `core_foundation`: 27/27 passed.
  - `ssh_network_core`: 81/81 passed.
  - `terminal_ui`: 126/126 passed.
  - `desktop_plugin_sdk`: 62/62 passed.
  - `apps/shellit`: 61/61 passed.
- Static analysis `flutter analyze` completed with 0 errors and warnings.
- Bumped application version to **v0.8.8**.

Shellit's background host telemetry now runs silently, respecting system resources and guaranteeing leak-free socket management across all platforms.
