---
title: "Act VI: Orbital Deployment — Web Portal, PocketBase & Cloudflare Tunnel"
description: "Astro and Starlight portal creation, cyberpunk /admin dashboard with Chart.js, vote abuse prevention via pb_hooks, and global rollout to shellit.top via Cloudflare Tunnel."
actNumber: 6
period: "September 20, 2026 — September 24, 2026, 17:00"
pubDate: 2026-09-24
readingTime: "10 min"
stage: "v0.8.3 Web & Cloud"
relatedBugs: ["BUG-030", "BUG-031", "BUG-033"]
tags: ["astro", "pocketbase", "cloudflare-tunnel", "admin-dashboard", "starlight"]
lang: "en"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Act Context:</strong> Transitioning from local development rigs to a globally accessible web presence. In this act, the official Shellit portal comes alive on Astro and Starlight, an engineering backend spins up on PocketBase with an `/admin` dashboard, roadmap ballot manipulation is neutralized via cryptographic tokens, and HAProxy port collisions are bypassed via Cloudflare Tunnel on the production domain shellit.top.
</div>

## Entries 41–46. The Web Portal: Astro, Starlight & Authentic Artifacts

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 22 — 23, 2026
</span>

Professional developer tools require a solid home on the internet. We avoided bloated CMS builders in favor of pure performance:

- **Astro + Starlight Foundation:** Instant static site compilation (30+ pages built under 8 seconds), scoring 100/100 on Google Lighthouse performance audits.
- **Uncompromising Termius Comparison:** Interactive comparison matrix detailing open-source sovereignty versus proprietary subscription barriers.
- **Real Screenshots, Zero Fakes:** We scrapped synthetic 3D renders in favor of 9 high-resolution authentic screen captures (Obsidian Dark palette, SFTP permissions modal, 2x2 matrix tiling, Keychain window).
- **Bilingual Knowledge Base:** English and Russian documentation indexed instantaneously client-side via Pagefind.

---

## Entries 50–52. The Admin Command Center & Roadmap Vote Hardening

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 24, 2026, 12:00 — 15:00 (~180 minutes)
</span>

For operational visibility and user telemetry, we introduced an embedded **PocketBase** backend:
- Cyberpunk `/admin` telemetry dashboard powered by Chart.js: privacy-respecting pageview analytics, release download counters, and incoming bug reports.
- **Roadmap Vote Manipulation (BUG-033):** The public roadmap permitted community feature voting. However, a naive client implementation allowed scripted `PATCH` requests to inflate vote counts indefinitely.
- **Defense-in-Depth:** Restricted direct record `PATCH` permissions across all PocketBase collections. Implemented a server-side `pb_hooks/vote.pb.js` hook: votes require secure POST validation matching `Voter Token + Salted IP Hash`. Duplicate attempts or incognito session resets trigger immediate `409 Conflict` rejections.

---

## Entry 39. Public Rollout: shellit.top Domain & Cloudflare Tunnel

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Timestamp: September 24, 2026, 15:15 — 16:10 (~55 minutes)
</span>

The deployment milestone required publishing the portal to our production node Senko under the official domain **`shellit.top`**.

Diagnostics uncovered server constraints:
- Ports **80 and 443** were claimed by an existing host-level HAProxy proxy service.
- Port **8090** was held by another containerized service.

Rather than altering host proxy templates, we deployed an isolated **Cloudflare Tunnel (`cloudflared`)** in Docker:
- Outbound encrypted HTTP/2 pipeline straight to Cloudflare Edge data centers with zero exposed inbound server ports.
- Automated SSL issuance, enterprise DDoS mitigation, and edge caching.
- **Same-Origin Harmony:** The single root domain `shellit.top` delivers Astro static pages, proxies `/api/` calls into PocketBase, and hosts `/admin/` without a single CORS complication.
