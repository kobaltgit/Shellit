---
title: "Act XI: The Mystery of the Swallowed Character — How Layout Switching Ate Keystrokes & How We Taught the Terminal to Listen"
description: "An engineering post-mortem on the missing first character after switching keyboard languages (Alt+Shift, Ctrl+Shift, Win+Space): how Win32 SC_KEYMENU intercepted inputs, why Flutter retained ghost modifiers in HardwareKeyboard, prioritizing printable glyphs, and restoring instant terminal response."
actNumber: 11
period: "September 30, 2026, 08:20 — 08:45"
pubDate: 2026-09-30
readingTime: "6 min"
stage: "v0.8.9 Responsive Keyboard & Layout Engine"
relatedBugs: ["BUG-045"]
tags: ["keyboard", "win32", "flutter", "xterm", "sc-keymenu", "ghost-modifiers", "layout-switching", "v0.8.9"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> A persistent ergonomic flaw in the Windows terminal emulator: whenever the keyboard input language was switched via system hotkeys (Alt+Shift, Ctrl+Shift, Win+Space), the first pressed letter was silently swallowed, requiring users to hit it twice. Investigation unmasked a two-fold platform conspiracy: the Win32 window transitioned into a modal system menu loop upon releasing Alt (SC_KEYMENU), while Flutter's HardwareKeyboard retained ghost modifier flags because the OS swallowed the key-up event. The bug was resolved across both layers, restoring instantaneous typing response.
</div>

## Entry 53. The Mystery of the Swallowed Character: How Layout Switching Ate Keystrokes & How We Taught the Terminal to Listen

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 30, 2026, 08:20 — 08:45 (~25 minutes)
</span>

### 1. The Symptom: Why Must the First Letter Be Pressed Twice?

Anyone who frequently switches between languages while working in a terminal on Windows knows that nagging micro-frustration: you press `Alt + Shift`, start typing your command or comments in Cyrillic, hit the first key — and nothing happens. You hit the key a second time — and only then does it begrudgingly appear on screen.

Initially, one might dismiss it as a clumsy finger or a mechanical slip. But when it reproduces consistently every single time the keyboard layout is toggled, it erodes the ergonomics of the application. In a terminal emulator, input latency and responsiveness must be pristine: if a key is pressed, the glyph must appear in the buffer. We set out to investigate the root cause: why the first character, and why specifically two keystrokes?

---

### 2. Under the Hood: A Conspiracy Between Win32 and Flutter

Deconstructing the event dispatch pipeline revealed a subtle interplay between Windows system mechanics and Flutter's input state:

#### Win32 System Menu Mode (`SC_KEYMENU`)
In the standard Win32 windowing architecture, tapping `Alt` triggers system menu activation (`WM_SYSCOMMAND` with `wParam == SC_KEYMENU`). In this mode, Windows treats the subsequent keystroke as a menu mnemonic accelerator. When the user pressed `Alt + Shift`, Windows entered this modal menu loop. When the user pressed the next character, Windows intercepted it, failed to find a matching menu mnemonic, silently dismissed menu mode, and **swallowed the keystroke** entirely! The character never even reached the application.

#### Ghost Modifiers in Flutter's `HardwareKeyboard`
Because Windows intercepts `Alt + Shift` and `Ctrl + Shift` globally at the OS level to switch input locales, it frequently omits sending the corresponding `WM_KEYUP` message to the application window. Consequently, Flutter's Dart memory continued to report `HardwareKeyboard.instance.isAltPressed == true` (a stuck ghost modifier).

#### Premature Shortcut Routing
`_handleTerminalKeyEvent` in `TerminalScreen` filtered modifier combinations: if `isCtrl` or `isAlt` was active, it ignored direct text input to let xterm shortcuts handle the key. With a ghost `isAlt == true`, the handler assumed the user was pressing an `Alt + [Key]` shortcut and discarded plain text emission!

#### Why the Second Keystroke Succeeded
During the first keystroke cycle, Flutter Engine reconciled its native modifier bitmask, clearing the ghost flag in `HardwareKeyboard`, while Windows exited its menu modal state. On the second keystroke, `isAlt` was cleanly `false`, and the character passed straight into the terminal buffer.

---

### 3. Remediation & Hardening (BUG-045)

We fixed the issue symmetrically at both layers — in the native C++ window runner and in Flutter's Dart event routing:

#### 1. Suppressing `SC_KEYMENU` in `win32_window.cpp`
In `Win32Window::MessageHandler`, we intercepted `WM_SYSCOMMAND`:
```cpp
case WM_SYSCOMMAND:
  // Prevent Alt tap from entering Windows system menu modal loop (SC_KEYMENU),
  // which would otherwise swallow or delay subsequent keyboard character input
  // after switching keyboard layouts (e.g. Alt+Shift).
  if (wparam == SC_KEYMENU) {
    return 0;
  }
  break;
```
Returning `0` prevents Windows from entering the Alt menu modal loop — a standard pattern employed by Windows Terminal and Alacritty.

#### 2. Prioritizing Printable Characters in `terminal_screen.dart`
We restructured key event dispatch:
1. Special navigation keys (`Enter`, `Tab`, `Backspace`, arrows, `Delete`) are unconditionally routed to xterm.
2. Whenever an event yields a valid printable character (Unicode runes $\ge 32$ and $\ne 127$), **text emission takes unconditional precedence**:
   - Non-ASCII runes (e.g., Cyrillic characters after `Ctrl+Shift` or `Alt+Shift`) are always treated as text input since terminal control sequences are strictly ASCII.
   - `isAlt` without `Ctrl` with a printable character indicates an unreleased `Alt` from layout switching, because holding Alt alone never produces printable characters on Windows. The character is emitted immediately.
   - Classic terminal control sequences (`Ctrl+C`, `Ctrl+D`, `Ctrl+Z`, `Ctrl+L`) and European AltGr combinations (`@`, `€`, `~`) remain 100% functional.

---

### 4. Regression Tests & Verification

New unit tests in `terminal_screen_test.dart` simulate unreleased `altLeft` and `controlLeft` states after layout switching, confirming that both Latin and Cyrillic characters reach the session input stream on the very first keystroke.

- Registered and resolved `BUG-045` (P1 / `VERIFIED`).
- All **128 of 128 tests** in `terminal_ui` passed with 100% success.
- Static analysis via `flutter analyze` confirmed 0 issues.

Keyboard layout switching is now completely seamless: every character appears instantaneously on the first keystroke across all language layouts.
