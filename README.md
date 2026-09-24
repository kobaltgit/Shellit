<p align="center">
  <img src="banner.svg" alt="Shellit — Modern SSH, SFTP &amp; Server Hub" width="100%">
</p>

<p align="center">
  <img src="icon.svg" alt="Shellit Logo" width="100" height="100">
</p>

<h1 align="center">Shellit</h1>

<p align="center">
  <strong>A modern, secure, and cross-platform SSH client, SFTP manager, and next-generation server hub built with Flutter &amp; Dart.</strong>
</p>

<p align="center">
  <strong>English</strong> | <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.12%2B-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="docs/AGENTS_MASTER_GUIDE.md"><img src="https://img.shields.io/badge/Status-Alpha%20%2F%20Developer%20Preview%20(Experimental)-orange" alt="Status: Alpha / Developer Preview (Experimental)"></a>
  <a href="#-security-status--transparency"><img src="https://img.shields.io/badge/Security-Experimental%20Zero--Trust-critical" alt="Security"></a>
  <a href="system-context.md"><img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android%20%7C%20iOS-informational" alt="Platform"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3"></a>
</p>

> ⚠️ **Status: Alpha / Developer Preview (Experimental)**  
> Shellit is currently in active alpha testing. It features an **Experimental Zero-Trust Architecture under active development & security auditing**. While cryptographic primitives (AES-256-GCM, Argon2id, TOFU host validation) are strictly implemented, features and APIs are evolving rapidly. We welcome community testing, feedback, and independent security auditing.

---

## 📖 About the Project

**Shellit** combines the ergonomics of premier infrastructure management tools with uncompromising security. Engineered as an independent developer and sysadmin power tool, it emphasizes blazing-fast performance, strict architectural isolation, and transparent connection control.

Unlike traditional terminal emulators, Shellit delivers live server telemetry before connecting, built-in protection against accidental destructive commands in production, and an open, extensible plugin ecosystem.

---

## ⚡ Development Velocity: From Zero to Release in 24 Hours

Shellit was designed, engineered, and tested from scratch in **under 24 hours** (~19 hours of active vibe-coding with autonomous AI agents): from an empty folder to a full-featured cross-platform application with self-hosted E2EE sync, an MCP AI Gateway, and a Gemini assistant.

<details>
<summary><strong>⏱️ View Development Timeline & Milestone Breakdown</strong></summary>

| Elapsed Time | Milestone | Key Deliverables |
|---|---|---|
| **0h 00m** | **Inception** | Concept, monorepo architecture, package isolation, agent contracts |
| **+1h 40m** | **Core Foundation** | 4 isolated packages (`core`, `vault`, `network`, `plugins`), 105 tests |
| **+2h 00m** | **Terminal UI** | Obsidian Dark theme, live RTT ping dot, 126 unit & widget tests |
| **+5h 17m** | **v0.1.0** | Matrix 2x2 splits, tabs, two-pane SFTP, Windows Inno Setup installer |
| **+6h 03m** | **v0.2.0** | Self-hosted E2EE cloud sync on VPS, zero-knowledge Go relay server |
| **+7h 46m** | **v0.3.0** | Keychain manager, Ed25519/RSA key generator, integrated `ssh-copy-id` |
| **+9h 11m** | **v0.4.0** | Desktop Plugin SDK, sandboxed WebView2 IPC, Docker Monitor plugin |
| **+11h 31m** | **v0.5.0** | 100% i18n-ready (Zero Hardcoded Strings) & official Russian language pack |
| **+14h 35m** | **v0.6.0** | Mobile-first Android client with touch accessory bar & haptic feedback |
| **+20h 52m** | **v0.7.0** | Model Context Protocol (MCP) server for Cursor, Claude & Windsurf |
| **+24h 15m** | **v0.7.3** | Built-in Gemini AI snippets assistant, dynamic models, pop-out log windows |
| **+24h 45m** | **Phase 14** | 1-click ConPTY local terminal with shell discovery (PowerShell, WSL, cmd) |

> ⏱️ **Total Active Time:** ~19 hours (including a 4-hour night rest).  
> 🛡️ **Quality Metrics:** 34 completed stages, 24 reported & resolved bugs, 133+ passing tests, 0 analyzer errors.  
> 📖 **Read the unfiltered developer log:** [**`docs/CHRONICLE.en.md`**](docs/CHRONICLE.en.md).

</details>

---

## ✨ Key Features (Shellit Identity)

- 🔄 **Self-Hosted Zero-Knowledge E2EE Sync:**
  Seamlessly synchronize hosts, SSH keys, command snippets, and folders across all your devices (Windows, macOS, Linux, Android, iOS) using your own ultra-lightweight VPS relay server. All data is end-to-end encrypted client-side using **Argon2id** and **AES-256-GCM**. The server never sees your passwords, private keys, or host metadata. Supports plain HTTP (ideal for WireGuard, Tailscale, or LANs without domain/SSL hassles) as well as HTTPS (including self-signed certificates).

- 🟢 **Live Host Telemetry (Real-time Ping):**
  Instant RTT latency indicator displayed directly on host cards (`<50ms` green, `<200ms` yellow, offline grey). Inspect server reachability and response times before opening a connection.

- 🛡️ **Environment Protection & PROD Guard:**
  Distinct color badges for every server (`PROD` alert red, `STAGE` cautionary yellow, `DEV` calm blue). On servers marked with the `PROD` tag, a glowing red border activates around the terminal, and potentially destructive commands (`rm -rf`, `DROP`, `reboot`, fork bombs) trigger an interactive confirmation modal.

- ⚡ **Omni-Bar (`Ctrl+K` / `Cmd+K`):**
  Universal command palette inspired by Raycast and Spotlight: lightning-fast fuzzy search across hosts, one-key snippet execution, instant theme switching, and split management without taking your hands off the keyboard.

- 🪟 **Matrix Tiling Splits & Drag & Drop:**
  Flexible terminal workspace layouts (horizontal, vertical, 2x2 grid) within tabs. Drag and drop open session tabs into empty split slots, or use **Broadcast Input** to send keystrokes simultaneously to all active panes.

- 📂 **Two-Pane SFTP Manager:**
  Full-featured file manager integrated right into the session tab: local filesystem on the left, remote server on the right, drag-and-drop transfers, context menus, interactive visual chmod permissions editor, and background transfer queue.

- 📜 **Asciinema Session Recording & Audit:**
  Built-in terminal session recording following the **asciinema v2 (`.cast`)** standard and raw text logs (`.log`). Automatic recording policy for PROD servers, live `● REC` timer badge in the toolbar, and a two-tab audit log inspector.

- ⚡ **Command Snippets:**
  Curated library of frequently used shell commands with tag search, 1-click execution into the active shell, and instant lookup via Omni-Bar (`Ctrl+K`).

- 🗂️ **Multi-View Catalog:**
  Instantly switch between catalog view modes: responsive tile Grid, dense high-capacity List (for 50+ servers), and hierarchical Folder Tree.

- 🔐 **Zero Credentials Leakage & SQLCipher Vault:**
  Local database encrypted with **AES-256 (SQLCipher)**. Master password secured with **Argon2id** key derivation. Strict memory hygiene (Zeroize) clears plaintext secrets upon session closure, coupled with comprehensive log sanitization.

- 🤖 **Model Context Protocol (MCP Server Plugin):**
  Built-in MCP Gateway (specification 2024-11-05, Server-Sent Events / SSE) to securely connect modern AI assistants (Cursor, Claude Desktop, Windsurf, Antigravity) directly to your servers and terminal sessions. Exposes standardized tools to run commands, fetch terminal buffers, and inspect remote SFTP files under PROD Guard protection with a dedicated AI audit trail.

- 🧩 **Open Desktop Plugin SDK:**
  Extend the application's capabilities with custom sandboxed plugins (`.shellit`) communicating via an isolated WebView IPC bridge on desktop platforms.

- 🌐 **Community Language Packs:**
  100% internationalization-ready UI (Zero Hardcoded Strings). English is the native default, with an official Russian language pack readily available: [**Download `russian_lang_pack.shellit`**](plugins/russian_lang_pack.shellit).

---

## 🧩 Plugins & Extensions

Shellit supports dynamic installation of custom plugins and language packages (`.shellit`) on the fly without restarting the application.

### 📦 Extensions Catalog:

- 🤖 **[MCP Server Plugin (`plugins/mcp_server.shellit`)](plugins/mcp_server.shellit)** — built-in AI Gateway for Cursor, Claude, and Windsurf with PROD Guard security gate _(bundled out of the box)_.
- 🐳 **[Docker Monitor (`plugins/docker_monitor.shellit`)](plugins/docker_monitor.shellit)** — real-time container management and log inspector _(bundled out of the box)_.
- 🌐 **[Russian Language Pack (`plugins/russian_lang_pack.shellit`)](plugins/russian_lang_pack.shellit)** — 100% Russian translation of the user interface (527+ keys).

#### Installation Instructions:

1. Download the desired `.shellit` package from the [**`plugins/`**](plugins/) directory.
2. In the Shellit application, open the **Plugins** sidebar.
3. Click the **Install .shellit** button in the top-right corner and select the file.
4. For language packs: navigate to **Settings → Language & Localization** and select your preferred language!

> Learn more about the plugin ecosystem: [`plugins/README.md`](plugins/README.md).  
> Translation authoring guide: [`docs/LOCALIZATION_AND_I18N_GUIDE.md`](docs/LOCALIZATION_AND_I18N_GUIDE.md).

---

## 🏛 Monorepo Architecture

The project is structured as a modular monorepo following contract-first design and strict package isolation:

```text
Shellit/
├── apps/
│   └── shellit/                    # Main Flutter application (DI, Riverpod, Routing, Run)
├── packages/
│   ├── core_foundation/            # Domain entities, Result/Failure, interfaces/contracts
│   ├── storage_vault/              # Encrypted storage (Drift + SQLCipher, Argon2id, SyncCrypto)
│   ├── ssh_network_core/           # Network core (dartssh2, PTY streams, SFTP client, tunnels, recorder)
│   ├── terminal_ui/                # Terminal emulator (xterm.dart, tabs, matrix splits, mobile panel)
│   └── desktop_plugin_sdk/         # Plugin manifest specs, validator, and IPC sandbox
├── plugins/                        # Bundled plugins and language packs (.shellit)
├── servers/
│   └── sync_server/                # Lightweight sync relay server (Dart + SQLite, Docker, <20MB RAM)
└── docs/                           # Central coordination and documentation hub
```

> **Isolation Rule:** Feature packages depend _strictly_ on abstractions from `packages/core_foundation/`. Direct cross-dependencies between feature packages are prohibited.

---

## 🚀 Quick Start

### Requirements

- **Flutter SDK**: `>= 3.12.0`
- **Dart SDK**: `>= 3.12.0`
- Supported desktop environments: Windows 10/11, macOS (12+), Linux (Ubuntu 22.04+ / Debian / Fedora)

### 1. Clone & Fetch Dependencies

```bash
# Clone the repository
git clone https://github.com/kobaltgit/Shellit.git
cd Shellit

# Fetch dependencies for the main app
cd apps/shellit
flutter pub get
```

### 2. Run Application

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

### 3. Run Tests & Static Analysis

```bash
# Analyze code across all packages
flutter analyze

# Run unit and widget tests
flutter test
```

---

## ☁️ Self-Hosted Sync Server

Shellit frees you from expensive proprietary clouds. You can deploy your own lightweight synchronization relay server on any home server or VPS in under 60 seconds.

### 🛡️ Zero-Knowledge Architecture

- **Client-Side Encryption:** All hosts, private keys, snippets, and folders are encrypted using **AES-256-GCM**. Encryption keys are derived client-side from your Passphrase via **Argon2id**.
- **Blind Server:** The server only receives blind authentication tokens (`authHash`) and encrypted binary payloads. The server owner cannot read hostnames or any metadata.
- **Tombstones & LWW:** Deletions are tracked via tombstones, and conflicts are resolved via Last-Write-Wins (Pull-Then-Push).
- **Transport Freedom:** Works over plain `http://` (inside WireGuard, Tailscale, or private LANs without domain or certificate overhead) as well as `https://` (including self-signed certificates).

### 🚀 Running on Server via Docker Compose

1. Copy the server directory or create `docker-compose.yml` on your VPS:

```yaml
version: "3.8"

services:
  shellit-sync:
    build: ./servers/sync_server
    container_name: shellit-sync
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - PORT=8080
      - HOST=0.0.0.0
      - DATA_PATH=/data/shellit-sync.db
      - REGISTRATION_TOKEN=super-secret-invite-token # Optional: protect against unauthorized registrations
```

2. Start the service:

```bash
docker compose up -d
```

### 📱 Connecting in the Shellit App

1. Open **Settings → Sync & Cloud**.
2. Configure:
   - **Server URL:** `http://<your-vps-ip>:8080` or `https://sync.your-domain.com`.
   - **Vault ID:** Storage vault identifier (e.g. `my-servers`).
   - **Sync Passphrase:** Encryption passphrase (remember it for your other devices).
   - **Registration Token:** Registration token (if configured in `REGISTRATION_TOKEN` on the server).
   - When using self-signed certificates, enable **"Allow self-signed SSL / insecure HTTP"**.
3. Click **Test Connection**, then **Sync Now**.
4. Repeat on your phone or secondary computer — and your infrastructure is synchronized!

Comprehensive server documentation: [`servers/sync_server/README.md`](servers/sync_server/README.md).

---

## 📚 Documentation & Development

All development processes, technical specifications, and tasks are cataloged in the [`docs/`](docs/) directory:

- [`docs/AGENTS_MASTER_GUIDE.md`](docs/AGENTS_MASTER_GUIDE.md) — Master architectural guide and engineering standards.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — Milestone roadmap and progress timeline.
- [`docs/CHECKLIST.md`](docs/CHECKLIST.md) — Interactive task tracker across packages.
- [`docs/BUGS_AND_ISSUES.md`](docs/BUGS_AND_ISSUES.md) — Realtime bug registry and incident log.
- [`docs/CHRONICLE.en.md`](docs/CHRONICLE.en.md) — Project development devlog and chronicle.
- [`GEMINI.md`](GEMINI.md) — System operating guide for AI agents.

---

## 🛡️ Security Status & Transparency

Shellit implements an **Experimental Zero-Trust Architecture under active development & security auditing**. While the application adheres to robust cryptographic principles (client-side AES-256-GCM, Argon2id key derivation, memory zeroization, strict TOFU host validation, and sandboxed plugins), users and contributors should be mindful of the following:

- **Active Alpha / Developer Preview:** Shellit is in active alpha development and has not yet undergone a formal third-party cryptographic or security penetration audit. It is currently intended for developer evaluation, testing, and community feedback.
- **Independent Security Reviews Welcome:** We transparently invite security researchers, cryptographers, and penetration testers to inspect our architecture, audit the code, and review cryptographic workflows.
- **Responsible Disclosure:** If you discover a vulnerability or potential security flaw, please report it responsibly via GitHub Security Advisories or by contacting the project maintainers directly.

### Core Security Controls & Practices

- **Zero Hardcoded Secrets**: Credentials, API tokens, and private keys are never stored in plain text or committed to the codebase.
- **Encrypted Master Vault**: Passwords and private keys are encrypted locally using SQLCipher (AES-256). Without the master password, decrypting the database is mathematically infeasible.
- **Memory Hygiene (Zeroization)**: Decrypted private keys and credentials are automatically wiped from memory (`zeroize`) immediately after use to prevent memory dumping.
- **Strict Host Verification (TOFU)**: SSH host keys are verified on first use and tracked against stored fingerprints with visual Drunken Bishop (Randomart) recognition.
- **Sandboxed Desktop Plugins**: Third-party plugins execute within isolated webview environments with strict Content Security Policies (CSP) and permission boundaries.

---

## 📄 License

This project is licensed under the copyleft **[GNU General Public License v3.0 (GPLv3)](LICENSE)**.

### What This Means (Freedom with Responsibilities):

- ✅ **Freedom of Use:** You may freely run and use Shellit for personal and commercial server administration.
- ✅ **Freedom to Study & Modify:** Full source code is open, inspectable, and extensible.
- ⚠️ **Strict Copyleft Requirements:**
  - **Reciprocal Freedom:** Any forks, modifications, or derivative products must also be distributed under GPLv3 with full source code made available.
  - **No Closed-Source Redistribution:** Proprietary commercial wrapping of core components without source disclosure is strictly prohibited.
  - **Attribution:** Original copyright notices and license texts must remain intact.
