---
title: "Act IV: Zero-Knowledge — Self-Hosted E2EE & Android Renaissance"
description: "Rejecting proprietary clouds: building a self-hosted Zero-Knowledge E2EE relay for VPS, honest Argon2id master-password rotation, IndexedStack GlobalKey traps, and Android touch bar."
actNumber: 4
period: "September 18, 2026, 19:30 — September 19, 2026, 03:40"
pubDate: 2026-09-18
readingTime: "10 min"
stage: "v0.3.0 — v0.6.0 Mobile & Sync"
relatedBugs: ["BUG-015", "BUG-018", "BUG-021"]
tags: ["e2ee", "sync", "argon2id", "android", "zero-knowledge"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Zero credentials surrendered to corporate cloud silos. In this act, Shellit introduces a lightweight self-hosted E2EE sync relay deployed on personal VPS nodes, eliminates a deceptive master-password rotation stub, fixes duplicate GlobalKeys inside Flutter's IndexedStack, and launches an Android client equipped with haptic terminal controls.
</div>

## Entry 18. Self-Hosted Zero-Knowledge E2EE Relay for VPS

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 19:30 — 20:30 (~60 minutes)
</span>

Commercial SSH tools enforce cloud lock-in: your connection inventories and metadata live on external vendor servers. We chose an unyielding **Zero-Knowledge** architecture:

- Built the lightweight `shellit-sync-server` Docker container (2-minute spin-up on any VPS).
- **Client-Side End-to-End Encryption (E2EE):** Everything (hosts, snippets, environment tags) is encrypted locally via **AES-256-GCM**. Encryption keys derive from a user sync passphrase via **Argon2id**.
- The VPS relay handles solely encrypted binary blobs. A compromised relay yields only random cipher text.
- Conflict resolution managed seamlessly via Vector Clocks.

---

## Entries 21–25. Argon2id Password Rotation (BUG-018) & The GlobalKey Pitfall

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 21:00 — 23:30 (~150 minutes)
</span>

Deep security regression testing revealed critical architectural discrepancies:

1. **BUG-018 (Fictitious Master Password Rotation):** In initial drafts, the change-password dialog displayed a success notification, but the underlying Drift/SQLCipher database retained the old encryption key! We engineered an authentic rotation routine: dumping plain records into volatile memory buffers, re-encrypting the database with fresh Argon2id salts, and cycling secure OS Keychain entries.
2. **BUG-021 (GlobalKey Collision in IndexedStack):** Switching between terminal sessions and SFTP tabs triggered a red Flutter screen: `Duplicate GlobalKey detected in widget tree`. The `IndexedStack` kept background widgets alive with identical generated keys. Replaced fragile global references with contextual `ValueKey(sessionId)`.

---

## Entries 26–28. The Mobile Renaissance: Shellit on Android

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 19, 2026, 01:00 — 03:40 (~160 minutes)
</span>

Mobile SSH apps often degrade into frustration without physical keys like `Ctrl`, `Esc`, `Tab`, and arrow keys.

We tailored Shellit for Android workflows:
- **Dedicated Touch Accessory Bar:** An ergonomic row positioned directly above the soft keyboard exposing `Esc`, `Tab`, `Ctrl`, `Alt`, history navigation arrows, pipes `|`, and tildes `~`.
- **Haptic Feedback:** Every tap produces a crisp mechanical vibration impulse, simulating physical key travel.
- **Desktop Hygiene:** Heavy Windows WebView2 and FFI desktop loaders are strictly decoupled via conditional imports, keeping the APK lean and lightning-fast.
