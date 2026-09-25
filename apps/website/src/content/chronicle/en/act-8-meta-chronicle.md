---
title: "Act VIII: The Birth of the Web Chronicle — Emerging from Repository Shadows & The Devlog in the Mirror"
description: "The strategic decision: why Shellit brought its engineering devlog into the open and established a public chronicle on its website. Stepping out from Git folders, the Knuth-Plass algorithm, authentic dialogue spoilers, and responsive TOC."
actNumber: 8
period: "September 25, 2026, 18:00 — 19:30"
pubDate: 2026-09-25
readingTime: "9 min"
stage: "v0.8.6+ Web Chronicle & Typography"
relatedBugs: []
tags: ["web-chronicle", "open-source", "typography", "knuth-plass", "mcp-server", "vibe-coding"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> The meta-engineering loop of Shellit. The author makes a fundamental decision: do not hide the project's unique development story in private repository folders, but publish a dedicated, open devlog chronicle directly on the official website `shellit.top`. What followed was transforming raw repository logs into an exemplary web publication using an in-house Knuth-Plass typography server, collapsible spoilers with unscripted session transcripts, and dynamic desktop navigation.
</div>

## Entry 46. The Birth of the Web Chronicle: Emerging from Repository Shadows, the Knuth-Plass Algorithm, and the Devlog in the Mirror

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 25, 2026, 18:30 — 19:15 (~45 mins)
</span>

### 1. The Context: Why the Project Needs Its Own Public Blog on the Website

As Shellit approached version v0.8.6, successfully passing rigorous cryptographic security audits and establishing comprehensive technical documentation, we paused to reflect upon the path travelled.

From day one, our repository had housed a remarkable living document: `docs/CHRONICLE.md` — an authentic devlog spanning over 50 detailed entries and 2,600+ lines of engineering reality. It was never a dry git commit log or boilerplate release notes; it recorded the visceral experience of building an ambitious developer tool from scratch: vibe-coding without prior Dart syntax expertise, orchestrating a parallel multi-agent swarm, UI collisions with raw Windows network sockets, and an adversarial midnight security duel between Qwen and Antigravity.

Yet an essential question arose: **why should this valuable engineering journey remain tucked away in a `docs/` folder inside GitHub, accessible only to the handful who clone the repository?**

An open-source developer tool thrives on community trust. When engineers can examine not merely compiled binary releases, but the entire authentic backstory — every resolved bug, architectural crossroads, and security verification — their confidence in the software deepens substantially. Readers appreciate genuine engineering problem-solving over sanitized marketing brochures.

This led to a definitive decision: **Shellit must launch its own official blog and devlog chronicle directly on its website, `shellit.top`**.

---

### 2. The Concept: Not Corporate PR, but a Living Chronicle

We immediately dismissed the idea of a generic corporate blog filled with promotional fluff. We already had a genuine, compelling story.

We decided to bring the chronicle into the full public light:
1. Name the section with dignity and clarity: **"Chronicle"** (in English) and **"Хроника"** (in Russian). The word carries weight, history, and honesty.
2. Place the entry point prominently in the top header navigation bar (`Navbar`) right alongside "Documentation" and "Roadmap".
3. Design a modular architecture: rather than overwhelming the browser with an unwieldy 400KB single-page text dump, structure the journey into eight narrative **Acts (I–VIII)** with an interactive timeline, glowing cyberpunk rail, and cross-referenced tags.
4. Establish instructions for `AGENT_6_CHRONICLE_PUBLISHER` to ensure that new repository devlog entries translate seamlessly into web-ready chapters.

---

### 3. The First Preview: Rebellion Against the "Blind Wall of Text"

When the AI first assembled the chronicle web section, I loaded the browser preview — and the visual result was deeply discouraging.

Stretching across the display was an unending, monotonous "blind wall of text" — grey sentences drowning on a pitch-black canvas. It possessed neither air nor typographic rhythm, nor any trace of the fierce intensity that characterized our recent sprints.

The critique was immediate and constructive:
> *"This is a blind wall of text. We need to break it up somehow, highlight headings, paragraphs, etc. /plan"*  
> *"Shouldn't the text justification be fully justified across the width?"*

Thus began our meta-engineering journey: building a blog about building Shellit commanded the exact same obsessive craftsmanship as the underlying SSH client itself.

---

### 4. The Knuth-Plass Typography Algorithm: Mastering Full Justification

Full text justification (`text-align: justify`) has long been avoided in web design because naively applying it causes browsers to distort word spacing into unsightly "rivers of white space" that strain the eye.

Fortunately, I had an in-house tool ready: [mcp-typography-server](https://github.com/kobaltgit/mcp-typography-server), built upon the **Knuth-Plass** line-breaking algorithm (via the Justif library). Back in the 1970s while creating TeX, Donald Knuth demonstrated that book-quality typesetting relies not on crudely stretching spaces, but on calculating optimal global line breaks, hyphenation penalties, and micro-typographic density balance.

We brought these principles into the chronicle stylesheet:
- `text-align: justify; text-justify: inter-word;`
- Language-aware hyphenation rules (`hyphens: auto; -webkit-hyphens: auto;`)
- A disciplined, readable column width (`max-w-3xl`) with comfortable leading.
- An explicit attribution footer crediting the typography server.

The page transformed instantly: from a messy web transcript into the disciplined, elegant typesetting of a collector's engineering volume.

---

### 5. Authentic Transcripts: Collapsible Spoilers & Dynamic TOC

When the AI initially drafted synthetic conversations, I halted the impulse:
> *"Only take real dialogues from our conversations"*  
> *"No naming discussions, that is uninteresting, something more interesting"*  
> *"Put transcripts under spoilers with an initially closed state"*

We mined our raw `transcript.jsonl` session files for genuine moments: spinning up the agent swarm via `/grill-me`, the shock of dropped host passwords upon first Windows boot, the architectural confrontation over independent tabs, and the Zero-Knowledge crypto verification. We encapsulated them in `<DialogueSnippet />` using native HTML5 `<details>` / `<summary>` tags — collapsed by default so they never disrupt reading flow, yet expandable in a click for those seeking the unvarnished engineering truth.

For navigation, we re-architected `ChapterTOC.astro`:
> *"The table of contents on desktop should slide right upon page scroll. Keep mobile as is."*

On mobile devices, the table of contents rests compactly under the chapter header. On desktop screens, as the user scrolls past the title, the TOC smoothly glides into a floating right-docked panel with live scrollspy highlighting.

---

### 6. Accurate Metrics: 19 Hours to MVP

We also eliminated a neural hallucination from the website hero banner, which claimed the project took "7 days":

> *"Why 7 days? Where did you pull that number from? 19 hours to MVP"*

From creating an empty directory and committing the first line of code to delivering a working v0.1.0 release with SSH, SFTP, local terminal, and encryption took exactly **~19 hours** of concentrated effort. Subsequent days were dedicated to security hardening, audits, and ecosystem expansion. We locked this truthful metric into the site's HUD.

---

### 7. The Verdict

Deciding to bring the project's devlog into the public light gifted Shellit its own premier media hub.

At `https://shellit.top`, an interactive 8-Act chronicle is now live, with Act VIII completing the loop by recounting the creation of this very chronicle. Complete transparency of development, open-source rigor, academic typesetting, and honest dialogue with the developer community.
