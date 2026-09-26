---
title: "Act IX: Armor for Production Servers — Universal Command Guard & v0.8.6 Release"
description: "A deep audit of remote server protection: why the Production Guard toggle failed on default hosts, how Bash history bypassed keystroke interception via Up Arrow, xterm screen buffer inspection, protecting nano/vim editors, and the v0.8.6 release."
actNumber: 9
period: "September 26, 2026, 17:15 — 17:55"
pubDate: 2026-09-26
readingTime: "8 min"
stage: "v0.8.6 Universal Command Guard"
relatedBugs: ["BUG-037", "BUG-038", "BUG-039", "BUG-040", "BUG-041", "BUG-042"]
tags: ["security", "command-guard", "prod-guard", "xterm", "bash-history", "v0.8.6", "tui"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Hands-on testing on active infrastructure surfaced a contradiction: toggling "Production Command Guard" on a host configured in the default environment produced zero visual changes and failed to intercept dangerous commands. The investigation exposed a cascade of six vulnerabilities — from a critical bypass via Bash history (`Up Arrow` + `Enter`) to disrupted sessions in TUI editors like `nano` and `vim`. This sparked a comprehensive architectural refactor, establishing the Universal Command Guard and delivering release v0.8.6.
</div>

## Entry 47. Armor for Production Servers: Universal Command Guard, Taming Bash History, and Xterm Buffer X-Ray

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 26, 2026, 17:45 (~40 minutes)
</span>

### 1. The Trigger: When a Protection Toggle Clicks into the Void

During real-world dogfooding of Shellit, I opened the edit modal for one of our working servers assigned to the default environment (`defaultEnv`), scrolled down to the settings, and enabled the toggle: **"Production Command Guard"**.

The intent seemed crystal clear: I explicitly instructed the client to guard this host against destructive mistakes. I saved the host, initiated the SSH session, the terminal connected... and nothing changed. No alerting border, no warning banner, no command interception. I typed a destructive command — and it was dispatched directly to the remote server without resistance.

The immediate feedback to the AI was unambiguous:  
> *"audit the prod guard implementation"*  
> *"I see zero visual difference, in addition to the bugs you discovered"*  
> *"record all discovered bugs! then we will discuss the plan"*  
> *"we need to explain this in the toggle subtitle. Also, explain to me what selecting items from this environment dropdown even affects?"*

---

### 2. The Blind Spots: A Disconnected Switch and a Cascade of Vulnerabilities

Digging beneath the surface revealed that this was far more than an isolated visual oversight. It was a chain of 6 interconnected architectural and ergonomic vulnerabilities:

1. **Disconnected Environment Logic (`BUG-037`):** The logic inside `ProdGuardBorder` and the keystroke interceptor in `terminal_screen.dart` strictly checked `host.environment == HostEnvironment.production`. For hosts configured as `defaultEnv`, `staging`, or `development`, the protection switch was completely dead code — saved to the encrypted database, but completely ignored by the active terminal screen.
2. **Fatal History Bypass (`BUG-038`, P0 Blocker):** The terminal's character accumulator `_commandLineBuffer` gathered printable keystrokes while discarding ANSI escape sequences. When a user pressed `Up Arrow` to cycle back through Bash history to a previous command such as `rm -rf /var/cache/*`, `_commandLineBuffer` remained completely empty! Pressing `Enter` dispatched the dangerous command straight to the SSH channel without triggering `DangerousCommandChecker` or the confirmation modal.
3. **Regex Holes & Utility Blind Spots (`BUG-039`):** The pattern matcher resided in the presentation layer `terminal_ui` instead of the domain core and tested for `\brm\s+`. Commands using absolute paths (`/bin/rm`), reordered flags (`rm -f -r`), or critical destructive tools (`wipefs`, `truncate -s 0`, `systemctl poweroff/reboot`, `chmod -R 777`) slipped right through.
4. **Disruptions Inside nano and vim (`BUG-040`):** In full-screen TUI editors, pressing `Enter` continued to be parsed as shell commands. If a config line contained a matching substring, the confirmation dialog popped up, and pressing Cancel sent a `Ctrl+C` (`\x03`) interrupt that broke the editor session.
5. **Divergent MCP AI Gateway Logic (`BUG-041`):** The MCP server gateway for external AI agents used an ad-hoc substring check `lower.contains('rm -rf')`, completely out of sync with terminal safety checks.
6. **Zero Hardcoded Strings Violation & Lack of Tab Context (`BUG-042`):** Warning banners were hardcoded in English, and open terminal tabs lacked visual indicators of their target environment or active guard status.

---

### 3. Architectural Solutions & Implementation

Resolving these issues demanded a unified overhaul across multiple layers:

#### 1. Universal Command Guard & Color Distinction
We expanded "Prod Guard" into a comprehensive **Universal Command Guard**:
- On servers declared as **Production** (`HostEnvironment.production`), destructive command protection is always active by default, framed with a vibrant red safety border (2.5px, `#FF3333`) and a top banner `[⚠️ PRODUCTION ENVIRONMENT]`.
- On servers in any other environment (`defaultEnv`, `staging`, `development`) where the user explicitly turned on the Command Guard toggle, the terminal renders a distinctive amber warning border (2.0px, `#FFB020`) and top banner `[🛡️ COMMAND GUARD ACTIVE]`.
- In `HostFormDialog`, the toggle is renamed to "Command Guard (Destructive Protection)" and features a dynamic subtitle explaining that Production hosts are always guarded automatically, while non-production hosts can be guarded on demand.

#### 2. Xterm Screen Buffer X-Ray & Shell Prompt Stripping
Rather than attempting complex ANSI cursor position tracking inside `_commandLineBuffer`, upon pressing `Enter` the terminal takes a direct snapshot of the active screen line:
```dart
final screenLine = _terminal.buffer.lines[_terminal.buffer.cursorY].toString();
final candidate = DangerousCommandChecker.cleanPromptAndExtractCommand(screenLine);
```
The new static helper `cleanPromptAndExtractCommand` intelligently strips arbitrary shell prompts (`user@host:~$ `, `root@srv:~# `, `(venv) [user@host /var]$ `), isolating the candidate command. If the candidate contains destructive actions, input is intercepted and the confirmation modal is triggered.

#### 3. Respecting Alternate Screen Buffers (TUI Apps)
Full-screen terminal applications (`vim`, `nano`, `htop`, `less`) transition xterm into an alternate screen buffer (`\x1b[?1049h`). Using `xterm.dart`'s native property `_terminal.isUsingAltBuffer`, we placed an early exit at the head of the input handler:
```dart
if (_terminal.isUsingAltBuffer) return;
```
Inside TUI editors, the command interceptor steps aside, allowing frictionless line breaks and text editing.

#### 4. Domain Core Migration & MCP Gateway Alignment
`DangerousCommandChecker` was relocated to `packages/core_foundation/lib/src/security/dangerous_command_checker.dart`. Patterns now support binary paths `(?:[^\s]*\/)?`, arbitrary flag order, and a comprehensive roster of destructive system commands (`wipefs`, `truncate`, `dd`, `mkfs`, `systemctl`, `init 0`, `chmod -R`). The identical validator is wired into the MCP Server Gateway.

#### 5. Tab Badges & Complete Localization
Terminal tab headers in `top_bar_tabs.dart` now display color-coded environment chips (`PROD` red, `STAGE` amber, `DEV` blue) alongside an active `[🛡️ GUARD]` badge. All UI strings are extracted into `context.tr('prod_guard.*')` with full Russian and English translations.

---

### 4. The Outcome: Release v0.8.6

- All 6 issues (`BUG-037` through `BUG-042`) are marked as `RESOLVED`.
- 48 domain tests and 9 regression UI tests established.
- 100% green test pass across all modules:
  - `core_foundation`: 27/27 passed.
  - `terminal_ui`: 126/126 passed.
  - `desktop_plugin_sdk`: 62/62 passed.
  - `apps/shellit`: 61/61 passed.
- Static analysis with `flutter analyze` completed with **0 issues found**.
- Version officially bumped to **v0.8.6**.

Server protection in Shellit is now intuitive, visually unmistakable, resilient against history bypasses, and unobtrusive during daily configuration workflows.
