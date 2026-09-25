---
title: "Act III: Sysadmin Powerhouse — SFTP, Splits & Flight Recorder"
description: "Dual-pane SFTP with octal 0755 permissions, automated OS icon detection, zero-latency asciinema session recording, 2x2 matrix tiling with broadcast input, and brand logo."
actNumber: 3
period: "September 18, 2026, 16:30 — 19:30"
pubDate: 2026-09-18
readingTime: "9 min"
stage: "v0.2.0 Power Features"
relatedBugs: ["BUG-008", "BUG-009", "BUG-010"]
tags: ["sftp", "splits", "matrix-2x2", "asciinema", "broadcast-input"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> With the baseline shell operational, the focus shifted to turning Shellit into an indispensable tool for systems engineering. In this act, we implement a full dual-pane SFTP suite, build an in-terminal flight recorder saving sessions to asciinema v2 without PTY frame drops, deliver 2x2 matrix tiling with synchronized keyboard broadcasting, and finalize Shellit's neon identity.
</div>

## Entry 10. Pro Dual-Pane SFTP: Octal Permissions & Drag-and-Drop

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 16:30 — 17:00 (~30 minutes)
</span>

File management in terminal workflows should never be confined to cramped modal popups:
- Left pane: Local file system; Right pane: Remote SFTP tree.
- Drag-and-drop transfers, right-click context menus (folder creation, deletion, downloads), and an asynchronous background transfer queue with real-time speed metrics.
- **Interactive Permissions Matrix:** Visual UNIX permission editor (`chmod 0755`, `0644`) with checkboxes for User, Group, and Others. No more mental octal math.

---

## Entries 11–13. The Flight Recorder: asciinema «● REC» Without PTY Stalls

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 17:00 — 18:00 (~60 minutes)
</span>

Post-mortem investigations require knowing precisely what happened on screen leading up to an incident.

We engineered an integrated session recorder outputting directly to the open **asciinema v2 (`.cast`)** standard:
- Sleek `● REC` button with active pulse in the terminal header.
- Automated recording policy for servers marked with the `PROD` tag: every byte is logged to disk from the moment the socket opens.
- **Architectural Challenge:** Writing raw byte streams and microsecond timestamps cannot block the PTY pipeline. We isolated timestamp extraction into a non-blocking ring buffer. The terminal maintains a locked 60 FPS even during massive multi-megabyte `cat` bursts.
- Generated `.cast` archives can be played in asciinema players or shared with teammates during incident reviews.

---

## Entries 14–17. 2x2 Matrix Splits, Broadcast Input & Neon Brand Identity

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 18, 2026, 18:00 — 19:30 (~90 minutes)
</span>

Cluster maintenance demands unified visibility:
- **Matrix Multiplexer:** Flexible viewport splitting into vertical, horizontal, and **2x2 grids (four independent live shells within a single tab)**.
- **Broadcast Input:** Synchronized keyboard distribution. Activating broadcast pipes every keystroke concurrently across all four terminals. Checking `systemctl status nginx` or pulling package upgrades across a server pool completes in seconds.
- **Tab Drag-and-Drop:** Seamlessly pull tabs into splits or detach them back into dedicated tabs.
- **Brand Identity:** Designed Shellit's signature neon-glow vector monogram, produced multi-resolution `.ico` assets for Windows, and packaged the release milestone.
