---
title: "Act II: Hardware Detective & Console Awakening"
description: "Migration to xterm 4, unexpected Kernel-Power 41 crashes during C++ compilation, and the birth of Safe Build Protocol. First integration bugs: silent terminals and frozen cursors."
actNumber: 2
period: "September 18, 2026, 14:40 — 16:30"
pubDate: 2026-09-18
readingTime: "9 min"
stage: "v0.1.5 First Boot"
relatedBugs: ["BUG-004", "BUG-005", "BUG-006", "BUG-007"]
tags: ["hardware", "kernel-power", "xterm", "pty", "safe-build"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> The core packages were ready, but assembling them into the root desktop application triggered a hardware detective story: compiling native C++ plugins pushed the Ryzen 5 8400F into sudden Kernel-Power 41 shutdowns. This act establishes the Safe Build Protocol, navigates the xterm 4.0 breaking upgrade, and hunts down the first integration regressions.
</div>

## Entry 04. UI Architecture: Obsidian Dark, Live RTT Pulses & Prod Guard

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 14:40 — 15:00 (~20 minutes)
</span>

Most existing SSH clients suffer from two design shortcomings: dreary 1990s styling and unresponsive lists where you cannot tell if a machine is alive without waiting 30 seconds for a timeout.

UI implementation hit an immediate dependency roadblock (**BUG-004**): `xterm: ^3.7.0` broke under Dart 3.12. We migrated on the fly to `xterm: ^4.0.0`, restructuring the `TerminalView` widget and window resizing subscriptions (`terminal.onResize`).

Key ergonomic standards established:
- **Obsidian Dark Theme:** Deep graphite canvas (`#151824`) and card surfaces (`#1E2235`) preventing eye fatigue during late-night sessions.
- **Live RTT Ping Telemetry:** Visual pulse dot (<50ms green, <200ms yellow, offline grey) directly on server cards.
- **Prod Guard:** High-contrast red perimeter border around production shells with mandatory dialog confirmation for destructive commands (`rm -rf`, `drop database`, `shutdown`).
- **Mobile Touch Accessory Bar:** Sliding panel of special keys (`Esc`, `Tab`, `Ctrl`, `Alt`, arrows) positioned above the virtual keyboard with haptic feedback.

---

## Entry 05. The Hardware Detective: Kernel-Power 41 & Safe Build Protocol

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 15:00 — 15:15 (~15 minutes)
</span>

When uniting all modules into `apps/shellit`, triggering a native build caused the workstation to abruptly reboot without warning.

Anyone compiling cross-platform C++ desktop runners knows the reality: compilers saturate 100% of all CPU threads simultaneously, spiking VRM power phases.

Inspection of Windows Event Viewer revealed **Event ID 41 (Kernel-Power)** and Blue Screen **0x50 (PAGE_FAULT_IN_NONPAGED_AREA)**. The root cause was an aggressive "Ultimate Performance" Windows power plan forcing excessive voltage into the Ryzen 5 8400F during sudden multi-threaded bursts, combined with low C: drive swap space.

We instituted the **Safe Build Protocol**:
1. Switched Windows power management to "Balanced", eliminating unneeded silicon overvoltage.
2. Relocated build caches and temp buffers from C: to D: (>140 GB free space).
3. Verified DI containers and logic pipelines within lightweight Dart VM memory sandboxes before invoking native linkers.

System temperatures remained in the safe zone, 132 tests passed cleanly, and zero reboots occurred.

---

## Entries 07–09. Ghost Hunting: The Silent Terminal and Frozen Cursor

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 15:35 — 16:30 (~55 minutes)
</span>

The first live execution surfaced predictable integration friction:

1. **BUG-005 (Unsaved Host Records):** Saving a server closed the dialog, yet the catalog remained empty. Drift reactive queries weren't invalidating the Riverpod cache. Added targeted invalidation to `hostsStreamProvider`.
2. **BUG-006 (Silent Terminal & Frozen Cursor):** The terminal opened, but keystrokes produced no output and the cursor stayed still. The PTY stream bridge was disconnected: `TerminalView` listened to input, but the `session.output` stream was unattached to `terminal.onOutput`. Wired the bidirectional pipe.
3. **BUG-007 (The Slammed Door Effect):** Navigating back to the server list destroyed the active session, dropping SSH sockets. Replaced naive `Navigator.push` with a persistent session tab stack maintaining background TCP channels.
