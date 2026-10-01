---
title: "Act XIII: Mobile Resilience & Cryptographic Hygiene — Resolving Post-Sync Key Decryption & Streamlining Android UX"
description: "Post-mortem analysis of BUG-051: why vault synchronization stumbled upon empty private keys, how continuous socket pings triggered Fail2ban, why desktop AI settings were pruned on mobile, and how terminal touch ergonomics were refined."
actNumber: 13
period: "October 1, 2026, 15:00 — 17:30"
pubDate: 2026-10-01
readingTime: "9 min"
stage: "v0.9.2 Mobile Resilience & Ergonomics"
relatedBugs: ["BUG-051"]
tags: ["android", "mobile", "sync", "crypto", "security", "fail2ban", "ergonomics", "ux", "v0.9.2"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Following the introduction of end-to-end encrypted vault sync and semantic shell integration, our Android mobile client met the harsh realities of real-world field deployment. Connecting to newly synced hosts abruptly failed with authentication abort errors, persistent background TCP pings triggered automated firewall defenses on sensitive hosts, and the settings screen was bogged down with desktop-only AI configuration panels. We executed a thorough cleanup: systematically overhauling the cryptographic pipeline, restoring lightweight clarity to mobile settings, and tuning touch ergonomics for real handheld usage.
</div>

## Entry 59. Mobile Maturity & Cryptographic Hygiene: Resolving Post-Sync Key Decryption & Refining the Android Experience

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: October 1, 2026, 15:00 — 17:30 (~2.5 hours)
</span>

### 1. Motivation: Field Testing on Mobile Hardware

I'll be honest: I don't spend my days memorizing the syntax of low-level cryptographic byte streams in Dart. My role as an architect is to keep sight of the bigger picture: how data originates on desktop, how it gets packaged into an encrypted payload, how it travels across the wire, and what happens when an engineer taps "Connect" from a smartphone while commuting or on-site.

Desktop vault synchronization worked like a charm: master password derivation, AES-GCM encryption, clean transfer. But once we deployed the build to an actual Android phone and pulled the synced vault database, anomalies surfaced immediately.

Hosts that connected effortlessly on the laptop refused connections on mobile: the terminal dropped before authentication with a generic `SSHAuthAbortError`. Worse, hosts with strict security policies began temporarily blacklisting the mobile device. And navigating to settings on a 5-inch screen revealed a bloated Gemini AI configuration card — a feature engineered for desktop workflows that had no place on mobile.

It became obvious that the mobile client required a disciplined overhaul and pruning of unnecessary overhead.

### 2. Technical Findings: Empty Buffers, Aggressive Pings & Host Key Duplicates

Our systematic investigation along the data pipeline uncovered four distinct defects:

1. **The Cryptographic Trap in `SyncManager`:**  
   When a host is configured with password authentication, its `encryptedPrivateKey` field in SQLite is empty (`Uint8List(0)`). During export serialization, the sync loop attempted to pass this empty byte buffer into AES-GCM decryption. The crypto engine threw an `ArgumentError`. Because of an overarching `try-catch` block, the exception halted the entire iteration: private key handling crashed, and the subsequent export of the server password (`encryptedPassphrase`) was silently bypassed! The passphrase remained encrypted under the desktop's local master key instead of the sync key, rendering it undecryptable on Android (`password = null`).

2. **Silent Failure in the Connection Controller:**  
   When `SessionConnectController` received `password == null`, instead of surfacing an authentication error to the user, it attempted to establish an SSH session with empty credentials. The remote server immediately dropped the socket, leaving the engineer bewildered.

3. **Socket Ping Aggression vs. Fail2ban:**  
   The background `PingMonitorNotifier` was firing raw TCP socket connects to port 22 every 15 seconds for every saved host. On hardened nodes protected by Fail2ban or connection rate limiters, repeatedly opening and resetting TCP connections without completing the SSH banner exchange mimics a port scan. The client was inadvertently triggering its own ban.

4. **Crash Risk on Duplicate `known_hosts`:**  
   In `findKnownHost`, query resolution concluded with `getSingleOrNull()`. If synchronization ever created duplicate entries for a single host identifier, the query crashed with an unhandled `StateError: Too many elements`.

### 3. Engineering Decisions: Systemic Hardening & Touch Ergonomics

We translated our findings into actionable engineering requirements:

1. **Decoupled Cryptographic Pipeline:**  
   In `SyncManager`, private key decryption is now strictly conditioned on `k.encryptedPrivateKey.isNotEmpty`. Passphrase export is fully isolated. Memory buffers (`rawPassBytes`) are explicitly zeroed out via `fillRange(0, length, 0)` in `finally` blocks.
2. **Safe Host Key Lookup:**  
   Added `..limit(1)` to `known_host_repository.dart` to guarantee fail-safe resolution even in the presence of accidental database duplicates.
3. **Transparent Diagnostic Feedback:**  
   `SessionConnectController` now immediately throws an explanatory exception when decryption fails, directing the user to re-enter credentials or refresh their sync session.
4. **Polite Network Profile:**  
   The aggressive 15-second background ping timer was removed on Android. The client performs a single gentle latency probe on startup, paired with a user-initiated native Pull-to-refresh (`RefreshIndicator`) gesture in the hosts list.
5. **Pruning Desktop Bloat:**  
   The entire AI and Gemini configuration card was cleanly hidden on mobile form factors (`SettingsScreen`), preserving interface speed and battery life.
6. **Handheld Ergonomics:**  
   - Added horizontal environment (`PROD`, `STAGE`, `DEV`) and folder filter chips in `MobileHostsView`.
   - Expanded `HostFormDialog` to responsive full width on mobile screens for comfortable thumb typing.
   - Enhanced `MobileAccessoryBar` with vital Unix keys (`:`, `_`, `$`, `&`, `PgUp`, `PgDn`, `ENTER`) and adjacent navigation arrows.
   - Streamlined terminal header height in landscape mode down to 36dp to maximize vertical screen real estate for terminal output.

### 4. Summary & Verification

- Resolved and verified issue `BUG-051`.
- Post-sync SSH connections on Android operate with 100% stability.
- Mobile UI stripped of desktop-only settings and tuned for single-handed touch usage.
- Built and validated release candidate APK `app-release.apk` (68.8 MB).
- Static analyzer reports 0 warnings, and 100% of monorepo unit tests pass cleanly (63 `storage_vault`, 150 `terminal_ui`, 61 `shellit`).
