---
title: "Act VII: Battle of the Titans — Qwen vs Antigravity & v0.8.5 Triumph"
description: "The vibe-coding climax: when tests shine green but instincts demand verification. How Qwen executed a ruthless Red Team audit, exposed MitM vulnerabilities, and how we rebuilt the core on Fail-Closed and OpenSSH Randomart."
actNumber: 7
period: "September 24, 2026, 20:00 — September 25, 2026, 11:00"
pubDate: 2026-09-25
readingTime: "12 min"
stage: "v0.8.5 — v0.8.6 Hardened Citadel"
relatedBugs: ["BUG-034", "BUG-035", "BUG-036"]
tags: ["qwen", "antigravity", "security-audit", "fail-closed", "randomart", "seo"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> The defining engineering manifesto of Shellit. Antigravity reported 382 green unit tests and declared Zero-Trust readiness. But an architect's instinct demanded adversarial peer review: the codebase was unleashed upon the external model Qwen as an uncompromising Red Team auditor. What followed was a devastating takedown of subtle flaws, an overnight Fail-Closed refactoring, OpenSSH Randomart synthesis, and an official clean bill of health.
</div>

## Entry 43. Battle of the Titans: Pitting Qwen Against Antigravity

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 25, 2026, 01:35 — 01:50 (~15 minutes)
</span>

The most perilous trap in AI-assisted development is the *hallucination of competence*. An agent crafts immaculate architectural whitepapers, throws around authoritative jargon ("Zero-Trust sandbox", "RFC 9106 test vectors"), writes 382 tests, and every single one passes with flying colors.

Yet when you manage software through systems logic without manually auditing every byte array yourself, blind faith in a single AI model is unacceptable—especially in cryptography and network protocols.

I took the v0.8.4 release commit, exported critical network files, and instructed **Qwen** to attack them: *"Uncover all vulnerabilities, dissect the architecture under a microscope, and tell me the unvarnished truth."*

Qwen's response was surgical and merciless:

1. **Silent Verification Bypass (Fail-Open):** In `ssh_client_service.dart`, when the UI callback was omitted (`onVerifyHostKey == null`), the agent logged a warning and… returned `true`. Any UI error opened a gaping door for Man-in-the-Middle eavesdropping.
2. **Binary Hash & Naive UTF-8:** `dartssh2` provides key fingerprints as 32 raw bytes of SHA-256. The agent wrote `utf8.decode(fingerprint)`. In production, this causes either `FormatException` crashes or unreadable character gibberish instead of a valid Base64 string. Synthetic mock tests had passed only because the mock test generated UTF-8 strings itself!
3. **The Illusion of Memory Zeroization in Managed Dart:** Claiming "guaranteed zeroing" under Dart's garbage collector without native `dart:ffi` was an illusion—the GC leaves String copies lingering in heap memory.

---

## Entry 44. The Red Team Triumph: Rebuilding on Fail-Closed & v0.8.5 Release

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 25, 2026, 03:10 — 03:30 (~20 minutes)
</span>

We embraced the critique immediately, executing a disciplined overnight overhaul:

1. **Ironclad Fail-Closed:** Every unhandled exception, missing callback, or network failure now strictly returns `false`. Zero silent connections allowed.
2. **Canonical OpenSSH Base64 Digest:** Replaced flawed `utf8.decode` with standard OpenSSH SHA-256 Base64 fingerprint encoding (`SHA256:...`), eliminating crashes on raw bytes and ensuring seamless host verification.
3. **Memory Hygiene on Uint8List:** Discarded immutable strings for sensitive keys in favor of mutable byte buffers with explicit `.fillRange(0, length, 0)` wiping and `SecretKey.destroy()`.
4. **JSON-RPC 2.0 Plugin Boundaries:** Strict whitelist of allowed methods and sanitization of null bytes (`\x00`).

Upon deploying v0.8.5, I submitted the updated codebase back to Qwen for verification.

> **From Qwen's Updated Verdict:**  
> *«✅ Critical MitM Vulnerability: RESOLVED. onVerifyHostKey logic is implemented impeccably: canonical OpenSSH fingerprint encoding, strict Fail-Closed paradigm, safe exception interception.*  
> *⚖️ Updated Verdict: The project demonstrated exceptional reaction speed and fix quality. Technical implementation of foundational SSH security now meets modern engineering standards. Outstanding work.»*

---

## Entry 45. The Organic Quest: Long-Tail Strategy & v0.8.6

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 25, 2026, 10:15 — 10:45 (~30 minutes)
</span>

With the core fortified, Qwen performed an independent technical SEO audit:
- Eliminated 403 Forbidden crawler dead zones on parent directories using declarative 301 static redirects in Astro.
- Cleaned sitemaps to prevent crawling private `/admin/` and `/api/` endpoints.
- Deployed a Long-Tail content marketing strategy: authored 3 deep-dive technical guides in English and Russian (stopping `rm -rf` accidents, running a personal E2EE relay, and setting up MCP for Cursor/Claude).

**The Core Takeaway of the Chronicle:**  
The future of AI engineering lies in **adversarial multi-model collaboration** (Red Team vs Blue Team) governed by human architectural authority. 411 green tests, zero critical vulnerabilities, and total transparency with our users.
