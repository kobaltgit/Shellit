---
title: "Act XVI: Console Aesthetics for Linux Power Users — Custom Typography, Nerd Fonts Cascade, and Kitty Graphics Architecture"
description: "How we implemented configurable terminal fonts with a resilient Nerd Fonts fallback stack (U+E000..U+F8FF), engineered a streaming APC filter for Kitty Graphics Protocol image rendering in yazi, and safeguarded the isolated cursor overlay from layer conflicts."
actNumber: 16
period: "October 11, 2026, 01:25 — 02:15"
pubDate: 2026-10-11
readingTime: "8 min"
stage: "v0.9.5 Custom Typography & Kitty Graphics"
relatedBugs: ["BUG-057"]
tags: ["typography", "nerd-fonts", "kitty-graphics", "yazi", "chafa", "terminal-ui", "bug-057", "apc", "stream-filter"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Following the resolution of Issue #1 and release v0.9.4, we focused on what truly transforms a terminal into a welcoming workspace for developers — typography, Nerd Fonts icons, and inline graphics rendering. In this act, we established a multi-layered font fallback cascade, developed a streaming parser for Kitty Graphics Protocol that strips base64 payloads before reaching xterm.dart, and positioned image canvases safely below our isolated cursor overlay.
</div>

## Entry 64. Console Aesthetics for Linux Power Users: Custom Fonts, Nerd Fonts Cascade, and Kitty Graphics Architecture

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: October 11, 2026, 01:25 — 02:15 (~50 minutes)
</span>

### 1. Motivation: Giving the Terminal Polish & Visual Previews

Following the successful resolution of Issue #1 and release v0.9.4, we turned our attention to the user experience refinements shared during our Arch Linux + Hyprland test run. Reliably multiplexing sessions is essential, but feeling completely at home in the console is what elevates a developer tool.

Modern terminal utilities (`yazi`, `eza`, `starship`, `bat`, `fzf`) rely heavily on extended Unicode codepoints and the private Nerd Fonts range (`U+E000..U+F8FF`): folder glyphs 📁, file indicators 📄, language symbols, and git branch chevrons. Until now, Shellit relied on a standard monospace stack. If a user had their favorite `JetBrainsMono Nerd Font` or `FiraCode Nerd Font` installed, the terminal lacked a configurable selector, and glyphs in TUI file managers would either render as missing boxes or misalign cell grids.

Furthermore, in-terminal graphics rendering via the **Kitty Graphics Protocol** (for live image previews in `yazi` and `chafa`) has long been a dream feature for Linux power users.

### 2. Constraints & Edge Cases: xterm.dart APC Sequences & Cursor Z-Index

We enforced strict architectural invariants before writing code:
1. **Zero Base64 Bleed into the Text Buffer:** The underlying `xterm.dart` emulator does not recognize Kitty graphics APC sequences (`\x1b_G ... \x1b\`). If passed into `_terminal.write()`, the emulator treats the stream as raw text, flooding the terminal with tens of kilobytes of unreadable base64 strings.
2. **Preserving the Isolated Cursor Overlay (BUG-052):** In release v0.9.3, we decoupled the blinking cursor into `TerminalCursorOverlay` wrapped in a `RepaintBoundary` for 0% idle CPU usage. In-terminal graphics must never obscure or interfere with the cursor: the cursor overlay must render strictly *on top of* active image canvases in `yazi`.
3. **Preserving Prompt Markers (OSC 133):** The `22px` left gutter margin for command status indicators must remain completely intact.

### 3. Engineering Decisions: Multi-Layer Stream Filtering & Typography Cascade

We engineered the solution across three coordinated layers:

1. **Font Settings & Cascade Fallback:**
   - Established `terminalFontFamilyProvider` and a resilient fallback stack `kTerminalFontFallbacks` (`JetBrainsMono Nerd Font`, `Symbols Nerd Font Mono`, `Nerd Font Symbols`, `monospace`). If a glyph is missing in the primary typeface, Flutter transparently resolves it from system Nerd Fonts without distorting cell widths.
   - Enhanced `TerminalSettingsCard` with a dropdown selector featuring top developer typefaces (`JetBrains Mono`, `JetBrainsMono Nerd Font`, `Fira Code`, `FiraCode Nerd Font`, `Cascadia Code`), arbitrary system font input (`Custom...`), and a live preview card with icons `📁 📄  [✓] 🚀`. Selections persist directly to encrypted vault storage.
2. **Streaming APC Filter (`KittyGraphicsStreamFilter`):**
   - Hooked `preWriteFilter` into `TerminalStreamCoalescer`. The filter intercepts streaming terminal bytes, extracts APC commands `\x1b_G ... \x1b\` and `\x1b_G ... \x07`, decodes multi-chunk transfers (`m=1`/`m=0`), and passes clean text downstream to `xterm.dart`.
3. **Image Texture Registry & `TerminalGraphicsOverlay`:**
   - `TerminalGraphicsRegistry` decodes PNG/RGBA payloads via `ui.instantiateImageCodec`, binds placements to grid cells (column, row, cell dimensions), and handles memory disposal on deletion (`a=d`).
   - In `TerminalScreen`, `TerminalGraphicsOverlay` is mounted directly between `TerminalView` and `TerminalCursorOverlay`.

### 4. Verification & Status

- Unit and regression tests in `kitty_graphics_test.dart` verified stream extraction and multi-chunk assembly (7/7 tests passed).
- All 210 tests in `packages/terminal_ui` and 61 tests in `apps/shellit` passed cleanly (100% green).
- Full workspace analyzer `dart analyze --fatal-infos` reported zero issues.
- Defect `BUG-057` resolved, prepared v0.9.5 release.
