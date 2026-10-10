---
title: "Act XV: First Field Crash-Test on Arch Linux — Fixing Omni-Search Split Tiling Freeze on Wayland & Integrating GitHub MCP"
description: "How the first public GitHub Issue #1 from an Arch Linux power user exposed an OpenGL/Wayland frame timeout during rapid Ctrl+K split layout switching, how GitHub MCP integration enabled real-time AI issue diagnosis, and how we streamlined Linux shell detection."
actNumber: 15
period: "October 10–11, 2026, 23:10 — 01:15"
pubDate: 2026-10-11
readingTime: "9 min"
stage: "v0.9.4 Linux Wayland & GTK OpenGL Stability"
relatedBugs: ["BUG-056"]
tags: ["linux", "wayland", "hyprland", "opengl", "gtk", "omni-search", "github-mcp", "bug-056", "splits", "local-shells"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> As Shellit reached beta stability, its most critical validation was confronting diverse real-world operating environments. Our first live crash test arrived from family: launching a fresh Shellit build on Arch Linux with the Hyprland Wayland compositor resulted in an OpenGL canvas lockup when rapidly switching split matrix layouts via the Ctrl+K Omni-search palette. We connected our development workspace directly to GitHub via the Model Context Protocol (MCP), dissected defect BUG-056, eliminated the OpenGL fence race condition, and refined Linux local shell discovery.
</div>

## Entry 63. First Field Crash-Test on Arch Linux: Investigating the Omni-Search Freeze & GitHub MCP Integration

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: October 10, 2026, 23:10 — October 11, 2026, 01:15 (~2 hours)
</span>

### 1. Motivation: A Family Bug Report from the Arch Linux Ecosystem

The most exacting and constructive testers are often family members, especially when they are passionate Linux power users. My son installed the latest build of Shellit onto his Arch Linux workstation running the Hyprland Wayland compositor, and shortly after opened our very first public GitHub Issue:

> *“[Bug]: Split layout freeze / OpenGL frame timeout via Omni-search Ctrl+K in Linux GTK/OpenGL”*

The reproduction step was succinct: summon the Omni-search palette via `Ctrl+K`, swiftly type a split layout command (such as `split 2x2` or `split horizontal`), and press `Enter`. If pressed rapidly or followed by a fast secondary keystroke, the terminal canvas froze entirely, outputting GTK warnings: `glXSwapBuffers timeout / eglSwapBuffers failure` and `Flutter engine frame request timed out waiting for OpenGL fence`.

In addition, he shared sharp ergonomic feedback from daily use:
1. When opening a local terminal from the welcome screen, the shell would sometimes launch in `sh` and sometimes in `bash`, even though the system's login shell was configured as `zsh`. The shell dropdown selector listed duplicate entries (`ZSH` and `ZSH`).
2. Custom Fonts: Standard monospace fonts without Nerd Font patches failed to render file glyphs when using modern CLI tools like `eza` or `starship`.
3. Future feature request: Terminal graphics protocols (Kitty Graphics / Sixel) for in-console image previews.

### 2. Connecting GitHub MCP & Investigating BUG-056

We first integrated our AI environment directly with GitHub via the Model Context Protocol (MCP). The assistant can now track repository issues, discussions, and pull requests in real time, respond to threads, and maintain issue lifecycles. We fetched Issue #1, logged `BUG-056` (P0) into our tracking system, and performed an architectural root-cause diagnosis.

Three interconnected factors caused the freeze:
1. **Cascading State Mutation During Modal Dismissal:**  
   In `omni_search_modal.dart`, submitting an action synchronously triggered `action.onSelect()`, which immediately mutated Riverpod state (`updateSplitLayout()`) before `Navigator.of(context).pop()`. In Wayland/OpenGL GTK environments, dismissing a popup window initiates graphics buffer synchronization. Simultaneously triggering a full layout rebuild caused conflicting surface redraws, provoking an OpenGL fence timeout.
2. **Subtree Teardown from `ValueKey` Over-Specification:**  
   In `shellit_app_shell.dart`, `SplitMatrixView` was keyed with `ValueKey('${tab.id}-${tab.splitLayout.name}')`. Because the layout name was embedded into the key, switching split modes destroyed the entire terminal widget subtree and rebuilt it from scratch rather than invoking standard `didUpdateWidget` lifecycle transitions.
3. **PTY Window Resize Bursts:**  
   Inside `terminal_screen.dart`, rapid layout recomputations triggered bursts of `onResize` callbacks (4–6 per frame), spamming resize control packets to the PTY socket.

### 3. Engineering Decisions: Graphic Pipeline Stabilization & Linux Shell Hygiene

We deployed comprehensive fixes across the codebase:
1. **Single-Shot Action Guard & Deferred Invocation:**  
   Introduced an atomic `_isExecutingAction` boolean flag in `OmniSearchModal`. On Enter, subsequent submissions are immediately rejected, focus is retracted, the modal dismisses via `Navigator.of(context).pop()`, and Riverpod state updates are deferred to the following frame using `WidgetsBinding.instance.addPostFrameCallback`.
2. **Stable Split Matrix Keying:**  
   Bound `SplitMatrixView` keys solely to the tab identifier: `ValueKey('split-${tab.id}')`. Transitioning between single view, horizontal/vertical splits, and 2x2 matrix now cleanly flows through `didUpdateWidget`, preserving terminal memory and controllers.
3. **Terminal Resize Memoization:**  
   Added `_safeResizeTerminal` with memoized `_lastSyncedCols` and `_lastSyncedRows`, eliminating redundant resize packets when dimensions have not changed.
4. **Symlink Resolution & Fallback Shell Discovery on Linux:**  
   Updated `LocalShellDetector` with `resolveSymbolicLinksSync()`. On `/usr-merge` systems like Arch Linux, `/bin/zsh` and `/usr/bin/zsh` canonicalize to the identical binary, removing duplicate entries. When launched from Wayland app drawers where `$SHELL` is unset, the detector reads the user's shell from `/etc/passwd` and applies clean priority: `user_shell > zsh > bash > fish > sh`.

### 4. Verification & Conclusion

- Resolved defect `BUG-056`, validated with an automated regression test in `omni_bar_shortcut_test.dart`.
- All 203 tests across `packages/terminal_ui` and 61 tests in `apps/shellit` passed cleanly.
- Added `.nojekyll` and cleaned up Astro frontmatter comments to safeguard GitHub Actions Pages builds.
- Registered backlog initiatives `IDEA-037` (Nerd Fonts & custom typography) and `IDEA-038` (Kitty/Sixel graphics protocols).
- Posted an exhaustive diagnostic report to GitHub Issue #1.
