# Shellit — Project Context & Operating Guide for Gemini / Antigravity

Welcome to **Shellit** — a modern, secure, cross-platform SSH client, SFTP manager, and server management tool built entirely with Flutter & Dart, inspired by the best ergonomics of Termius but developed as an independent, extensible, and feature-rich developer tool.

---

## 1. Project Architecture (Monorepo on Packages)

The project is structured as a multi-package monorepo to allow fully isolated parallel development across agents:

```text
Shellit/
├── GEMINI.md                       # This project guide and entry point for AI agents
├── system-context.md               # Product high-level vision
├── .antigravity/
│   └── rules.md                    # Antigravity session-level rules
├── raw-sources/
│   └── reference.png               # Ergonomic reference layout (not for direct cloning!)
├── docs/                           # Project Operations & Coordination Center
│   ├── AGENTS_MASTER_GUIDE.md      # Master Operating Guide for all agents
│   ├── ROADMAP.md                  # Milestone & Phase roadmap
│   ├── CHECKLIST.md                # Interactive development checklist
│   ├── BUGS_AND_ISSUES.md          # Realtime bug tracker and issue log
│   ├── IDEAS_AND_BACKLOG.md        # Feature ideas and improvements backlog
│   ├── CHRONICLE.md                # Development chronicle (author's devlog style)
│   └── agents/                     # Dedicated agent instructions
│       ├── AGENT_1_STORAGE.md      # Storage & Security Team (Drift/SQLCipher, Argon2id)
│       ├── AGENT_2_NETWORK.md      # Network & SSH Team (dartssh2, PTY streams, SFTP)
│       ├── AGENT_3_TERMINAL_UI.md  # UI & Terminal Cross-Platform Team (xterm.dart, UI Shell)
│       ├── AGENT_4_PLUGINS.md      # Desktop Plugin Ecosystem Team (manifest, IPC bridge)
│       ├── AGENT_5_WEBSITE.md      # Web Ecosystem & Docs Team (Astro, Starlight, Scrollytelling)
│       ├── AGENT_6_CHRONICLE_PUBLISHER.md # Chronicle Web Publisher Agent (Astro MDX, Interactive Timeline)
│       └── AGENT_CHRONICLE_WRITER.md # Chronicle & Devlog Writer Agent (Raw Repository Devlog)
├── packages/
│   ├── core_foundation/            # Pure domain entities, contracts/interfaces, Result/Failure, logger
│   ├── storage_vault/              # Encrypted DB, master-password, hosts/keys repositories
│   ├── ssh_network_core/           # SSH sessions, PTY pipes, SFTP client, port forwarding
│   ├── terminal_ui/                # Terminal emulator widget, tabs, tiling splits, mobile accessory bar
│   └── desktop_plugin_sdk/         # Plugin loader, manifest validator, WebView IPC (desktop only)
└── apps/
    ├── shellit/                    # Main Flutter application (DI, routing, native runners)
    └── website/                    # Official Web Portal (Astro, Starlight, Scrollytelling, PocketBase)
```

---

## 2. Shellit Identity vs. Reference

We use `raw-sources/reference.png` solely as an ergonomic guideline (sidebar layout, clean top bar, host cards). **Shellit is NOT a Termius clone:**
1. **Live Host Telemetry:** Visual RTT ping latency dot (<50ms green, <200ms yellow, offline grey) directly on cards.
2. **Environment Protection:** Colored environment badges (`PROD` alert red, `STAGE` yellow, `DEV` blue) with optional warnings against destructive commands on production.
3. **Multi-View Catalog:** Quick toggle between Grid View, Dense List View (for 50+ servers), and Hierarchical Folder Tree View.
4. **Omni-Bar (`Ctrl+K` / `Cmd+K`):** Raycast-style command palette for instant host connect, snippets execution, split layout management, and theme switching.
5. **Matrix Tiling Splits:** 2x2, horizontal and vertical splits inside tabs with Broadcast Input mode.
6. **Open Desktop Plugin SDK:** User-extendable plugins (`.shellit`) via sandboxed WebView IPC.

---

## 3. Strict Rules for All Agents

1. **Context7 Rule:** Always fetch and adhere to up-to-date documentation for any library or API (`dartssh2`, `xterm.dart`, `drift`, `sqlcipher`, `flutter_riverpod`, `go_router`).
2. **Package Isolation & Contract-First:** 
   * Modifying packages must depend ONLY on abstractions from `packages/core_foundation/`.
   * No direct cross-package dependencies between feature packages.
3. **Zero Credentials Leakage:**
   * Never output private keys, passwords, or tokens in logs or error messages.
   * Ensure memory zeroization of decrypted keys after use.
4. **Desktop vs. Mobile Hygiene:**
   * Never import desktop-only dependencies (WebView2, FFI plugin loaders) into code compiled for mobile (Android/iOS). Use no-op stubs or conditional exports.
5. **Realtime Bug Tracker Protocol:**
   * Any detected bug or breaking issue must be immediately registered in `docs/BUGS_AND_ISSUES.md`.
   * When resolved, update status to `RESOLVED`, add regression unit test, and describe root cause and fix.
6. **Checklist, Backlog & Bilingual Chronicle Protocol:**
   * Mark completed tasks in `docs/CHECKLIST.md` and keep feature statuses in `docs/IDEAS_AND_BACKLOG.md` up to date (`IN_PROGRESS`, `IMPLEMENTED`).
   * Keep BOTH Russian (`docs/CHRONICLE.md`) and English (`docs/CHRONICLE.en.md`) chronicles strictly synchronized.
   * Always include canonical timestamps (`*Время: ...*` / `*Timestamp: ...*`).
   * Adhere to refined author style without colloquial clichés («по ходу пьесы») or repetitive phrasing.
7. **Zero Hardcoded UI Strings & I18n Ready:**
   * Never hardcode user-visible strings (labels, buttons, tooltips, dialogs, errors) in Flutter widgets.
   * All UI text must use `context.tr('key')` and support fallback to English and community localization plugins (see `docs/LOCALIZATION_AND_I18N_GUIDE.md`).
8. **Strict Anonymity & Zero Infrastructure/PII Leakage (Абсолютная анонимность):**
   * **Никаких реальных IP-адресов:** Категорически запрещено указывать, коммитить или упоминать реальные IP-адреса боевых серверов (VPS, нод, шлюзов) в коде, CI/CD конфигурациях, документации, примерах консольных команд, тестах или летописях. Все боевые адреса подключаются исключительно через защищенные секреты окружения (`${{ secrets.SENKO_HOST }}`).
   * **Фиктивные адреса для тестов и примеров:** В юнит-тестах, документации и примерах использовать исключительно зарезервированные RFC 5737 диапазоны (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`) либо локальные фиктивные адреса (`192.168.1.x`, `127.0.0.1`).
   * **Запрет деанонимизации стороннего софта и топологии:** Категорически запрещено упоминать в коде и документации стороннее приватное ПО, установленное на серверах владельца (любые VPN-сервисы, прокси-шлюзы, сторонние панели управления, личные инструменты, порты приватных сервисов), а также реальные имена узлов, внутренние пути, провайдеров или персональные данные (PII), связывающие инфраструктуру с конкретными людьми или закрытыми сервисами.
   * **Невидимость санитарных операций:** Любые технические действия по очистке истории Git или удалению чувствительных данных никогда не должны описываться в летописи, чек-листах или баг-трекере.

---

## 4. Key Commands

```bash
# Analyze all packages
flutter analyze

# Run unit tests across packages
flutter test

# Format code
dart format .
```
