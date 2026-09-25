---
title: "Act V: Gateway to the Future — MCP Server, Gemini & ConPTY"
description: "Shellit learns to converse with AI: Model Context Protocol (MCP) integration for Cursor and Claude, Google Gemini BYOK snippet generation, and native Windows ConPTY local shells."
actNumber: 5
period: "September 19, 2026, 12:00 — 15:00"
pubDate: 2026-09-19
readingTime: "8 min"
stage: "v0.7.3 — v0.8.0 AI & Terminal"
relatedBugs: ["BUG-024", "BUG-026"]
tags: ["mcp", "gemini", "conpty", "cursor", "claude-desktop"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> A next-generation terminal must bridge the gap to artificial intelligence. In this act, Shellit becomes a Model Context Protocol (MCP) gateway—allowing external agents in Cursor and Claude to inspect server logs safely under Prod Guard oversight—integrates Google Gemini for intelligent script synthesis, and embraces native Windows ConPTY.
</div>

## Entry 29. The AI Bridge: Native Model Context Protocol (MCP) for Claude & Cursor

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 19, 2026, 12:00 — 13:00 (~60 minutes)
</span>

Engineers increasingly rely on autonomous AI agents in tools like Claude Desktop and Cursor IDE. But how can agents diagnose remote servers without exposing raw private keys to third-party clouds?

We built a native **Model Context Protocol (MCP)** server directly inside Shellit:
- Connects seamlessly to IDEs via standard JSON-RPC over `stdio`.
- Exposes vetted, secure tool endpoints: `shellit_list_servers`, `shellit_exec_command`, `shellit_get_terminal_buffer`, `shellit_read_remote_file`.
- **Prod Guard in Action:** If an AI model attempts a destructive command against a `PROD` node, Shellit intercepts execution and requires physical human confirmation. Private keys never leave the local encrypted Vault.

---

## Entry 31. AI Command Synthesizer: Google Gemini BYOK

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 19, 2026, 13:30 — 14:00 (~30 minutes)
</span>

How often do engineers hunt through StackOverflow for obscure `awk`, `sed`, `journalctl` time filters, or `lsof` network inspection arguments?

We embedded a smart assistant into the Snippets library:
- **BYOK (Bring Your Own Key):** Users supply their personal Google Gemini API key stored in the secure Keychain. No subscription markups.
- Dynamic model selection: rapid `gemini-1.5-flash` for instant one-liners or `gemini-1.5-pro` for deep multiline automation.
- The assistant auto-generates descriptive tags, flags breakdown, and documentation. A **1-Click Run** button shoots the synthesized command straight into the active terminal tab.

---

## Entry 33. Native ConPTY: Tabby-Grade Local Terminals

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 19, 2026, 14:15 — 14:45 (~30 minutes)
</span>

Most commercial SSH tools (including Termius) lack a first-class local shell, forcing users to toggle external PowerShell or WSL windows for local chores.

We integrated full native **Windows ConPTY** support:
- 1-click local tabs: PowerShell, CMD, or WSL environments (Ubuntu, Debian, Arch).
- Complete 24-bit TrueColor and mouse event passthrough for rich TUI apps (`htop`, `mc`, `fzf`).
- Consistent keyboard shortcuts, 2x2 matrix splits, and the Obsidian Dark visual hierarchy—now unified across local and remote workflows.
