---
title: "Act I: Ground Zero & Architectural Manifesto"
description: "From empty folder to 105 green tests in two hours: why we dropped TermIt, how /grill-me prevented monolithic spaghetti, and how 4 AI subagents worked in parallel."
actNumber: 1
period: "September 18, 2026, 13:00 — 14:40"
pubDate: 2026-09-18
readingTime: "8 min"
stage: "v0.1.0 Alpha Core"
relatedBugs: ["BUG-001", "BUG-002", "BUG-003"]
tags: ["architecture", "grill-me", "vault", "argon2id", "parallel-agents"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Honest vibe-coding without manual syntax memorization. In this act, the philosophy of an independent SSH client is born, faulty naming is dismantled via the rigorous <code>/grill-me</code> interview mode, the monorepo splits into 5 isolated packages, and a parallel swarm of 4 AI subagents delivers the core in a record two hours.
</div>

## Entry 00. Genesis: Why Existing Tools Like Termius Fell Short

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 13:00 — 13:25 (~25 minutes)
</span>

I'll be honest: I am not a career software developer. I do not spend my days manually typing brackets, semicolons, and boilerplate classes. My focus lies in systems architecture, user workflows, product ergonomics, and data pipelines.

When modern AI models evolved to design solid software architectures and write clean code based on precise technical specifications, it felt like a paradigm shift. The friction between an idea in one's head and a running application dissolved. The key is to think in systems: understand data structures, UX realities, and steer the process as a product architect.

The necessity for Shellit arose from daily server operations. I used Termius and similar clients for a long time. While visually polished, major flaws became glaring in daily engineering life:

1. **Blind Host Cards:** You open a catalog of 30 servers, and every card looks identically static. Is the server reachable? Has ping spiked? Are you about to connect to production instead of staging? Zero ambient awareness.
2. **One-Size-Fits-All Catalogs:** Either a flat grid or nothing. When managing 50+ nodes, scrolling cards becomes exhausting. A dense table and hierarchical folder tree are essential.
3. **Walled Gardens:** No plugin ecosystem. Need a Docker container monitor in your sidebar? You have to open a raw shell and run `docker ps` by hand.

I sketched the core logic, extracted the proven ergonomics from reference layouts (sidebar, search bar, clean cards), and rejected blind cloning. The vision was defined: a fast, independent client with live RTT ping on cards, strict environment protection (Prod Guard), 2x2 matrix tiling splits, an Omni-Bar (`Ctrl+K`), and an open desktop plugin SDK.

---

## Entry 01. Why We Began with Rules Instead of Rushing to Code

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 13:25 — 13:45 (~20 minutes)
</span>

The biggest trap in AI-assisted coding is rushing in: *"Build me a pretty terminal app!"* The outcome is always a 2,000-line monolithic blob where even the AI gets tangled within three days.

To prevent this architectural decay, we established ironclad contracts first:
- **Modular Monorepo Isolation:** Encrypted storage (`storage_vault`), SSH networking (`ssh_network_core`), terminal UI (`terminal_ui`), and desktop plugins (`desktop_plugin_sdk`).
- **Contract-First Design via `core_foundation`:** All feature modules depend solely on pure abstract domain interfaces. The network engineer cannot corrupt the database schema; the UI layer cannot break Argon2id key derivation.
- **Realtime Bug Tracker & Backlog:** Every anomaly is immediately logged in `BUGS_AND_ISSUES.md`. Zero regressions swept under the rug.

---

## Entry 02. The /grill-me Interview & Naming Evolution

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 13:45 — 14:15 (~30 minutes)
</span>

Before writing code, we subjected the concept to an adversarial audit using `/grill-me`. Rather than an agreeable assistant, the AI acted as a relentless systems architect and product skeptic.

The initial draft name "TermIt" hit an immediate roadblock: Linux distributions have maintained a lightweight VTE terminal named `termit` in Debian/Ubuntu repositories for over a decade. Colliding with an established package was unacceptable. Etymological exploration of *termes* pointed to termites, while Greek roots evoked medical inflammations.

The final name emerged naturally: **Shellit** (specifically with a lowercase 'i'). It is concise, punchy, and an active imperative (*"Shell it!"*).

We finalized critical UX specifications during this session:
- **Dual-Pane SFTP in Dedicated Tab:** Drag-and-drop file transfers, background queues, and inline config editor.
- **2x2 Matrix Splits & Broadcast Input:** Synchronized keyboard broadcasting across multiple terminal panes.
- **Live RTT Ping Telemetry:** Visual millisecond latency indicators (<50ms green, <200ms yellow, offline grey) on catalog cards.
- **Production Guard:** Red perimeter accent and modal confirmation before destructive commands (`rm -rf`, `drop database`, `reboot`) can hit production.

---

## Entry 03. Parallel Swarm Triumph: Core, Vault, Network & Plugins (105/105 Tests)

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 14:15 — 14:40 (~25 minutes)
</span>

Rather than sequential development (waiting weeks for a database before touching network code), we launched 4 specialized subagents simultaneously:
- One agent implemented Drift/SQLCipher encryption and Argon2id KDF in `storage_vault`.
- The second parsed OpenSSH wire formats, PTY streams, and SFTP channels in `ssh_network_core`.
- The third secured the plugin sandbox against Zip Slip attacks in `desktop_plugin_sdk`.

Three bugs were caught immediately by strict unit tests:
* **BUG-001 (Archive package quirk in SDK):** The latest `archive` package lacked `entry.isDirectory`. Handled via `!entry.isFile`.
* **BUG-002 (Unmodifiable memory in Vault):** `cryptography` returned `UnmodifiableUint8ListView` upon `extractBytes()`, throwing an error during zeroization. Fixed by handling view wrappers and zeroing only mutable allocations.
* **BUG-003 (dartssh2 key parsing & ECDSA):** `dartssh2` rejected empty passphrases unless strictly passed as `null`. Added OpenSSH wire-format header parsers for ECDSA curves.

**Outcome:** All 105 unit tests passed with 100% green status, `dart analyze` reported 0 errors, and the monorepo foundation was validated. Next stop: UI rendering!
