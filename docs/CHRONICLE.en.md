# Shellit Development Chronicle: Author's Devlog

<p align="center">
  <strong>English</strong> | <a href="CHRONICLE.md">Русский</a>
</p>

*Honest vibe-coding without syntax memorization, systematic prompt engineering and architectural direction for AI, deep-dives into engineering decisions, and a real-time record of overcoming bugs.*

> ⚡ **Shellit Development Velocity & Milestones (From Concept to Production):**
> - **Project Kickoff:** September 18, 2026, 13:00 (Blank folder, pure idea)
> - **First Cross-Platform Release v0.1.0:** September 18, 2026, 18:17 (**5 hours 17 minutes**)
> - **E2EE Cloud Sync & Keychain v0.3.0:** September 18, 2026, 20:46 (**7 hours 46 minutes**)
> - **Plugin Ecosystem & Docker Monitor v0.4.0:** September 18, 2026, 22:11 (**9 hours 11 minutes**)
> - **Language Plugins & Zero Hardcoded Strings v0.5.0:** September 19, 2026, 00:31 (**11 hours 31 minutes**)
> - **Android Mobile Release with Touch Accessory Bar v0.6.0:** September 19, 2026, 03:35 (**14 hours 35 minutes**)
> - **MCP Server for AI & Gemini Assistant v0.7.3:** September 19, 2026, 13:15 (**Under 24 hours total**)
> - **ConPTY Local Terminal (Phase 14):** September 19, 2026, 13:45 (**24 hours 45 minutes from first file**)
>
> ⏱️ *Net Active Working Time:* **~19 hours** (including a 4-hour night rest).  
> 🚀 *Average Feature Implementation & Bugfix Cycle:* **25–35 minutes**.  
> 🛡️ *Quality Metrics:* 34 completed milestones, 24 logged & resolved bugs, 133+ green unit/widget tests, 0 analyzer issues.

---

## Entry 00. Inception: Why Termius Left Room for Something Better

*Time: September 18, 2026, 13:00 — 13:25 (~25 minutes)*

To be completely honest: I am not a syntax-heavy programmer, nor do I spend hours manually typing out boilerplate classes and nested brackets. My core expertise is in product vision, systems architecture, user workflows, and ergonomic design.

When state-of-the-art AI models emerged—capable of turning rigorous specifications into robust, production-grade code—it felt like a paradigm shift. The friction between conceiving a clean system in your head and running a tangible desktop binary melted away. The secret lies in disciplined architectural direction: clearly structuring domain models, establishing contracts, and steering the swarm as a principal architect.

The idea for **Shellit** emerged from a straightforward daily frustration. Anyone managing remote infrastructure, self-hosted homelabs, or cloud VPS clusters inevitably relies on an SSH client.

I spent considerable time evaluating Termius and similar commercial utilities. They look polished, but everyday operations expose clear limitations:
1. **Static, Unresponsive Host Cards:** You open a catalog of thirty servers, and they are all identically inert. Is host B down? Has latency spiked to 500ms? Did you inadvertently tap a production instance instead of a staging sandbox? There is zero immediate visual feedback.
2. **Rigid View Options:** You are forced into a flat grid. Once you exceed 50+ servers, endless scrolling becomes tedious. You need a dense tabular view and a clean folder hierarchy.
3. **Closed Ecosystem:** Zero user extensibility. If you need a lightweight Docker container monitor alongside your console, you must switch back to the shell and manually hammer `docker ps`.

I sat down, mapped the workflow, captured UI references to borrow the strongest ergonomic concepts (collapsible sidebar, responsive cards, clean top bar), and deliberately discarded blind cloning.

Thus the product vision crystallized: an independent, high-velocity developer hub featuring live host telemetry right on the card, safeguards against destructive commands in production, matrix tiling splits, an Omni-Bar (`Ctrl+K`), and an open desktop plugin runtime.

---

## Entry 01. Starting with Contracts Instead of Rushing Code

*Time: September 18, 2026, 13:25 — 13:45 (~20 minutes)*

The greatest pitfall when collaborating with AI is asking: *"Build me a pretty terminal app right now!"*  
The inevitable outcome is a monolithic 2,000-line spaghetti file where even the LLM loses its bearings after two iterations, and any attempt to plug in encrypted persistence breaks the whole build.

To guarantee modularity, we laid down strict monorepo rules on day one:
- **Partitioned into isolated packages:** Encrypted database (`storage_vault`), SSH networking (`ssh_network_core`), terminal rendering (`terminal_ui`), and desktop extensions (`desktop_plugin_sdk`).
- **Unified strictly through domain abstractions (`core_foundation`):** Domain entities, logger contracts, and Result/Failure types live in a zero-dependency package. Now specialized subagents can work in parallel without risk—network engineers cannot inadvertently touch SQL tables, and UI contributors cannot weaken AES-256 routines.
- **Set up a live Bug Tracker and Idea Backlog:** Every anomaly found is immediately registered in `docs/BUGS_AND_ISSUES.md`, and design improvements are tracked in `docs/IDEAS_AND_BACKLOG.md`.

With foundation rules locked in, we proceeded to scaffold `core_foundation` and spin up parallel development streams.

---

## Entry 02. The Architecture Interview (/grill-me) and Naming Shellit

*Time: September 18, 2026, 13:45 — 14:15 (~30 minutes)*

### 1. The Impetus: When AI Asks Uncomfortable Questions
Before writing low-level code, we subjected our design to an adversarial review. In vibe-coding, a concept often feels complete in your mind until implementation surfaces edge-cases. I prompted an interactive `/grill-me` session, instructing the AI to act not as a compliant coder, but as an inquisitive principal architect and product skeptic.

We dissected core user journeys, multi-pane layouts, and project positioning.

### 2. The Trap: Naming Dilemmas and Linguistic Pitfalls
Our first dilemma revolved around naming. The initial working title, "TermIt", seemed concise. However, package repository checks revealed that a lightweight Linux VTE terminal named `termit` had existed in official Debian and Ubuntu repos for over a decade. Colliding with an existing binary and polluting search results from day one was unacceptable.

We explored etymology. The Latin *termes* pointed directly to wood-boring termites (hardly an inspiring metaphor for software safeguarding SSH keys), while the Greek suffix *-itis* sounded medicinal, like an inflammation. Why bring negative connotations into our tool?

We pivoted to an identity that clicked immediately: **Shellit** (specifically with a lowercase 'i'). It is punchy, memorable, and a direct call to action: *"Shell it!"*. The brand was settled.

### 3. Decisions with AI: Tackling Architectural Crossroads
During the interview, we addressed the pain points where open-source terminals typically falter:

- **Dedicated Dual-Pane SFTP Tab:** File transfer is often bolted on as an afterthought in cramped dialogs. We committed to a first-class Termius-grade workspace: SFTP opens in its own tab with a dual-pane layout (local disk on the left, remote server on the right), drag-and-drop support, transfer queues, and a built-in remote config viewer.
- **2x2 Matrix Splits & Broadcast Input:** Splitting a tab vertically is common, but managing a server cluster requires more. We planned a responsive 2x2 grid with a Broadcast Input toggle, broadcasting keystrokes across all four consoles simultaneously—invaluable for rolling package updates or inspecting logs across a farm.
- **Live RTT Ping Telemetry on Host Cards:** Eliminating the "blind catalog" problem. Host cards should not be static gravestones. A lightweight background ICMP/TCP ping measures round-trip time, rendering a live millisecond indicator and a pulsing status dot (green <50ms, yellow <200ms, grey offline).
- **Production Guard against `rm -rf`:** When a server is tagged `PROD`, its terminal window receives an accent red border, and destructive commands (`rm -rf /`, `systemctl stop`, `reboot`, `drop database`) trigger a mandatory confirmation dialog. A lifesaver during late-night operational fatigue.

### 4. Outcome: Subagent Swarm Deployed
The architectural fog cleared completely. All four subagents were assigned distinct roles:
1. **Foundation & Vault Agent:** Drift/SQLCipher encrypted storage and domain interfaces.
2. **SSH Network Core Agent:** `dartssh2` transport, PTY streams, and SFTP pipes.
3. **Terminal UI Agent:** Flutter views, tiling multiplexer, tabs, and Obsidian Dark themes.
4. **Desktop Plugin SDK Agent:** Sandboxed WebView2 IPC bridge and manifest validators.

---

## Entry 03. Parallel Engineering Triumph: Core, Vault, Network & Plugins (105 of 105 Tests)

*Time: September 18, 2026, 14:15 — 14:40 (~25 minutes)*

### 1. The Impetus: Field Test for a Multi-Agent Swarm
With contracts in `core_foundation` established, we launched all four subagents in parallel. Traditional development handles these sequentially over weeks. Here:
- The storage subagent in `storage_vault` developed Drift/SQLCipher encryption, configured Argon2id KDF, and added secure memory zeroization for credentials;
- The networking subagent in `ssh_network_core` parsed OpenSSH wire formats, managed PTY streams, and handled SFTP channels;
- The plugin subagent in `desktop_plugin_sdk` hardened zip extraction against Zip Slip directory-traversal vulnerabilities.

### 2. Bottlenecks: Three Real-World Bugs
1. **BUG-001 (Archive Directory Flag in `desktop_plugin_sdk`):** While unzipping `.shell-plugin` packages, the code called `entry.isDirectory`. In the latest `archive` package version, this property was removed; directories are identified strictly by `!entry.isFile`. We patched the logic and added recursive directory tests.
2. **BUG-002 (Unmodifiable Memory in `storage_vault`):** Zeroizing decrypted keys in memory crashed with `Unsupported operation: The bytes are unmodifiable`. The `extractBytes()` method in package `cryptography` returned an `UnmodifiableUint8ListView`. We updated the crypto service to copy sensitive data into mutable byte buffers before zeroization.
3. **BUG-003 (Strict `dartssh2` Key Parsing & ECDSA):** `dartssh2` rejected unencrypted private keys if an empty string or default password was passed—it required an explicit `null`. Furthermore, modern OpenSSH ECDSA keys bury the curve descriptor inside wire base64 blobs. We implemented 4-byte header decoding and enforced strict `null` arguments for unencrypted keys.

### 3. Decisions with AI: Strict Verification over Assumptions
The key lesson learned: AI agents produce remarkably clean code when instructed not just to "implement a feature", but to "provide production implementation accompanied by edge-case unit tests proving correctness".

- `core_foundation`: All entities verified; log masking confirmed.
- `storage_vault`: Brute-force resistance, bad passwords, and schema migrations tested.
- `ssh_network_core`: Handled all key types (Ed25519, RSA, ECDSA) and connection drops.
- `desktop_plugin_sdk`: Validated manifests, package integrity, and filesystem confinement.

### 4. Outcome: 105 of 105 Green Tests
- **105 unit tests** passing across all core packages.
- `dart analyze` reports **0 warnings, 0 errors**.
- Architecture proved 100% stable, paving the way for Phase 2: graphical UI.

---

## Entry 04. The Shellit UI: Obsidian Dark, Live RTT Pulses, Dual-Pane SFTP & Prod Guard

*Time: September 18, 2026, 14:40 — 15:00 (~20 minutes)*

### 1. The Impetus: Moving Beyond 90s-Style Terminal Aesthetics
Once the core was locked in, we turned to visualization. I designed the interface strictly around user journeys and modern workspace ergonomics:
1. **Dull Aesthetics:** Most existing clients look like Windows 95 relics or garish neon palettes.
2. **Dead Host Lists:** Viewing thirty identical tiles without knowing which machines are reachable before clicking Connect is unacceptable.

### 2. Bottlenecks: Major Version Jump (`BUG-004`)
We initially targeted `xterm: ^3.7.0`. However, the current Flutter SDK and Dart 3.12 rejected this version due to dependency conflicts on pub.dev.

We migrated on the fly to `xterm: ^4.0.0`. Major updates break APIs: `TerminalView` was rewritten, constructor signatures changed, and resize subscription mechanics (`terminal.onResize`) were overhauled. The UI agent updated the screens, aligned event streams, and registered `BUG-004` as resolved.

### 3. Decisions with AI: Ergonomics in Detail
- **Obsidian Dark Palette:** Deep graphite backgrounds (`#151824`), elevated cards (`#1E2235`), subtle borders (`#2A2F4C`), and cyan accents. Terminal themes feature quick toggles for Dracula, Nord, OLED True Black, and Cyberpunk.
- **Live RTT Host Pulse:** Cards now render live latency dots: green pulse (<50ms), yellow (<200ms), and grey offline.
- **Prod Guard:** Tagging a host as `PROD` wraps the terminal in a conspicuous red border and intercepts hazardous commands (`rm -rf`, `reboot`, `shutdown`, `drop database`, fork-bombs) with a modal confirmation.
- **Dual-Pane SFTP & Matrix Splits:** Local directories on the left, remote server on the right, background task queue. Tiling supports up to 2x2 matrix splits with Broadcast Input mode.
- **Omni-Bar & Mobile Accessory Bar:** Fast fuzzy-finder via `Ctrl+K` / `Cmd+K`. On mobile screens, a dedicated touch accessory row (`Esc`, `Tab`, `Ctrl`, `Alt`, arrows) sits above the software keyboard with tactile HapticFeedback.

### 4. Outcome: 126 of 126 Green Tests
- 21 unit & widget tests covering UI logic.
- Total monorepo test suite expanded to **126 of 126 green tests**.
- `flutter analyze` clean with 0 warnings.

---

## Entry 05. Root App Assembly (apps/shellit), Hardware Power Anomalies & Safe Build Protocol

*Time: September 18, 2026, 15:00 — 15:15 (~15 minutes)*

### 1. The Impetus: When Native Compilation Stresses Hardware
With all packages verified, we proceeded to integrate them into the root runner `apps/shellit`. However, cross-platform builds with native C++ dependencies can spike multi-core CPUs to 100%, saturate memory, and trigger system reboots on aggressive power curves.

### 2. Bottlenecks: Hardware Diagnostics & Safe Build Protocol
Reviewing Windows Event Viewer revealed **Event ID 41 (Kernel-Power)** and bugchecks like **0x50 (PAGE_FAULT_IN_NONPAGED_AREA)** during heavy multi-threaded compiling. The combination of a Ryzen 5 8400F on an aggressive power profile, limited space on drive `C:`, and unbounded parallel compiler jobs caused instant voltage drops on the VRM.

We instituted the **Safe Build Protocol**:
1. Switched Windows power plan to **"Balanced"**, eliminating unstable voltage spikes.
2. Relocated build caches and compiler temporary buffers from `C:` to high-capacity drive `D:`.
3. Verified DI and application logic within the lightweight Dart VM test environment before triggering native release compilation.

System temperatures remained cool, fans remained quiet, and build stability achieved 100%.

### 3. Decisions with AI: Integrating the Monorepo
- Scaffolding `apps/shellit` for Windows, macOS, Linux, Android, and iOS.
- Central Riverpod DI container (`app_providers.dart`) binding all four packages via abstract interfaces.
- Implemented **Keychain**, **Tunnels**, **Plugins**, and **Settings** screens in Obsidian Dark.
- Wired `SessionConnectController` to fetch decrypted keys from vault and seamlessly spawn SSH or SFTP sessions.

### 4. Outcome: 132 of 132 Green Tests
- All 132 tests passed across the 6 monorepo projects.
- Static analyzer clean: **0 errors, 0 warnings**.

---

## Entry 06. Snippets Library, 1-Click Omni-Bar Execution & Encrypted Backups

*Time: September 18, 2026, 15:15 — 15:35 (~20 minutes)*

### 1. The Impetus: Eliminating Command-Line Repetition
Frequently typing repetitive operational commands (`docker logs -f --tail 100 app`, `systemctl restart nginx`) causes unnecessary fatigue. We wanted frequently used snippets accessible at a single click or searchable via `Ctrl+K`.

### 2. Bottlenecks: Active Tab Targeting & Zero-Knowledge Vault Backups
- Snippets must target the actively focused terminal tab, even in complex 2x2 split configurations.
- Backing up configurations in plain JSON leaks credentials. We required a military-grade encrypted backup format protected by a separate password.

### 3. Decisions with AI: Snippets & .shellit-vault
1. **`SnippetsScreen`:** Fast fuzzy search by title, tags, and command body; 1-click execution into the active PTY stream.
2. **Omni-Bar Integration:** Typing a snippet name in `Ctrl+K` immediately executes it in the current console.
3. **`VaultBackupService`:** Encrypted `.shellit-vault` archive format utilizing **Argon2id** key derivation and **AES-256-GCM** authenticated encryption with support for clean restores or non-destructive merging.
4. **Memory Hygiene:** Zeroization verified for all decrypted private key buffers.

### 4. Outcome: 133 Tests & Clean Windows Release
- 133 of 133 tests green.
- Windows Release compilation completed in 38 seconds without system load.
- Production binary ready at `apps/shellit/build/windows/x64/runner/Release/shellit.exe`.

---

## Entry 07. First Live Run & The Ghost Host Mystery

*Time: September 18, 2026, 15:35 — 15:55 (~20 minutes)*

### 1. The Impetus: Host Added, but Where Did It Go?
We launched the freshly compiled `shellit.exe`. The Obsidian Dark interface was responsive and sleek. I entered a test server, clicked "Save"... and the list remained blank. Restarting the application showed an empty catalog. In mock tests everything passed, but in the live environment data vanished.

### 2. Investigation: Three Hidden Traps
1. **In-Memory SQLite Provider:** In `app_providers.dart`, the database connection was defaulted to `VaultDatabaseConnection.inMemory()`. Data never reached disk.
2. **The Locked Vault Paradox:** `HostsRepository` enforced `if (!_securityContext.isUnlocked) return Result.error(VaultFailure.locked())`. On first launch, the user had not yet created a master password, so the vault was uninitialized, and writes were silently rejected.
3. **Silent Failure in UI:** `HostsNotifier.addHost` called repository save but ignored the returned `Result.error()`, failing without user notification.

### 3. Resolution: Frictionless Start & Persistent Disk Storage
- Pointed Drift SQLite to persistent storage via `path_provider` (`%APPDATA%/com.example/shellit/data/shellit_vault.db`).
- Added **Open Session Mode** (`ensureOpenSession()`): users can immediately add and manage servers without being forced into mandatory master password creation on first launch.
- Optional Master Encryption: clicking "Primary Vault (Open)" allows setting a master password at any time, re-encrypting records with Argon2id + AES-256-GCM.
- UI SnackBar error feedback and comprehensive integration test `host_persistence_test.dart`.

### 4. Outcome: Solid Persistence
Hosts persist reliably across reboots; release binary updated.

---

## Entry 08. The Silent Terminal Mystery: Unresponsive Keystrokes & Frozen Cursor

*Time: September 18, 2026, 15:55 — 16:15 (~20 minutes)*

### 1. The Impetus: SSH Connected, Window Open, but Complete Silence
Everything seemed ready: database persisted hosts, SSH established connections, and the welcome banner from remote Linux printed clearly in the terminal. But when typing on the physical keyboard:
- Zero response. Letters did not appear, commands failed to register, and Enter produced nothing.
- The cursor in the corner remained completely static: no blinking, no movement, just an unblinking rectangle.

### 2. Under the Hood: IME and Focus Clashes on Windows
Deep inspection of `xterm.dart 4.0` internals and Flutter Windows event handling revealed three underlying causes:

1. **Virtual Keyboard Trap (`hardwareKeyboardOnly: false`):**
   By default, `TerminalView` in `xterm 4.0` initialized in mobile mode, wrapping itself in `CustomTextEdit` waiting for input via `TextInputClient`. On Windows desktop, physical key presses ('l', 's', 'a', space) did not trigger `updateEditingValue`. Meanwhile, the default `keytab` map contained arrow keys and Enter, but omitted plain alphanumeric letters without modifier keys. Input was silently dropped.
2. **Missing Cursor Blinker in `xterm 4.0`:**
   During the rewrite for 4.0, `RenderTerminal` dropped its built-in ticker/cursor blink timer, drawing a single static box. Without active focus, it rendered an empty outline.
3. **Focus Hijacking by Root Listeners:**
   Root widgets listening for `Ctrl+K` had `canRequestFocus: true` enabled by default, seizing focus from the newly mounted terminal view.

### 3. Resolution: Hardware Input Router & Blinking Ticker
1. **Desktop Hardware Input:** Enabled `hardwareKeyboardOnly: isDesktop` for `TerminalView` and implemented `_handleTerminalKeyEvent`: regular characters (English, Cyrillic, numbers, symbols) stream directly into the PTY pipe, while special keys (Tab, Esc, arrows, Ctrl+C) resolve via keytab.
2. **550ms Blinking Cursor:** Added a periodic blink timer via `_terminal.setCursorVisibleMode()` and `notifyListeners()`, pausing blinking during active typing bursts.
3. **Explicit Focus Management:** Provided `TerminalScreen` with a dedicated `FocusNode` requesting focus on mount and click.
4. **Regression Tests (`BUG-007`):** Authored `terminal_screen_test.dart` verifying alphanumeric input, spaces, Backspace, Cyrillic strings (`echo привет`), and cursor ticks.

### 4. Outcome: 137 Tests & Responsive Terminal
All 137 tests passing; keystrokes register instantly, and the cursor pulses smoothly.

---

## Entry 09. The "Slammed Door" Effect: How We Taught Tabs to Live Forever

*Time: September 18, 2026, 16:15 — 16:35 (~20 minutes)*

### 1. The Impetus: When One Tab Hijacks the Entire Interface
Tabs in browsers and modern terminals are fundamental. You connect to Server A, open Server B, switch seamlessly between them, and browse the catalog to pick a third.

In Shellit, tapping "Connect" triggered the "slammed door" syndrome. The terminal opened, but the host catalog vanished. Clicking "Hosts", "Keychain", or "Settings" in the sidebar produced no result. There was no "+" button, no way to open SFTP separately, and the only escape was terminating the SSH session via the tab's close button.

Users must be able to keep 10 or 20 tabs open (production terminal, SFTP logs, staging database) while returning to the catalog in a single click without tearing down connections.

### 2. Under the Hood: Naive Rendering Traps
1. **Greedy `if (activeTab != null)`:** The view switch strictly checked:
   ```dart
   Widget _buildMainContent(SessionTab? activeTab) {
     if (activeTab != null) return TerminalScreen(...);
     // Catalog was rendered only when activeTab == null!
   }
   ```
2. **State Destruction on Switch:** Standard widget switching unmounted the previous screen (`dispose`), wiping terminal scrollback, cancelling stream subscriptions, and aborting in-flight SFTP transfers.
3. **Timestamp ID Collisions:** Generating tab IDs via `DateTime.now().millisecondsSinceEpoch` caused duplicate IDs during fast multi-connect scripts, causing closing one tab to kill both.

### 3. Decisions with AI: IndexedStack, Persistent Hosts Tab & Termius Ergonomics
- **State Preservation via `IndexedStack`:** Level 0 hosts the persistent catalog and sidebar screens; levels 1..N host active sessions (terminals, SFTP, matrix splits). Switching tabs takes 0ms: widgets remain in memory, buffers stay intact, and SFTP transfers continue uninterrupted.
- **Pinned "Hosts" Tab & `+` Button:** The top bar now features a permanent `[ 💻 Hosts ]` tab and a clean `+` button.
- **First-Class SFTP Tabs:** Dedicated teal folder icons and colored indicators. Each terminal header includes a `[ 📁 SFTP ]` button to open file transfer for the active host in an adjacent tab.
- **Monotonic Tab IDs:** Integrated a static counter `_tabCounter` to eliminate ID collisions.

### 4. Outcome: 141 Tests & Seamless Navigation
141 green tests; `BUG-008` marked resolved. Multi-tab workflows run smoothly without state loss.

---

## Entry 10. Enterprise Dual-Pane SFTP: Context Menus, The Invisible Blue Button & 0755 Chmod

*Time: September 18, 2026, 16:35 — 16:55 (~20 minutes)*

### 1. The Impetus: Moving from Basic Transfer to Real Usability
File transfer worked, but daily ergonomics were rough:
- No right-click context menu to rename, chmod, create folders, or delete logs.
- Selecting a local file presented an unlabelled blue rectangle at the bottom: an unreadable upload button where blue text blended invisibly into a blue background.
- Uploading a file did not trigger an automatic remote view refresh.

### 2. Bottlenecks: Color Mimicry & Nested Context Menus
1. **Invisible Button (Blue on Blue):** In Material 3, setting `backgroundColor: accentBlue` on `ElevatedButton` without explicitly assigning `foregroundColor` inherited the theme's blue default, rendering text invisible. Fixed by enforcing crisp white text.
2. **Double Context Menus:** Right-clicking a file triggered both the file menu and the parent directory menu simultaneously. Resolved by introducing `_itemRightClickHandled` to halt gesture bubbling.
3. **Crowded Directories:** If a folder contained 50 items, empty space for right-clicking was inaccessible. We added persistent `[📁+ New Directory]` and `[📄+ New File]` toolbar buttons and an 80px bottom scroll padding.
4. **Visual Chmod Matrix:** Built a 3x3 interactive permission checkbox matrix linked to an octal numeric input (`0755`, `0644`). Ticking boxes recalculates the mask in real time and vice versa.
5. **Real-time Auto-Refresh:** Tied panel `reload()` directly to transfer completion events (`onDone`).

### 3. Outcome: 147 Tests & Windows Release
Updated `ISftpSession` contracts, added `sftp_dialogs_test.dart`, resolved `BUG-009` and `BUG-010`, and verified 147 of 147 tests.

---

## Entry 11. Termius-Grade OS Icons: Automatic SSH Detection & Crisp Vector SVGs

*Time: September 18, 2026, 16:55 — 17:15 (~20 minutes)*

### 1. The Impetus: Why Manual OS Selection Is Obsolete
In modern tools, server cards immediately identify Ubuntu, Debian, Alpine, Arch, or Windows via distinctive brand emblems. In early Shellit builds, users were forced to choose from a manual dropdown during host creation.

Why should users manually specify the OS? When connecting over SSH, the client can query system identity in milliseconds and brand the card automatically.

### 2. Bottlenecks: Multiplexed Channels & Derivative Distros
1. **Background Discovery Without Shell Clutter:** Utilized `dartssh2` channel multiplexing: while the interactive PTY launches, an isolated exec channel runs:
   `cat /etc/os-release 2>/dev/null || uname -s 2>/dev/null`
2. **Derivative Distros Trap (`ID_LIKE`):** Rocky Linux and AlmaLinux initially misidentified as Fedora due to `ID_LIKE="rhel centos fedora"`. Refactored the parser to prioritize exact `ID=...` values before substring heuristics.
3. **Crisp Vector Graphics:** Integrated `flutter_svg: ^2.0.17` with brand badges for Ubuntu, Debian, Alpine, Arch, Fedora, CentOS, Rocky, AlmaLinux, Red Hat, FreeBSD, Raspberry Pi, macOS, Windows, and generic servers.

### 3. Outcome: 151 Tests & Zero Selector Overhead
Removed manual OS dropdowns; cards update automatically upon first connection. Total test count reached 151 (100% green).

---

## Entry 12. Flight Recorder for Servers: Live Audit Logs, Rotation & Asciinema (.cast)

*Time: September 18, 2026, 17:15 — 17:30 (~15 minutes)*

### 1. The Impetus: When Staging Breaks at Midnight
As an architect and regular user, I know the pain of midnight server failures. The sidebar `Logs` tab held a placeholder text message. When connections dropped or SFTP failed on permissions, where could you inspect the root cause?

Furthermore, when applying complex shell pipelines across remote hosts, you need a flight recorder: an exact session history without bloating the disk.

### 2. Bottlenecks: Secret Masking, Disk Quotas & Asciinema
1. **Zero Secret Leakage:** Enforced strict sanitization: private keys become `***[REDACTED_PRIVATE_KEY]***`, and tokens/passwords are masked automatically before writing to disk.
2. **Disk Quota Auto-Rotation:** Set a strict 5MB threshold per log file (`shellit.log` and archive `shellit.1.log`), capping total disk usage to 10MB maximum.
3. **Asciinema v2 (`.cast`) Recordings:** Instead of heavy video formats, terminal streams are recorded as timestamped JSON streams (`[0.125, "o", "ls -la\n"]`). A 20-minute session takes only 150–300 KB, with a companion `.log` text file for instant searching.
4. **Infinite Spinner Test Hangs:** In widget tests, `tester.pumpAndSettle()` timed out on `CircularProgressIndicator` infinite animations. Switched to incremental timed `pump` calls.

### 3. Decisions with AI: The Two-Tab Audit Console
- **`core_foundation`:** `LogEntry` model and `AppLogger.entryStream` broadcast pipeline.
- **`ssh_network_core`:** `SessionRecorder` class capturing PTY streams into `.cast` and text logs.
- **`AuditLogsScreen`:** System Logs tab with level filters (`DEBUG`, `INFO`, `WARN`, `ERROR`), search, auto-scroll, copy, and full stacktrace modals; Session Recordings tab with environment badges and output viewers.

### 4. Outcome: 157 Green Tests
`system_logs_screen_test.dart` and `session_recorder_test.dart` validated; 157 passing tests.

---

## Entry 13. The Live "● REC" Button, PROD Policies & Zero-Freeze PTY Timestamps

*Time: September 18, 2026, 17:30 — 17:45 (~15 minutes)*

### 1. The Impetus: Making Recording Tangible
Having built the recorder engine, session capture still required manual API calls. When logging into a production machine to apply emergency fixes, you want automatic recording and a prominent pulsing indicator: `● REC 02:45`.

### 2. Bottlenecks: Dynamic Attachment & Flush Mechanics
1. **Interface Extensibility:** Added a recorder setter to `ITerminalSession` in `core_foundation` to allow attaching recorders to active live sessions.
2. **Toolbar Indicator:** Embedded a dynamic indicator in the terminal toolbar. When active, it displays a pulsing red `● REC 01:23` ticking every second. Clicking stops recording and finalizes the cast file.
3. **Flexible Recording Policies in Settings:**
   - **PROD Only (Recommended):** Production machines record automatically; others require manual activation.
   - **All Sessions:** Records every connection indiscriminately.
   - **Manual:** Triggered exclusively via toolbar toggle.
4. **Clean Stream Flush:** `TerminalSession.terminate()` flushes and closes descriptors before writing to the index.

### 3. Outcome: 163 Tests Green
Added 4 scenarios in `session_connect_flow_test.dart` and UI widget checks in `terminal_screen_test.dart`.

---

## Entry 14. Matrix Splits Come Alive: Tiling Parallel Consoles Side-by-Side

*Time: September 18, 2026, 17:45 — 18:00 (~15 minutes)*

### 1. The Impetus: Clicking Split Did Nothing
Opening two servers and selecting "Split Horizontally" in `Ctrl+K` resulted in silence—the terminal remained a single pane. While `SplitMatrixView` was implemented, the wiring between state notifications, layout routing, and the screen had gaps.

### 2. Root Cause Analysis (`BUG-012`)
1. **Static Tab Type:** `setSplitLayout` updated layout properties but left `tab.type` as `TabType.terminal`. The router only rendered the split matrix when `tab.type == TabType.splitTerminal`.
2. **Isolated Sessions:** Each tab maintained its own single session in `splitSessions: [session]`.
3. **Missing Lifecycle Hooks:** Layout state was cached in `initState` without `didUpdateWidget` synchronization.

### 3. Resolution: Intelligent Session Aggregation
- Automatically transitions tab type to `TabType.splitTerminal` when horizontal, vertical, or 2x2 layouts are chosen.
- `SessionManagerNotifier.setSplitLayout` aggregates active terminal sessions from open tabs, placing them side-by-side.
- Pane headers resolve host names and environment badges independently.
- Synchronized `BroadcastInputBar` toolbar toggles with `Ctrl+K` palette commands.
- Prevented premature destruction of borrowed sessions during pane closures.

### 4. Outcome: 165 Tests Green
Full tiling multiplexer verified across unit and integration tests.

---

## Entry 15. Tab System Supercharged: Drag & Drop Tiling, Context Menus & 50+ Servers

*Time: September 18, 2026, 18:00 — 18:20 (~20 minutes)*

### 1. The Impetus: Managing Massive Server Fleets
Once splits worked, users needed direct manipulation: dragging open tabs into empty split slots, docking/undocking consoles, right-click actions (duplicate, rename, color tag, pin), and clean horizontal scrolling when managing dozens of servers.

### 2. The Three Pillars of the Tab Upgrade
1. **Drag & Drop Tiling (`TabDragPayload`):** Tabs wrap in `Draggable` with glowing neon feedback. Empty split panes act as `DragTarget` slots. Dropping a tab removes it from the top bar and embeds it into the split grid. An "Undock" button (`[↗]`) returns it to the top bar.
2. **Right-Click Tab Context Menu:**
   - Session operations: Duplicate (`Ctrl+D`), Open SFTP, Reconnect.
   - Layout management: Horizontal, Vertical, 2x2 Grid, Collapse to Single.
   - Personalization: Custom rename, 6 color tags (Red, Amber, Emerald, Electric Blue, Purple, Cyan), and Tab Pinning.
   - Bulk management: Close Others, Close to the Right, and Close Disconnected (pinned tabs protected).
3. **Taming Tab Overflow:** Smooth horizontal wheel scrolling without Shift, edge chevron buttons (`‹` / `›`), an overflow dropdown menu (`[ ⌄ N ]`) with instant search, and Omni-Bar quick-switching under "Open Tabs".

### 3. Bottlenecks & Flutter Quirks
- **Uniform Border Rule:** `BoxDecoration` forbids mixing different border properties with `borderRadius`. We rendered uniform subtle borders and positioned color tags as clean circular status indicators.
- **Pointer Device Emulation:** Replaced generic tester taps with `PointerDeviceKind.mouse` to ensure accurate secondary button events.

### 4. Outcome: 194 Tests Green
Added comprehensive test suites for drag-and-drop, context menus, and pinning; 194 passing tests.

---

## Entry 16. Split Refinement: Inline Host Picker, Unbreakable Layouts & Preserved Scrollback

*Time: September 18, 2026, 18:20 — 18:40 (~20 minutes)*

### 1. The Impetus: Ergonomic Gaps in Tiling Workflows
While splits and drag-and-drop worked mechanically, real-world usability revealed friction:
1. **Clicking "+" in an Empty Split Pane:** Instead of picking a host inside that pane, Shellit redirected to the global catalog, opening the chosen host in a brand new top-level tab, leaving the split slot empty.
2. **The "Undock" Button (`[↗]`):** Returning a pane to the top bar forcibly shifted active focus and collapsed the remaining single pane back to `single`, destroying prepared 2x2 grids.
3. **Scrollback Reset on Docking:** Moving a terminal into a split pane re-instantiated `Terminal` inside `initState`, wiping console history.

### 2. Resolution: Technical Insights
1. **Inline Host Picker (`HostSlotPickerDialog`):** Clicking "+" or "Connect Host to this Pane" opens an inline modal over the slot with instant fuzzy search. Supports "Quick Connect" (`root@10.0.0.5:2222`), attaching sessions directly into the target slot (`addSessionToSplit`).
2. **Unbreakable Layouts & Focus Retention:** `undockSplitPane` preserves `TabType.splitTerminal` and grid geometry, turning the vacated slot into an empty target. Active focus remains on the current split tab.
3. **`TerminalSessionRegistry`:** Lifted active `Terminal` instances, controllers, and streams into a global session registry. Terminal widgets can remount, resize, or move across the widget tree with 100% scrollback and buffer preservation. Immediate PTY resize signals (`session.resize(...)`) align terminal dimensions on the first frame.

### 3. Outcome: Polished Desktop Tiling
194 tests green; fresh Windows release binary compiled.

---

## Entry 17. The Face of Shellit: Neon Branding, Multi-Resolution .ico & Release Packaging

*Time: September 18, 2026, 18:40 — 19:00 (~20 minutes)*

### 1. The Impetus: Beyond the Default Flutter Butterfly
With encryption, live ping, xterm 4.0, 2x2 matrix splits, and audit logging complete, seeing the default blue Flutter icon in the taskbar felt unfinished. A production power tool requires distinct identity: console roots, energy, and speed.

### 2. Bottlenecks: Vector Iterations & Packaging Quirks
Having spent a decade in visual design, I had a clear concept: the capital **S** of Shellit paired with a terminal prompt underscore `_` (`S_`).
1. **First Pass (Bare Vector):** A light-green outline on transparent canvas washed out completely on light OS backgrounds, while the 16x16 tray icon turned into an illegible single pixel.
2. **Second Pass (Squircle Background):** Added deep dark-blue backing (`#1C213D`) with a neon gradient (`#5FB300` → `#8AEB1A`). However, inadequate glyph margins (20px) caused OS mask clipping on Android and macOS.
3. **Third Pass (Optical Balance):** Balanced margins (65–75px safe zone) and aligned the cursor with the base of the lower curve of `S`.

Technical hurdles:
- **`flutter_svg` Parsing:** Stripped `<style type="text/css">` blocks from Illustrator vectors, converting styles to inline attributes to avoid warnings.
- **Multi-Resolution Windows `.ico`:** Standard icon generators produce single-resolution 48x48 icons, turning blurry at 256x256. We authored an automated Pillow/PyQt asset script packaging all 7 standard Windows layers: 16, 24, 32, 48, 64, 128, and 256px.
- **Apple App Store Cleanliness:** Set `remove_alpha_ios: true` to prevent rejection due to alpha channels.

### 3. Decisions with AI: System-Wide Asset Pipeline
- Multi-platform assets generated for Windows (`.ico`), Android (all mipmap densities), iOS/macOS (`AppIcon.appiconset`), and Web (PWA favicons).
- Added `ShellitLogo` widget to `terminal_ui`, embedding the vector brand emblem in `NavigationSidebar`.
- Completed 30-second Windows Release build under Safe Build Protocol (`apps/shellit/build/windows/x64/runner/Release/shellit.exe`).

### 4. Outcome: 194 Tests & Recognizable Identity
194 tests green, 0 analyzer issues.

---

## Entry 18. Self-Hosted E2EE Sync: Zero-Knowledge VPS Relay in Pure Dart

*Time: September 18, 2026, 19:00 — 19:35 (~35 minutes)*

### 1. The Impetus: Multi-Device Reality Without Third-Party Clouds
Launching Shellit on a secondary mobile device presented an empty database. Re-entering dozens of hosts, ports, and private keys manually on mobile screens is painful.

Commercial clients offer cloud sync, but routing private keys and server manifests through third-party proprietary servers is an unacceptable security compromise for sysadmins. We built our own ultra-lightweight, zero-knowledge self-hosted sync server.

### 2. Bottlenecks: HTTP vs. HTTPS, Mobile Security & Zombie Hosts
1. **Protocol Flexibility:** For users running sync across WireGuard or internal LANs, forcing paid domains and Let's Encrypt certificates is unnecessary friction. We supported both HTTP and self-signed HTTPS. To satisfy mobile OS security policies, we adjusted `AndroidManifest.xml` cleartext rules and handled SSL bypass via explicit opt-in settings.
2. **Zero-Knowledge E2EE Architecture:**
   - User inputs a vault passphrase.
   - Derives a 256-bit symmetric encryption key via **Argon2id** and unique salt.
   - Encrypts records (hosts, keys, snippets) locally with **AES-256-GCM**.
   - Authenticates with the relay via blind hash `authHash` (SHA-256 of key + salt). The server stores purely encrypted blobs and possesses zero decryption capability.
3. **The Zombie Record Problem:** Deleting a host on desktop could cause an unsynced mobile device to push it back as an active record. We resolved this via **Tombstones** and a **Pull-Then-Push** algorithm with Last-Write-Wins (LWW) timestamp conflict resolution.
4. **Dart Sync Server (`servers/sync_server`):** Implemented in pure Dart with `shelf` and `sqlite3`, consuming only 15–20 MB RAM in a lightweight Docker container.

### 3. Decisions with AI: End-to-End Pipeline
- `SyncCrypto` module in `storage_vault` handling key derivation and authenticated GCM payloads.
- REST API (`/api/v1/sync/changes`, `/push`) and WebSocket channel (`/ws`) for instant real-time sync pushes across devices.
- `SyncSettingsCard` in Settings with connection testing, custom server endpoints, and registration tokens.

### 4. Outcome: Laptop ↔ Server ↔ Mobile Integration Tests
Created `sync_client_integration_test.dart` verifying multi-client replication, updates, and tombstones. Production Docker Compose deployment runs in 60 seconds:
```bash
docker compose up -d
```

---

## Entry 19. The Missing Essential: 1-Click Key Generator, ~/.ssh Scanner & Built-In ssh-copy-id

*Time: September 18, 2026, 19:35 — 20:46 (~1 hour 10 minutes)*

### 1. The Impetus: Forgetting the Basics Amid Complex Architectures
Focusing heavily on E2EE sync and WebSocket replication left an obvious gap: the Keychain screen only offered manual PEM text pasting. Expecting users to leave the app, generate keys via terminal CLI, locate `.ssh` folders in Notepad, and copy text is counter-productive.

### 2. Bottlenecks: Cryptographic Generation & Windows Permissions
1. **Local Key Generation:** Generating OpenSSH-compliant Ed25519 and RSA-4096 keys natively in Dart without relying on system `ssh-keygen` binaries.
2. **Automated `~/.ssh` Scanner:** Filtering out `known_hosts` and `config` files across Windows (`%USERPROFILE%\.ssh`) and POSIX (`~/.ssh`), detecting encrypted keys and requesting passphrases safely.
3. **Autonomous `ssh-copy-id`:** Windows lacks standard `ssh-copy-id`. Shellit must connect via password, create `~/.ssh`, set `chmod 700`, append public keys via stdin stream, deduplicate entries, and apply `chmod 600`.

### 3. Decisions with AI: Keychain Pro
- **`KeyGeneratorService`:** Ed25519 generation in under 5ms via `pinenacl` with standard OpenSSH headers; RSA-4096 generation via `pointycastle`.
- **`SshDirectoryDiscoveryService`:** Scans local user directories, matches `.pub` counterparts, and extracts fingerprints.
- **`SshKeyDeployService`:** Streams public keys directly into `~/.ssh/authorized_keys` over SSH stdin, with an option to link the deployed key to the host card for future logins.
- **Ergonomic Keychain UI:** "Generate Key" and "Import ~/.ssh" header buttons, 1-click clipboard copy, and deployment cloud triggers.

### 4. Outcome: 200+ Green Tests & Frictionless Auth
Over 200 tests passing across the monorepo; analyzer completely clean.

---

## Entry 20. Terminal Hotkeys: Smart Ctrl+C, Context Menu & The F1 Cheat Sheet

*Time: September 18, 2026, 20:46 — 21:25 (~40 minutes)*

### 1. The Impetus: Terminal Usability Bottlenecks
Selecting text in the terminal and pressing `Ctrl+C` sent a `SIGINT` interrupt signal to the remote server rather than copying text. Right-clicking the terminal did nothing. Expecting everyday developers to know `Ctrl+Shift+C` without hints is poor UX.

### 2. Resolution: Ergonomic Hotkey System
1. **Smart `Ctrl+C`:** If text is selected, `Ctrl+C` copies to the clipboard with a subtle notification badge ("Copied N chars"). If no text is selected, it passes through standard console `SIGINT` (`\x03`).
2. **Universal Paste:** Supports `Ctrl+Shift+V`, `Ctrl+V`, `Shift+Insert`, and middle-mouse button click (Linux-style).
3. **Right-Click Terminal Context Menu:**
   - 📋 Copy (shows selected character count)
   - 📥 Paste (`Ctrl+Shift+V`)
   - 🔲 Select All (`Ctrl+Shift+A`)
   - 🧹 Clear Buffer (`Ctrl+Shift+K`)
   - ⌨️ Hotkeys... (`F1`)
4. **Font Zoom:** `Ctrl++`, `Ctrl+-`, `Ctrl+0` (reset to 13pt).
5. **Keyboard Cheat Sheet (`F1`):** A clean modal dialog grouping hotkeys by clipboard, mouse, zoom, and session operations.

### 3. Outcome: 12 Terminal Screen Tests Verified
Added widget tests in `terminal_screen_test.dart` for selection, copy, paste, zoom, and menu triggers.

---

## Entry 21. The GlobalKey Trap in IndexedStack: Solving Red Screen Crashes in SFTP

*Time: September 18, 2026, 21:25 — 21:45 (~20 minutes)*

### 1. The Impetus: Flutter Assert Crash on Local SFTP Pane
Opening an SFTP session displayed remote directories on the right, but the left local panel threw a red screen error:
`'package:flutter/src/widgets/framework.dart': Failed assertion: line 2168 pos 12: '_elements.contains(element)': is not true.`

### 2. Root Cause Analysis (`BUG-016`)
We previously attached `GlobalKey<LocalFilePaneState>` to allow parent views to trigger `reload()`. In `LocalFilePane.initState()`, directory scanning invoked path callbacks that called parent `setState()`. Inside `IndexedStack`, triggering layout rebuilds while child elements were mounting corrupted element tree references.

### 3. Resolution: `PaneReloadController`
1. **Removed GlobalKeys:** Created `PaneReloadController` extending `ChangeNotifier`. Parents call `reload()`, and panes listen without manipulating widget keys.
2. **Clean Lifecycle:** Moved directory reads outside `setState()` and deferred path notifications via `addPostFrameCallback`.
3. **Smart Home Directory Default:** Replaced `Directory.current` (which pointed to internal build paths) with actual user home directories (`%USERPROFILE%` / `$HOME`).

### 4. Outcome: Zero Runtime Errors
Validated via DTD and Hot Restart; 0 runtime errors reported.

---

## Entry 22. Standardizing .shellit & Launching the Docker Container Monitor

*Time: September 18, 2026, 21:45 — 22:15 (~30 minutes)*

### 1. The Impetus: Beyond Stubbed Plugins
The Plugins tab listed dummy cards for Docker and Kubernetes that only flipped boolean switches in memory. Furthermore, dialogs referenced `.pkit` bundles (a foreign format from another ecosystem inadvertently copied by an AI agent).

We wanted real, extensible plugins built with web standards (HTML/CSS/JS) running inside a sandboxed panel next to the console, packaged as **`.shellit`** archives.

### 2. Architectural Insight: Desktop vs. Mobile Hygiene
We established a fundamental rule: **Plugins are exclusive to desktop environments (Windows, macOS, Linux).**  
Mobile screens are too narrow for 340px sidebars, and bundling WebView dependencies on mobile bloats binaries and drains battery life. Mobile clients stay ultra-lightweight and clean.

### 3. Implementation: WebView2, Loopback HTTP & SSH JSON-RPC
1. **`.shellit` Packaging:** Standardized extension archives as `.shellit` (zip archives containing `manifest.json`, `index.html`, and assets).
2. **Loopback Server (`PluginStaticServer`):** Serving files via `file://` triggers CORS and security blocks in WebView2. We built a lightweight embedded HTTP server on `127.0.0.1` binding a random free port and enforcing directory boundaries via `p.isWithin`.
3. **JSON-RPC 2.0 Bridge:** `DesktopPluginHostView` handles `window.chrome.webview.postMessage` events. When users click "Restart Container", the JS runtime calls `terminal.runCommand`, the bridge verifies permissions (`terminal:execute`), and runs the command directly over the active SSH client.
4. **Session Context & Top Bar:** Added a `[🐳 Docker]` button in the terminal header. The sidebar reflects the active host and switches contexts when changing tabs.

### 4. Outcome: Verified Reference Plugin
Built and bundled `docker_monitor.shellit` (5.8 KB); 34 tests in `desktop_plugin_sdk`, 52 in `terminal_ui`, and 23 in root app passing.

---

## Entry 23. Real-World Testing: WebView2 Mouse Wheel Scroll & Seamless Auto-Switching

*Time: September 18, 2026, 22:15 — 22:35 (~20 minutes)*

### 1. The Impetus: Live VPS Container Monitoring
Connecting to live Hetzner and Senko servers populated `Docker Container Monitor` with running containers (`rustdesk`, `vibestack`, `swiftgram-proxy`). However, two ergonomic issues appeared:
1. Mouse wheel scrolling did not work inside the sidebar list.
2. Switching server tabs did not automatically refresh the container list.

### 2. The Mouse Wheel Bug in `webview_windows`
In the underlying C++ code of `webview_windows`, `SendScroll` coordinates were hardcoded to `point.x = 0; point.y = 0`, targeting the static unscrollable HTML header.

Rather than patching C++ plugins, we solved it in the Flutter host:
1. Wrapped `Webview` in a Flutter `Listener(onPointerSignal: ...)`.
2. Intercepted `PointerScrollEvent.scrollDelta.dy` and forwarded scroll deltas directly to DOM elements via `executeScript`.
3. Added a native `'wheel'` listener in `plugin.js` for smooth scrolling.

### 3. Reactive Session Context Switching
1. Subscribed `DesktopPluginHostView` to `sessionManagerProvider.select((s) => s.activeTab?.id)`.
2. Dispatches `host.changed` JSON-RPC notifications and triggers `window.onHostChanged` on tab switch.
3. Automatically collapses the plugin panel when navigating to the Hosts catalog, expanding back to 100% width when returning to terminal sessions.

---

## Entry 24. Master Password Change (BUG-018): From Decorative UI Stub to True Argon2id Re-Keying

*Timestamp: September 18, 2026, 22:35 — 23:15 (~40 minutes)*

### 1. The Glitch: "Password Changed", But Not Really
In "Settings & Security", a user clicks "Change Master Password", enters the new secret, clicks "Update Password", and gets a friendly green banner: *"Master password updated and database re-keyed"*. But next time the app locks up, the new password fails, and the old one unlocks the vault as if nothing happened.

### 2. Under the Hood of the Dialog
Opening `settings_screen.dart` revealed a classic UI facade:
The "Update Password" button in `_showChangePasswordDialog` was a pure UI stub. It dismissed the dialog and popped a `ScaffoldMessenger.showSnackBar(...)` without reading a single character from `oldPassCtrl` or `newPassCtrl`, let alone calling any repository method.

In `VaultRepository`, the `changeMasterPassword` method had been written and tested: verifying the old password, generating a new salt, running Argon2id, re-encrypting all entries in `KeysTable`, and updating the verification blob. But there was zero wiring between the dialog and this backend logic — `VaultNotifier` in `vault_provider.dart` lacked `changeMasterPassword` altogether.

Furthermore, a subtle security edge case was discovered: when rotating the master key, any cached PIN metadata still held the old master key, potentially causing desynchronization during rapid PIN unlock.

### 3. The Fix
1. Implemented `changeMasterPassword` in `VaultNotifier` (`packages/terminal_ui`), proxying the call to `IVaultRepository` while updating lock states and timer listeners.
2. Fully rebuilt the dialog in `SettingsScreen`:
   - Proper input validation: empty field checks, minimum length (>= 6 chars), mismatch check between old and new passwords, and confirmation field ("Confirm New Password").
   - Added `StatefulBuilder` with a `CircularProgressIndicator`, since Argon2id requires non-trivial CPU work.
   - Inline red error banners for validation mistakes or incorrect current passwords, avoiding jarring dialog dismissals or wiped input fields.
   - Dynamic mode adaptation: if the vault was previously in Open Session mode, the tile switches to "Set Master Password" and delegates to `initializeVault`.
3. Added automatic PIN reset (`disablePin()`) inside `VaultRepository.changeMasterPassword` to avoid stale master-key leaks.
4. Added regression tests in `apps/shellit/test/settings_screen_test.dart` and `packages/terminal_ui/test/view_switcher_and_providers_test.dart`.

---

## Entry 25. Connection UX & Freedom from Master Passwords: Live Spinner, Clear Lock Cards & Open Session Mode

*Timestamp: September 18, 2026, 23:15 — 23:55 (~40 minutes)*

### 1. The Context: Silent Terminals and Cryptic SSH Errors
Real-world usage revealed two frustrating friction points:
First, clicking a host card produced zero visual feedback for a couple of seconds. You sat wondering if the click registered, if the network stalled, or if the app froze.
Second, an even worse scenario: when the vault was locked (after app launch or auto-lock timeout), clicking a server popped a red error banner: *"Authentication failed"* or *"SSHChannelRequestError"*. Anyone's first thought would be: *"Did the server crash? Did my key expire? Did the admins change passwords?"*. In reality, the key was locked inside the local database, but Shellit attempted an anonymous connection with empty credentials.

And finally: not every developer needs a master password. On a home machine with BitLocker, typing a master password on every launch just to access two local VMs is tedious. A true opt-out was needed.

### 2. The Root Cause: Connecting Blindly
In `SessionConnectController`, when a host had a `credentialRefId`, the controller queried `KeyManager` for the decrypted credentials. If the vault was locked, `KeyManager` returned `VaultFailure.locked()`. The controller logged a warning and simply proceeded with `password: null` and `keyBytes: null`. `dartssh2` attempted an unauthenticated handshake, the server naturally rejected it, and the network error masked the actual cause.

### 3. Engineering the Solution
1. **Instant Feedback & Live Spinner (`TerminalConnectingView`):**
   - The session tab in `TopBarTabs` opens **the exact millisecond** a host card is tapped or chosen via `Ctrl+K`.
   - The tab displays a styled Obsidian Dark connection view: `user@host:port`, OS badge, environment badge (`PROD` / `STAGE`), cyan top progress bar, and a glowing neon spinner.
   - Below the spinner, a live step-by-step timeline shows connection stages: *Key Decryption → TCP Socket Connect → SSH Handshake → User Authentication → PTY Allocation*.
   - Added a "Cancel Connection" button to abort immediately without waiting for a 15-second TCP timeout.
2. **Clear Amber Card Instead of False SSH Errors:**
   - Implemented a strict fail-fast check in `SessionConnectController`: if a host requires stored credentials and the vault is locked, the app halts before touching the network.
   - The tab displays a warm amber card with a lock icon: **"Master password required"**.
   - An inline **"Unlock Vault"** button opens the unlock dialog. Upon unlocking, Shellit automatically retries the connection without requiring a manual reconnect click.
3. **True Open Session Mode (Disabling Master Password):**
   - Added `disableMasterPassword` in `IVaultRepository` and `VaultRepository`. It verifies the current password, generates a cryptographic `open_session_key`, re-encrypts all private keys in SQLite with it, clears lock metadata, and disables auto-lock.
   - Added an explicit **"Disable Master Password"** option with clear warnings in `SettingsScreen`.
   - Users choose their own balance: high paranoia with Argon2id and 5-minute auto-locks, or instant, password-free convenience.

---

## Entry 26. Zero Hardcoded Strings & Russian Language Plugin

*Timestamp: September 18, 2026, 23:55 — September 19, 2026, 00:30 (~35 minutes)*

### 1. The Context: Hardcoded English Refusing to Yield
After building the `.shellit` localization engine, reactive `context.tr(...)`, and template exports, we packaged `russian_lang_pack.shellit`, installed it, switched the language to Russian... and found half the interface still stubbornly displaying English.

### 2. Anatomy of the Gap
Two distinct gaps were at play:
1. **Incomplete Template Dictionary:** `defaultEnglishStrings` contained only 87 rough keys. Navigation sidebar items, settings headers, view mode switchers (grid, list, tree), audit options, and tooltips were absent.
2. **Hardcoded Widget Text:** UI widgets (`NavigationSidebar`, `TopBarTabs`, `HostViewsSwitcher`, `SettingsScreen`) directly rendered hardcoded text like `const Text('Auto-Lock Timeout')`, `label: 'Hosts'`, and `_buildSectionHeader('Security & Vault')`. Even with thousands of translations in a plugin, Flutter never queried `context.tr(...)`.

### 3. Implementation
1. **Eradicated Hardcoded Strings in Core UI:**
   - `NavigationSidebar`: translated all navigation items (Hosts, Keychain, Tunnels, Snippets, Logs, Plugins, Settings) and collapse tooltips to `context.tr('sidebar.nav_*')`.
   - `TopBarTabs`: host catalog tabs, quick-connect placeholders, `Ctrl+K` tooltips, vault lock status indicators, and unlock dialogs.
   - `HostViewsSwitcher`: search input, layout toggles ("Grid", "Compact List", "Folder Tree"), "Add Host" button, and empty state views.
   - `SettingsScreen`: all section headers ("Security & Vault", "Terminal Appearance", "Backup & Restore", "Language & Localization", "Synchronization", "Logs & Diagnostics") and setting tiles.
2. **Standardized Master Dictionary & Russian Pack:**
   - Expanded `defaultEnglishStrings` to 128 canonical keys.
   - Updated `ru.json` in both user plugin storage and the distribution bundle `russian_lang_pack.shellit`.
   - Exported updated `shellit_strings_template.json` containing all 128 keys.
3. **Runtime Verification:**
   - Applied via `hot_restart` and `hot_reload` over DTD. The UI switched completely and cleanly to Russian.
   - 33/33 tests passing in `apps/shellit`, 0 analyzer warnings.

---

## Entry 27. Cross-Device Key Synchronization & Zero-Knowledge Security

*Timestamp: September 19, 2026, 00:30 — 02:45 (~2 hours 15 minutes)*

### 1. The Context: "Everything Synced to Android, But Nothing Connects"
Self-hosted synchronization between Windows and Android (via a lightweight Proxmox CT sync server) transferred hosts, folders, and snippets seamlessly. But tapping "Connect" on Android yielded: *"Authentication failed. Please check your password or SSH key"*. Furthermore, attempting to set a master password on mobile triggered: *"Database file is corrupted or cannot be decrypted"*.
An audit of the local SQLite database also revealed that `syncPassphrase` was stored as plaintext in a configuration column.

### 2. Root Cause Analysis
1. **The Independent Master-Key Paradox:**
   Each device has its own local vault encryption key (a user-chosen master password on desktop, an auto-generated `open_session_key` on mobile). Previously, desktop exported SSH keys pre-encrypted with its own local master key. The mobile device received this encrypted blob and tried to decrypt it using its own local key, triggering an AES-GCM `SecretBoxAuthenticationError`. When the mobile user later tried setting a master password, `initializeVault` failed when attempting to re-encrypt this undecryptable foreign blob.
2. **Plaintext `syncPassphrase`:**
   Storing the sync passphrase in a plain `TextColumn` posed a security vulnerability if disk storage was compromised.

### 3. Cryptographic Resolution
1. **Vault-Encrypted `syncPassphrase`:**
   - Added a binary `encryptedSyncPassphrase` (`blob()`) column to `VaultSettingsTable`.
   - When saving settings, the passphrase is encrypted using the active AES-256-GCM master key, and the plaintext column is cleared.
   - Transparently decrypted in memory; re-encrypted automatically on master password rotation.
2. **E2EE On-the-Fly Re-Encryption (Zero-Knowledge Relay):**
   - **Push (Upload):** The sending device decrypts secrets with its local vault key, places raw credentials (`clearPrivateKey`, `clearPassphrase`) into the sync payload, and **encrypts the entire payload with a shared E2EE `syncKey`** derived via Argon2id from the sync passphrase. The sync server sees only opaque ciphertext.
   - **Pull (Download):** The receiving device decrypts the payload with `syncKey`, extracts the plaintext credentials, and **re-encrypts them with its own active local master key** before writing them to SQLite.
   - Desktop and mobile can now use completely different local master passwords without causing synchronization friction.
3. **Resilient Key Migration:**
   - Wrapped individual key re-encryption inside `initializeVault` and `changeMasterPassword` in isolated `try-catch` blocks, guaranteeing that legacy or malformed records never abort database operations.
4. **Validation:**
   - Added an end-to-end integration test (`sync_client_integration_test.dart`) simulating two independent devices with distinct master passwords.
   - Packaged release builds: Windows `shellit.exe` and Android `app-release.apk` (66.2 MB).

---

## Entry 28. Mobile Renaissance: Android Redesign & Desktop Decoupling

*Timestamp: September 19, 2026, 02:45 — 03:35 (~50 minutes)*

### 1. The Context: "A Desktop Giant Stuffed into a 6-Inch Screen"
Shellit's initial mobile build was a textbook case of brute-force cross-platform deployment: a desktop UI (wide sidebar, tab bar, 2x2 matrix splits, dual-pane SFTP, WebView plugins) rendered directly on a narrow portrait smartphone screen.
Buttons were squished, dual-pane SFTP split 380px into two unusable columns, desktop WebView plugins bloated the APK, and terminal splits were impossible to control with one thumb.

The user requirement was clear: build a dedicated, thumb-friendly mobile interface focused strictly on core remote access — one active terminal session, simplified navigation, and zero desktop baggage.

### 2. Principles of the Mobile-First Redesign
1. **Adaptive Architecture Dispatcher:**
   - Desktop shell preserved intact (tabs, matrix tiling, WebView plugins, dual-pane SFTP, snippets).
   - In `ShellitAppShell`, screen widths `< 700px` automatically mount the dedicated `MobileAppShell`.
2. **Material 3 Bottom Navigation (3 Tabs):**
   - Replaced the sidebar with a clean 3-tab `NavigationBar`: **Hosts**, **Keychain**, and **Settings**.
   - Omitted desktop-heavy modules (plugins, tunnels, snippets, SFTP) on mobile for lightweight, instant responsiveness.
   - Compact AppBar with vault lock status, live host search, and Quick Connect bottom sheet (`user@host:port`).
   - Floating Action Button (`+`) for rapid server creation.
3. **Touch-Friendly Host Catalog (`MobileHostsView`):**
   - Full-width touch cards with generous tap targets.
   - Real-time RTT latency dot (green `<50ms`, yellow `<200ms`, orange `>200ms`, grey offline), OS icon, and prominent environment badges (`PROD`, `STAGE`, `DEV`).
   - Long-press and context button opening a native action bottom sheet (Edit, Duplicate, Delete).
4. **Full-Screen Single-Session Terminal (`MobileTerminalScreen`):**
   - Full-screen terminal rendering without tab bar clutter.
   - Top banner showing back button, host title, PROD badge, and live latency.
   - **Accidental Back-Swipe Protection (`PopScope`):** Intercepts swipe gestures to prevent accidental disconnects, prompting for confirmation only if a session is alive.
   - **Reconnect Banner:** Automatically presents a "Tap to Reconnect" banner on connection drops.
   - **Pinch-to-Zoom:** Smooth font scaling using standard two-finger pinch gestures.
5. **Mobile Accessory Bar (`MobileAccessoryBar`):**
   - Dedicated keyboard accessory bar pinned above the soft keyboard with Esc, Tab, Ctrl, Alt, |, /, -, ~, cursor arrows, and `HapticFeedback`.
   - One-tap **PASTE** button and keyboard dismiss toggle.
6. **Mobile Hygiene:**
   - Locked mobile locale strictly to English (`effectiveLocale: 'en'`).
   - Removed plugin language settings from mobile preferences.
   - Fixed `RenderFlex` overflow in the Keychain toolbar.

### 3. Results
- 37/37 tests passing in `apps/shellit`, 70/70 in `packages/terminal_ui`.
- Clean static analysis across all packages.
- Zero desktop compromises; mobile elevated into a practical, lightning-fast sysadmin tool.

---

## Entry 29. MCP Bridge to Cursor, Claude & AI Assistants

*Timestamp: September 19, 2026, 08:15 — 09:55 (~1 hour 40 minutes)*

### 1. The Context: Bridging Terminals and LLMs
Modern infrastructure engineering frequently involves AI editors like Cursor, Windsurf, or Claude Desktop. The workflow often requires manual copy-pasting: asking an LLM for diagnostics, copying a `docker logs` command to the terminal, copying output back to the chat, and repeating the cycle.

With Anthropic's **Model Context Protocol (MCP)** establishing an open standard for AI tooling, we evaluated a native integration: turning Shellit into a secure bridge allowing Cursor or Claude to query servers, inspect terminal buffers, and execute commands safely.

### 2. Guardrails: Running AI Against Production
Connecting an LLM to live servers requires uncompromising security:
1. **Zero Secret Leakage:** Master passwords, private keys, and database contents remain strictly inaccessible to the model. Commands execute only through already-authorized SSH sessions.
2. **PROD Guard:** Prohibits destructive commands (`rm -rf /`, `DROP DATABASE`, etc.) against environments flagged with `PROD`.
3. **Live Audit Trail:** Every MCP invocation is logged with timestamp, tool, arguments, and exit status in a real-time UI stream.
4. **Platform Hygiene:** Desktop-only plugin; excluded from mobile builds.

### 3. Implementation
1. **Core Dart MCP Server (`McpServerService`):**
   - Implemented the MCP specification (version 2024-11-05) in pure Dart via HTTP + Server-Sent Events (SSE).
   - `GET /sse` manages persistent connections, assigning unique `sessionId`s and dispatching endpoint handshakes.
   - `POST /message?sessionId=...` handles JSON-RPC 2.0 requests: `initialize`, `tools/list`, and `tools/call`.
   - Implemented 5 foundational tools:
     - `shellit_list_servers`: lists configured servers, tags, and environments.
     - `shellit_list_active_sessions`: lists active connections.
     - `shellit_exec_command`: runs a command via the active SSH client.
     - `shellit_get_terminal_buffer`: reads recent lines from an open terminal buffer.
     - `shellit_read_remote_file`: reads remote configs and logs via SFTP.
2. **PROD Guard & Audit Logging:**
   - Evaluates host environment before execution, intercepting dangerous operations on `PROD` targets.
   - Logs invocations to `McpAuditLogEntry` models streamed directly to the plugin UI.
3. **Plugin Interface (`com.shellit.mcp-server`):**
   - Clean vector SVG cybernetic icon using Obsidian / Cyberpunk accents (`#00F0FF`, `#A855F7`).
   - Displays server status, port configuration (default 8181), and 1-click configuration exporters for `claude_desktop_config.json`, `.cursor/mcp.json`, and Windsurf.
   - Real-time audit log viewer at the base of the panel.
4. **Application Integration:**
   - Bundled out-of-the-box in `plugins/`.
   - Added a `[⚡ MCP AI]` toggle in the top bar tab row.
   - Fully localized via `context.tr`.

---

## Entry 30. Multi-Monitor Setup for AI: Pop-Out OS Window, Smooth Scrolling & Antigravity Support

*Timestamp: September 19, 2026, 09:55 — 10:25 (~30 minutes)*

### 1. The Context: Viewing AI Actions on a Second Screen
Once MCP was operational and connected to Google Antigravity, interacting with servers via AI became frictionless. However, ergonomics needed adjustment:
1. **Sidebar Cramping:** A 340px sidebar is fine for quick glances, but inadequate for reviewing extensive command logs and multi-step agent actions.
2. **Multi-Monitor Potential:** Sysadmin and developer desks almost always feature two or three monitors. Displaying the AI activity log in an independent OS window on a secondary monitor is ideal.
3. **Antigravity First:** Rather than focusing solely on third-party editors, we needed seamless 1-click configuration for Google Antigravity (`~/.gemini/config/mcp_config.json`).

### 2. Architecture: Native App Window Mode Without Multi-Window Bloat
Rather than adopting fragile third-party Flutter multi-window packages that introduce native FFI compilation issues, we chose a robust OS-level pattern:
1. **Standalone App Window (`logs.html`):**
   - Built a dedicated `logs.html` monitor and `logs.js` styled in Shellit Obsidian Dark.
   - Clicking **"⤢ Pop-out"** launches `msedge.exe` (or Chrome) with `--app=http://127.0.0.1:<port>/logs.html`.
   - In `--app=` mode, the OS renders a clean window without browser navigation chrome, tabs, or address bars, featuring its own taskbar icon and support for Windows Snap across multi-monitor setups.
   - Includes real-time log streaming, full-text tool/argument search, success/error filtering, and **"📥 Save Logs (.log)"**, **"📋 Copy All"**, and **"🧹 Clear"** buttons.
2. **Direct REST Endpoints (`/logs` & `/api/logs/clear`):**
   - Decoupled the pop-out window from the sidebar lifecycle by exposing `GET /logs` and `POST /api/logs/clear` directly on `McpServerService`.
3. **Flexible Sidebar Resizing & Scroll Handling:**
   - Added a draggable splitter handle to the sidebar (adjustable from 280px to 950px) alongside a quick-expand toggle (380px ⟷ 640px).
   - Added vertical CSS resizing to the log container.
   - Fixed mouse wheel behavior inside the WebView container.
4. **1-Click Google Antigravity Setup:**
   - Added an **"⚡ Antigravity Config"** button that places the ready-to-use JSON block for `mcp_config.json` directly into the clipboard:
     ```json
     {
       "mcpServers": {
         "shellit": {
           "type": "sse",
           "url": "http://127.0.0.1:4422/sse",
           "serverUrl": "http://127.0.0.1:4422/sse"
         }
       }
     }
     ```

---

## Entry 31. AI Snippets Assistant: Google Gemini Integration, Dynamic Models & Safe Command Generation

*Timestamp: September 19, 2026, 11:05 — 12:30 (~1 hour 25 minutes)*

### 1. The Context: Eliminating the Need to Memorize Complex Bash Pipelines
Memorizing obscure flags for `find`, `awk`, `sed`, or chained Docker filters is an inefficient use of developer focus. While Shellit already featured a `Snippets` library for storing commands with tags and folders, curating them manually remained tedious.
Integrating an intelligent assistant directly into the Snippets view—enabling users to describe tasks in plain language and receive precise, safe commands with one-click terminal execution—was the natural evolution.

### 2. Architecture: Zero Hardcoding & Structured JSON Schema
1. **Modern Foundation:** Built on Google AI Studio API using `gemini-2.5-flash` — fast, cost-effective, and well-versed in Linux administration.
2. **Dynamic Model Discovery:** Rather than hardcoding model IDs, Shellit queries `GET /v1beta/models`, discovering available models supporting `generateContent` and populating the selector dynamically.
3. **Structured JSON Schema:** Configured `responseSchema` on Gemini requests, enforcing strict JSON output containing `title`, `command`, `description`, `tags`, and an `isDangerous` boolean paired with a `dangerWarning`.
4. **Destructive Command Detection:** If a generated snippet includes destructive operations (disk wipes, database drops, network interface resets), the UI immediately displays a prominent red warning banner to prevent accidental execution.
5. **Multi-Turn Context:** Retains conversation context across turns, enabling iterative refinements (e.g., "now exclude the /var/log/audit directory").
6. **Key Security & Localization:** API keys are encrypted in SQLite using AES-256-GCM under the master password, never appearing in plaintext logs. All UI copy is fully localized.

---

## Entry 32. UX Refinement: Notification Legibility, Targeted Command Routing & Terminal Resizing

*Timestamp: September 19, 2026, 12:30 — 13:15 (~45 minutes)*

### 1. The Context: Polishing Real-World Ergonomics
Transitioning from unit tests to daily operational use revealed several ergonomic papercuts:
1. Clicking "Run in Terminal" in the snippets view triggered an empty notification snackbar.
2. With multiple tabs open (e.g., production, staging, local VM), clicking "Run in Terminal" lacked clear visual indication of which server received the command.
3. Entering a Gemini API key in settings and switching tabs occasionally wiped the field.
4. Pressing `Enter` in the AI prompt box immediately submitted incomplete prompts instead of inserting newlines.
5. Maximizing the application window on 4K monitors left the terminal canvas stuck in a fixed box.

### 2. Deep Dive & Resolutions
1. **Legible Notifications (Dark-on-Dark Contrast Bug):**
   In Flutter's Material 3 dark theme, default `SnackBar` text colors derive from `onInverseSurface` — a near-black tone. Combined with Shellit's dark graphite `obsidianCard` background, notifications appeared blank. We defined an explicit `snackBarTheme` in `ShellitTheme.obsidianDarkTheme` with high-contrast typography and vivid status badges.
2. **Targeted Server Selection:**
   - When a **single terminal** is active, the button explicitly indicates the destination: e.g., **`Run in Hetzner`** with a green arrow.
   - When **multiple servers** are open, the button becomes a dropdown: **`Run in Hetzner ▾`**, displaying tab names and IP addresses.
   - Upon dispatch, a notification confirms: *"Command sent to Hetzner (192.168.1.1)"* with a **`[View in Terminal]`** action button that instantly switches to the corresponding tab.
3. **Gemini API Key Persistence (BUG-023):**
   In Open Session mode (no master password, `activeKey == null`), `updateSettings` inadvertently nullified the string column `geminiApiKey` while routing bytes into an encrypted BLOB that required an active key to read back. We corrected the persistence pipeline, eliminated premature auto-saves on toggle clicks, and added unit tests covering password-free storage.
4. **WebView2 Sidebar State Isolation:**
   Switching between Docker Monitor and MCP Server reused existing `State` because both widgets shared `DesktopPluginHostView`. Adding `ValueKey(activePlugin.manifest.id)` ensures clean widget disposal and recreation on plugin switch.
5. **Chat Inputs & Terminal Resizing:**
   - Standard `Enter` creates line breaks in the AI prompt field, while `Ctrl+Enter` (or `Cmd+Enter`) sends messages.
   - Wrapped the terminal canvas in a `LayoutBuilder` that actively triggers PTY stream resize recalculations when the window maximizes.

---

## Entry 33. Built-In Local ConPTY Terminal: Fast, Native & Ergonomic

*Timestamp: September 19, 2026, 13:15 — 13:45 (~30 minutes)*

### 1. The Context: Instant Local Shell Access
Developers managing remote infrastructure frequently require quick local execution: running `git status`, local migration scripts, network checks via `curl`, or tunnel verification. Having to minimize the client to open Windows Terminal disrupts workflow.
We designed a native **`[ Terminal ]`** local shell tab in Shellit, fully styled in **Obsidian Dark** with comprehensive shell detection (PowerShell 7, Windows PowerShell 5.1, cmd, WSL, Git Bash).

### 2. Technical Architecture & Stream Safety (BUG-024)
1. **ConPTY over Raw Process Pipes:**
   Standard `Process.start` pipes do not constitute a virtual terminal — cursor navigation fails, Tab completion breaks (PSReadLine crashes), interactive CLI tools (`vim`, `nano`, `htop`) break, and window resize events are ignored.
   We integrated Windows **ConPTY** (`CreatePseudoConsole`) via `flutter_pty2`, directly linking output with `xterm.dart`.
2. **Clean Contract Reuse (`ITerminalSession`):**
   Leveraged `core_foundation`'s `ITerminalSession` interface by implementing `LocalTerminalSession`. The existing `TerminalScreen`, matrix tiling splits, text selection, and scrollback systems accepted local sessions without UI modifications.
3. **Split-Button Shell Selector `[ Terminal | ▼ ]`:**
   - Left click: opens the default shell in `%USERPROFILE%`.
   - Dropdown arrow: lists all shells detected on the system (prioritizing modern PowerShell 7 `pwsh.exe`, falling back to Windows PowerShell, Command Prompt, WSL, and Git Bash).
   - Hotkey support via `Ctrl+`` and Omni-Bar (`Ctrl+K`).
4. **Stream Broadcast Fix (BUG-024):**
   `flutter_pty2` exposes a single-subscription stream. When testing under narrow window widths, both `TerminalSessionRegistry` and `MobileTerminalScreen` attempted to listen simultaneously, throwing:
   `Bad state: Stream has already been listened to.`
   We resolved this by wrapping the PTY stream in a broadcast controller (`StreamController<Uint8List>.broadcast()`) inside `LocalTerminalSession`, ensuring safe multi-subscriber access.

---

## Entry 34. Tabby-Inspired "About" Card: Smart Updates, Pre-Filled Issue Reporter & Project Passport

*Timestamp: September 19, 2026, 14:05 (~15 minutes)*

### 1. The Context: Adding the Final Touch of Craftsmanship
A well-designed "About" section anchors an application's identity. Instead of static text or non-functional placeholder links, we designed a functional, informative card inspired by Tabby and Termius:
- **Real Update Checker:** Queries the GitHub Releases API (`api.github.com/repos/kobaltgit/Shellit/releases/latest`), parses the latest release tag, compares versions, and presents release notes with direct download links.
- **Pre-Filled Bug Reports:** Clicking "Report Bug" generates a pre-filled GitHub Issue URL automatically populated with the Shellit version, host OS, and a structured reproduction template.
- **Honest Community Status:** Clearly communicates public release planning without dead links.
- **Adaptive Obsidian Layout:** Two-column desktop presentation that collapses smoothly into a single-column layout on narrower screens without `RenderFlex` overflows.

### 2. Architecture & Quality
- Modularized into `AboutSettingsCard` (`apps/shellit/lib/src/screens/settings/about_settings_card.dart`).
- Features the SVG `ShellitLogo`, `Shellit` title with superscript `α`, and version badge `0.7.3`.
- Added modal dialog for "What's New in Shellit" summarizing milestones (Matrix splits, SQLCipher, E2EE sync, Gemini AI, Plugin SDK).
- Fully covered by widget tests (`about_settings_card_test.dart`, 5/5 passing) and zero analyzer warnings.

---

## Entry 35. Native Dual-Pane SFTP Pro Suite: Elevating the File Manager into a Pro Tool

*Timestamp: September 21, 2026, 22:35 (~30 minutes)*

### 1. The Context: Overcoming SFTP Usability Hurdles

When we first introduced SFTP to Shellit, it was a minimal proof-of-concept: two panes, flat lists, and single-file uploads. However, using it for real-world maintenance revealed significant friction points:
- The remote pane rigidly defaulted to root `/` instead of the user's actual home directory (`/home/username` or `/root`), forcing manual path navigation on every connection.
- Folder transfers failed silently (`BUG-025`): handlers checked `isDirectory` and dropped execution.
- Multi-selection via `Shift` or `Ctrl` was unsupported (`BUG-026`), forcing users to transfer items one by one.
- Conflicting file names resulted in silent destination overwrites without user confirmation (`BUG-027`).
- Quick configuration edits (such as updating `nginx.conf`) required downloading files locally, editing them in external tools, and uploading them back.

We elevated `IDEA-027` (*Native Dual-Pane SFTP Pro Suite*) to completely modernize the SFTP subsystem.

---

### 2. Architectural Decisions & Implementation

#### User Home Resolution (`getDefaultPath`)
Via SFTP OpenSSH protocol, the server resolves `.` to the user's home directory (`sftp.absolute('.')`). We expanded the `ISftpSession` contract in `core_foundation` with `getDefaultPath()` and implemented it in `ssh_network_core`. The remote pane now boots directly into the remote user's home directory, and the breadcrumbs bar provides a `~` shortcut for instant returns.

#### Interactive Breadcrumbs & In-Place Editing (`SftpBreadcrumbsBar`)
Replaced the static path text with interactive breadcrumbs:
- Each path segment is an isolated button to navigate up any number of directory levels in a single click.
- Features back/forward navigation history (`<` and `>`), parent directory jump (`↑`), root jump (`/`), and home jump (`~`).
- Clicking the edit icon toggles an in-place `TextField` for direct path pasting and keyboard navigation with `Enter`.

#### Multi-Selection & Floating Batch Action Bar
Eliminated the single-selection limitation:
- `Shift+Click` selects contiguous ranges between the anchor element and the clicked item.
- `Ctrl+Click` (or `Cmd+Click` on macOS) toggles individual item selections.
- `Ctrl+A` selects all items in the active directory view.
- Selecting multiple items activates a floating **Batch Action Bar** showing item count with batch upload, download, and delete actions.

#### Recursive Folder Transfers (BUG-025)
Replaced the single-file limitation with robust recursive directory traversal:
- Local uploads recursively scan all subdirectories (`listSync(recursive: true)`), replicate the directory hierarchy remotely via `session.createDirectory`, and stream files sequentially.
- Remote downloads recursively query directories via `session.listDirectory`, create local folders, and download files with real-time transfer tracking.

#### Conflict Resolution Modal (BUG-027)
Before transmitting files, the system checks for destination existence (utilizing remote folder caching to eliminate redundant roundtrips). If a collision is detected, `SftpConflictDialog` appears:
- Displays source and destination file sizes and modification timestamps.
- Offers Overwrite, Skip, and Rename decisions.
- An "Apply to all conflicts" checkbox persists the decision across all remaining items in the transfer queue.

#### Embedded Remote & Local File Editor (`SftpFileEditorDialog`)
Double-clicking or pressing `Space` on any text file opens a full modal editor:
- Synchronized line numbers gutter.
- Monospace typography (JetBrains Mono), word-wrap toggle, and UTF-8 encoding indicator.
- In-place saving via `Ctrl+S` through new `readFile` and `writeFile` session contracts.
- Binary file detection with protective user warnings.
- Unsaved changes guard preventing accidental data loss on modal dismissal.

#### Bidirectional Inter-Pane Drag & Drop
Wrapped list items in strongly typed `Draggable<SftpLocalDragPayload>` and `Draggable<SftpRemoteDragPayload>`. Panes serve as mutual `DragTarget` drop zones:
- Dragging local files over the remote pane renders an active accent-blue boundary and uploads to the active remote folder.
- Dragging remote items over the local pane highlights an accent-cyan boundary and downloads to the active local folder.

---

### 3. Verification & Results

- Registered and resolved `BUG-025`, `BUG-026`, and `BUG-027`.
- Promoted `IDEA-027` from active backlog to `IMPLEMENTED`.
- Created comprehensive test suite in `sftp_suite_test.dart` and expanded `sftp_dialogs_test.dart`.
- All 291 unit and widget tests passed across all 6 packages:
  - `terminal_ui`: 84 tests
  - `ssh_network_core`: 60 tests
  - `apps/shellit`: 48 tests
  - `desktop_plugin_sdk`: 43 tests
  - `storage_vault`: 36 tests
  - `core_foundation`: 20 tests
- `flutter analyze` passed with 0 errors and 0 warnings.

---

## Entry 36. Refining SFTP in Battle: Batch Conflict Decisions and Instant Transfer Cancellation

*Timestamp: September 21, 2026, 23:05 (~15 minutes)*

### 1. Motivation: Field Testing Uncovers UX Gaps

Following the release of the SFTP Pro Suite with multi-selection, in-place file editing, and conflict dialogs, live dogfooding revealed two friction points:
1. **"Apply to all" ignored on Skip:** When syncing a directory with existing files, selecting "Skip" with the "Apply to all conflicts" checkbox failed to suppress subsequent modals (`BUG-028`). The dialog kept reappearing for every colliding file.
2. **Inability to abort transfers:** When accidentally transferring a large directory or initiating an unwanted upload/download, users had no mechanism to cancel or abort the active transfer without terminating the entire session (`BUG-029`).

### 2. Root Cause Analysis & Architecture Fixes

#### Batch Conflict Decision Persistence (BUG-028)
In `sftp_tab_view.dart` (`_uploadSingleFileWithConflict` and `_downloadSingleFileWithConflict`), the guard `if (result == null || result.decision == SftpConflictDecision.skip) return;` preceded `if (result.applyToAll) setBatchDecision(result.decision);`.
- Consequently, selecting `skip` triggered an immediate `return` prior to saving the choice to `_batchConflictDecision`. Subsequent files found `batchDecision == null` and prompted the user again.
- Relocating `if (result.applyToAll) setBatchDecision(result.decision);` before the skip evaluation ensures the batch decision is reliably remembered across the remainder of the transfer queue.

#### Responsive Transfer Cancellation & Queue Abort (BUG-029)
We engineered responsive transfer cancellation across the UI and streaming layers:
1. **Queue Bar Ergonomics (`TransferQueueBar`):**
   - Introduced `TransferStatus.cancelled`.
   - Added a prominent **[✕ Cancel All]** action button in the queue bar whenever active transfers are processing.
   - Added individual close icons (`Icons.close`) on active file chips to support granular single-item aborts.
2. **Stream Abort & Loop Guards (`SftpTabView`):**
   - Added `_cancelRequested`, `StreamSubscription<double>? _currentStreamSub`, and `Completer<void>? _currentCompleter`.
   - Calling cancel invokes `_currentStreamSub?.cancel()`, updates the item status to `cancelled`, and resolves the completer immediately.
   - In recursive and batch routines (`_uploadPaths`, `_downloadPaths`, `_uploadDirectoryRecursively`, `_downloadRemoteDirectoryRecursively`), `if (_cancelRequested) break;` guards guarantee immediate termination of subsequent queue items.

### 3. Verification & Results

- Verified and resolved `BUG-028` and `BUG-029`.
- Added unit tests for cancellation in `TransferQueueBar` within `sftp_suite_test.dart`.
- Total test count in `terminal_ui` increased to **86** (100% passing).
- Windows debug executable compiled cleanly via Safe Build protocol and relaunched.

---

## Entry 37. Modern Workspace Redesign: Custom Titlebar, Right Activity Rail, and Session Persistence (IDEA-024)

*Timestamp: September 21, 2026, 23:25 (~20 minutes)*

### 1. Motivation: Tab Room and Context Preservation

The user interface of an everyday SSH client must be unobtrusive, spacious, and resilient to application restarts. During routine dogfooding of Shellit, three ergonomic friction points became evident:
1. **Heavyweight OS Window Borders and Cramped TopBar:** The standard Windows titlebar wasted vertical space, while the 220px Quick Connect input combined with plugin buttons (MCP AI, Docker) consumed vital horizontal space in the tab bar. With several sessions open, tabs compressed into unreadable slivers.
2. **Context Loss on App Restart:** Exiting Shellit or closing the window obliterated all open terminal and SFTP tabs. Users were forced to relocate servers in the catalog and reconnect manually upon reopening.
3. **Pinned Tabs Consumed Excessive Width:** The Hosts tab and pinned servers took almost as much space as regular sessions, losing the compact advantage of pinning.

### 2. Architecture & Implementation

#### Seamless Custom Titlebar (`WindowControls`)
We integrated window frame control using `window_manager` while maintaining strict package boundaries (Desktop vs Mobile Hygiene):
- Neither `terminal_ui` nor `core_foundation` depend on desktop native packages; they consume abstract callbacks (`onWindowMinimize`, `onWindowMaximize`, `onWindowClose`).
- Designed `WindowControls` with native Windows 11 iconography, smooth hover transitions, and an accent red close button.
- TopBarTabs supports dragging the window (`DragToMoveArea`), double-clicking to maximize/restore, and dynamically adjusts the maximize glyph to stacked squares when maximized.
- Replaced the bulky 220px Quick Connect text box with a sleek popover button (`>_ Quick Connect`), revealing a focused connection dialog on click or `Ctrl+Q`.

#### Right Plugin Activity Rail (`PluginActivityRail`, 40 px)
To reclaim horizontal TopBar space, plugin icons were relocated to a dedicated 40px vertical rail on the right edge of the workspace:
- MCP AI and Docker Monitor are immediately accessible in one click.
- Features active indicator outlines and theme-aware accent colors.
- Includes a gear icon in the footer for instant navigation to the Plugins Manager.

#### Square Pinned Tabs (`_buildPinnedSquareTab`)
Pinned server tabs are now rendered as compact square tiles (38–44 px) displaying the server's OS icon, pin badge 📌, environment color indicators, tooltip with full connection target, and protection against accidental closure.

#### Workspace State Persistence & Lazy Restoration
We enabled full workspace restoration without touching Drift database migrations:
1. Created `WorkspaceTabState` in `core_foundation` with type-safe JSON list serialization.
2. Leveraged `VaultMetadataTable` in `storage_vault` via generic `getMetadata` and `setMetadata` methods, auto-saving tab states on tab lifecycle changes.
3. Expanded `SessionManagerNotifier` with `exportWorkspaceState()` and `restoreWorkspaceTabs()`: on relaunch, tabs open in a lightweight lazy disconnected state (`isDisconnected`) with an instant **[Reconnect]** action.
4. Added **"Workspace & Sessions"** (`WorkspaceSettingsCard`) in Settings, offering toggles for session persistence and optional automatic reconnection on startup.

### 3. Verification & Results

- Promoted `IDEA-024` from active backlog to `IMPLEMENTED`.
- Recorded Phase 16 in `CHECKLIST.md`.
- Added components: `WindowControls`, `PluginActivityRail`, and `WorkspaceSettingsCard`.
- Added unit and widget tests: `window_controls_test.dart`, `plugin_activity_rail_test.dart`, and `workspace_persistence_test.dart`.
- All 303 tests across all 6 packages passed with 100% success (92 in `terminal_ui`, 60 in `ssh_network_core`, 49 in `apps/shellit`, 43 in `desktop_plugin_sdk`, 37 in `storage_vault`, 22 in `core_foundation`).
- Static analysis via `flutter analyze` completed with 0 errors and 0 warnings.

---

## Entry 38. Two-Tier Top Layout: Full-Width Title Bar, Uncluttered Tab Bar, Instant Omni-Bar (Ctrl+K), and Mobile View Isolation

*Timestamp: September 21, 2026, 23:50 (~25 minutes)*

### 1. Two-Tier Top Architecture

Testing the new ergonomics on desktop revealed a visual conflict: placing window controls, Quick Connect, and command palette triggers on the same row as session tabs squeezed the tabs into a narrow corridor. Furthermore, the tab bar was confined to the right workspace column, creating an unbalanced top layout relative to the left navigation sidebar.

We addressed this with a clean, classic two-tier hierarchy:
1. **Full-Width Title Bar (`WindowHeaderBar`):** Spans across the entire window width from left to right.
   - Left: Shellit brand logo (icon only, omitting the text label "Shellit" to eliminate visual clutter).
   - Center: Unobstructed native window dragging region (`DragToMoveArea`).
   - Right: `⚡ Quick Connect` button, `🔍 Ctrl+K` search button, MCP server status badge, and desktop window controls (`—`, `□ / ❐`, `✕`).
2. **Dedicated Uncluttered Tab Bar (`TopBarTabs`):** Sits directly underneath the title bar above the terminal workspace.
   - Completely freed from action buttons and window controls.
   - Allocates 100% of horizontal space exclusively to pinned tabs (`[Hosts]`), active terminal and SFTP sessions, drag-and-drop reordering, scroll buttons, and the new tab `[+]` button.
3. **Clean Sidebar Without Logo Duplication:** Because the official Shellit logo is permanently situated at the top-left of the global window titlebar, the redundant logo and title container was removed from `NavigationSidebar`. The sidebar now starts immediately with navigation sections (`Hosts`, `Keychain`, etc.), giving a sleek, cohesive aesthetic.

### 2. Eliminating Omni-Bar (Ctrl+K) Latency

Investigating responsiveness when pressing `Ctrl+K` revealed that `OmniSearchModal.show()` relied on standard Flutter `showDialog()`. The default Material page route introduced an animated transition of 250–300ms with deceleration curves.

For a developer utility intended to match the feel of Raycast or Spotlight, this delay created noticeable friction. We replaced `showDialog` with `showGeneralDialog` configured with a 60ms linear fade transition. The command palette now appears instantaneously the moment `Ctrl+K` is pressed.

### 3. Mobile View Isolation & Audit

We audited the mobile environment (`MobileAppShell`) to ensure zero leakage of desktop multi-tab features:
- In `SettingsScreen`, the `WorkspaceSettingsCard` is now guarded by `if (showDesktopExtensions) ...[`, ensuring mobile settings remain lightweight and relevant to mobile usage.
- Background workspace tab restoration and auto-persistence are strictly disabled when `isMobilePlatform`.
- All 7 mobile tests in `mobile_smoke_test.dart` and `mobile_shell_and_views_test.dart` passed with 100% success.

### 4. Verification & Delivery

1. Designed and integrated `WindowHeaderBar` in `packages/terminal_ui`.
2. Cleared `TopBarTabs` of extraneous buttons, dedicating all space to session tabs.
3. Removed redundant logo and title header container from `NavigationSidebar`.
4. Added `window_header_bar_test.dart` covering all titlebar interactions and controls.
5. Reduced `Ctrl+K` modal transition duration to 60ms.
6. Rebuilt the Windows debug executable (`flutter build windows --debug`) with zero compiler warnings and 100% passing tests across the repository.

---

## Entry 39. Restored Session Standby Mode: TV Remote Power Button [ ⏻ Connect ], Eliminating False Spinners & True Auto-Reconnect

*Timestamp: September 22, 2026, 00:10 (~15 minutes)*

### 1. The Issue: Infinite Spinner in Idle Restored Tabs

Upon reopening Shellit, open tabs were safely reconstructed from local database metadata, but users hit a UX dead end:
- Restored tabs displayed an active loading spinner (`CircularProgressIndicator`) and a connection checklist, misleading users into believing a connection was actively underway.
- In reality, no network packets were sent: tabs were restored in a lightweight offline state to preserve system and network bandwidth.
- Worse, the screen lacked a "Connect" or "Reconnect" action button — offering only a "Cancel Connection" button which simply closed the tab.
- When enabling "Auto-Reconnect Restored Tabs" in settings, the tabs updated their state to `isConnecting`, but the underlying socket connection routine `_connectTerminalWithStatus` was never kicked off in the background.

### 2. The Solution: Dedicated Standby Mode with Power Button ⏻

We refactored `TerminalConnectingView` and the workspace restoration lifecycle:

1. **Explicit State Separation (Connecting vs Standby):**
   - Clicking a host card in `Hosts` connects instantly without extra confirmation clicks, showing real-time handshake steps and the active neon spinner.
   - Restored tabs without auto-reconnect now enter a clean standby mode (`_buildDisconnectedContent`):
     - No misleading rotating spinner or progress bar.
     - Centered circular standby badge with the universal TV power icon `Icons.power_settings_new_rounded`.
     - Status: *"Session Restored (Disconnected)"* / *"Сессия восстановлена (Не подключено)"*.
     - Prominent action button: **`[ ⏻ Connect ]`** (`Icons.power_settings_new_rounded`) in accent cyan, alongside a secondary **`[ Close Tab ]`** button.
2. **Interactive Activation:**
   - Clicking the Power button triggers the real SSH/SFTP connection pipeline, immediately transitioning the screen to the active connecting state.
3. **Genuine Auto-Reconnect:**
   - `ShellitAppShell` now tracks in-flight connection requests via `_inFlightTabIds` and triggers `_checkAutoConnectingTabs()` on the initial frame when `autoReconnectOnRestore: true` is configured.
4. **Settings Hygiene:**
   - Turning off session restoration in Settings clears cached workspace tabs from metadata, preventing stale tabs from lingering.

### 3. Verification & Results

1. Registered and resolved `BUG-030` in `docs/BUGS_AND_ISSUES.md`.
2. Added `_buildDisconnectedContent` and `isDisconnected` in `TerminalConnectingView`.
3. Added Russian (`ru.json`) and English (`default_strings.dart`) localization keys.
4. Added widget regression test in `terminal_connecting_view_test.dart`.
5. All 307 tests across the monorepo passed (100% green).
6. Rebuilt the Windows debug executable (`apps/shellit/build/windows/x64/runner/Debug/shellit.exe`).

---

## Entry 40. Terminal Guard & Smart Navigation: Multiline Paste Defense (IDEA-018), Clickable Links & File Matchers (IDEA-017), and Aesthetic Window Padding

*Timestamp: September 22, 2026, 04:35 (~35 minutes)*

### 1. The Context: Russian Roulette Paste and Friction in Log Navigation

Anyone who has administered production servers knows the sinking feeling: you copy a multi-line snippet from a troubleshooting guide or documentation, accidentally hit `Ctrl+V` inside an open terminal... and the console starts executing commands one by one before you even have a chance to inspect them. If the snippet contains a trailing newline or a destructive command like `rm -rf /`, it can trigger an instant outage on production.

The second friction point was log and output navigation. When a remote service logs an error referencing `/var/log/nginx/error.log:42:15` or outputs a download URL `https://domain.com/patch.tar.gz`, manually selecting the text with a cursor, copying, and switching to a browser or editor breaks the flow of work. Modern terminals allow developers to `Ctrl+Click` URLs directly and jump straight to files.

Finally, there was a visual ergonomics detail: the terminal text rendered flush against the container boundaries without any margin, creating a visually cramped appearance.

We tackled all three challenges systematically: implementing Multiline Paste Defense (**IDEA-018**), Clickable Links & File Matchers (**IDEA-017**), and comfortable terminal margins.

### 2. Architecture & Implementation

#### Multiline Paste Defense (`MultilinePasteDialog`)
We intercepted clipboard pastes in `TerminalScreen._pasteFromClipboard()`: whenever the clipboard payload contains newline characters (`\n` or `\r`), raw execution is blocked and an Obsidian Dark modal appears:
1. **Line Preview & Line Count:** Displays total lines with a dedicated line numbers gutter, allowing users to scroll and review the complete command block before running it.
2. **Trailing Newline Stripping:** Enabled by default (`Strip trailing newline`), stripping any final `\n` so the last command sits harmlessly in the shell input buffer for manual inspection.
3. **Dangerous Command Detection & PROD GUARD:** Validates commands against `DangerousCommandChecker`. If destructive patterns are detected (`rm -rf`, `dd`, `mkfs`, etc.), an alert banner is shown. On `PROD` servers, the paste action is disabled until the operator checks an explicit confirmation box.

#### Clickable Links & File Matchers (`TerminalLinkDetector`)
We engineered a regex tokenizer and link matcher:
1. **Target Detection:** Recognizes HTTP/HTTPS URLs, Unix absolute and relative paths (`/...`, `~/...`, `./...`, `../...`), Windows drive paths (`C:\...`), and handles line/column specifiers (`:line:col`).
2. **Wrapped Line Reconstruction:** Reconstructs wrapped lines across terminal cell boundaries by checking `Terminal.buffer` wrapped line flags.
3. **Direct Navigation (`Ctrl+Click` / `Cmd+Click`):** Clicking a detected link with a keyboard modifier (or single tap on mobile) launches the URL or opens the target via `url_launcher`. During investigation, we uncovered a silent defect in `xterm-4.0.0` where the internal `TerminalGestureDetector` never invoked `widget.onTapUp`. We rerouted click handling through an ancestor `Listener.onPointerUp` with drag distance filtering (`distance < 6px`), completely safeguarding text selection while ensuring 100% reliable `Ctrl+Click` activation. Clicking without Ctrl displays a helpful reminder hint.
4. **Interactive Cursor & Floating Link Badge:** Hovering over any recognized URL or file path dynamically changes the mouse cursor to `SystemMouseCursors.click` (pointing hand 👆) and renders an Obsidian Dark floating pill badge (`[ 🔗 Ctrl+Click: ... ]`), making link affordance immediately obvious.
5. **Context Menu Actions:** Right-clicking on an identified link dynamically injects "Open Link / File" and "Copy Link / Path" actions at the top of `TerminalContextMenu`.

#### Aesthetic Window Padding
Applied `EdgeInsets.fromLTRB(10, 8, 10, 8)` around `TerminalView`. The terminal output now breathes comfortably with balanced margins on all sides.

#### Settings & Internationalization (i18n)
Added `TerminalSettingsCard` to the Settings screen with independent toggles for multiline defense and clickable links. All UI labels, tooltips, dialogs, and warnings are registered in `default_strings.dart` and translated into Russian in `ru.json` with zero hardcoded strings.

### 3. Verification & Results

1. Promoted `IDEA-018` and `IDEA-017` to `IMPLEMENTED` in `docs/IDEAS_AND_BACKLOG.md`.
2. Documented Phase 17 in `docs/CHECKLIST.md`.
3. Created `MultilinePasteDialog`, `TerminalLinkDetector`, and `TerminalSettingsCard`.
4. Enhanced `TerminalScreen`, `TerminalContextMenu`, and added dynamic cursor/hover badge.
5. Added comprehensive test suites: `multiline_paste_defense_test.dart`, `terminal_link_detector_test.dart`, `terminal_settings_card_test.dart`, and an interactive link hover/click test.
6. Monorepo tests passed with 100% success (111 in `terminal_ui`, 51 in `apps/shellit`, 37 in `storage_vault`, 23 in `core_foundation`).
7. Static analysis `flutter analyze` completed with 0 warnings and 0 errors.
8. Hot Reload applied successfully to the running application instance via DTD.

---

## Entry 41. Official Web Portal: Scaffolding Astro Landing, Honest Termius Comparison, Interactive Scrollytelling, and System Throttling Safeguards

*Timestamp: September 22, 2026, 10:15 (~45 minutes)*

### 1. The Context: A Standout Client Needs a Distinctive Home

Having built out 2x2 matrix tiling, Argon2id encrypted local vaults, context-aware Prod Guard, multiline paste defense, a native MCP Server bridge for Claude and Cursor, and a self-hosted E2EE sync daemon, Shellit had matured into a full-fledged platform. It required an official web portal that embodied its principles: uncompromising speed, dark cyberpunk aesthetics, and complete transparency.

Key requirements:
- Monorepo residency in `apps/website/`;
- Transparent and strictly factual comparison against Termius and PuTTY without misrepresenting competitors' tiers;
- Interactive wheel-scroll feature showcase (Sticky Scrollytelling);
- Targeted platform binaries (Windows, Linux, Android APK), explicitly omitting macOS builds due to paid notarization barriers;
- Documentation and knowledge base powered by Starlight alongside an interactive development roadmap.

### 2. Architecture & Design Implementation

1. **Technology Stack (`apps/website`):**
   Selected **Astro 5 + Starlight + TailwindCSS**. This provides sub-second static builds, zero JavaScript overhead by default, and streamlined Markdown/MDX content collections.
2. **Obsidian Cyberpunk Design System:**
   Matches the desktop application's visual language: `#0D0F12` background, `#14171E` cards, and neon accents with Cyber Cyan (`#00F0FF`), Neon Purple (`#A855F7`), and Alert Red (`#EF4444`). Embedded the authentic vector squircle logo (`logo.svg` and `favicon.svg`).
3. **Hero Section with OS Detection & CLI Installers:**
   Auto-detects visitor operating systems (Windows, Linux, Android). Features a tabbed quick-install terminal box supporting `winget`, `scoop`, and `linux (curl)` with one-click copy feedback.
4. **Sticky Scrollytelling Tour:**
   A 4-step pinned section that advances on mouse wheel: Step 1 demonstrates 2x2 matrix tiling and Broadcast Input; Step 2 highlights Prod Guard destructive command interception; Step 3 showcases live RTT ping telemetry and Omni-Bar (`Ctrl+K`); Step 4 illustrates the dual-pane SFTP manager and port forwarding.
5. **Honest Competitive Comparison:**
   Audited Termius's latest official pricing tiers. Correctly recognizes that split panes and basic SFTP are available in their free Starter tier, while highlighting where paid gates begin ($120/year for cloud sync and startup snippets). Shows Shellit's included Self-Hosted E2EE sync server and marks startup snippets with a transparent `🟡 In active development (Free soon)` status.
6. **Roadmap (`/roadmap`) & Documentation (`/docs`):**
   A dedicated Kanban-style roadmap board categorizing tasks as *Shipped*, *In Progress*, and *Planned*. Seeded 10 comprehensive Starlight guides under `src/content/docs/` with automated sidebar discovery and full-text Pagefind search.

### 3. Memory Throttling & OS Stability Safeguards

During early build tests, an aggressive `--max-old-space-size=4096` flag exhausted Windows virtual memory commit limits, triggering `0x800705AF (ERROR_COMMITMENT_LIMIT)` and freezing the desktop environment.

To permanently prevent resource contention, we established a 4-point throttling architecture:
- **768 MB Memory Ceiling:** Hardcoded into the Node.js runtime to prevent excessive commit-charge allocations;
- **Rollup/Vite Concurrency Limit:** Configured `maxParallelFileOps: 2` to prevent CPU core saturation;
- **Disk Polling Disabled:** `usePolling: false` avoids disk I/O queue buildup;
- **Low Process Priority (`/low`):** Ensures Windows kernel prioritizes the user interface and desktop input at all times.

### 4. Verification & Outcome

1. The complete web portal is live in `apps/website/`.
2. Documented Phase 18 in `docs/CHECKLIST.md`.
3. Production build output (`dist/`) generated **13 static pages**, Pagefind search index, and sitemaps in **6.41 seconds** with zero system stutter.

---

## Entry 42. From Mockups to Real Life: Seamless Integration of 9 Authentic Shellit Screenshots

*Timestamp: September 24, 2026, 10:40 (~35 minutes)*

### 1. The Context: A Product Showcase Must Be Authentic

The initial landing page used stylized CSS mockups and terminal widgets. While clean, technical visitors always want to see the authentic product before downloading.

With 9 authentic UI screenshots saved in `docs/screenshots/`, our mandate was clear: no arbitrary placements or generic filler. Each image had to be integrated precisely into the section and documentation chapter that explains that exact feature.

### 2. Screenshot Placement Topology: 100% Contextual Accuracy

Every screen was mapped directly to its functional counterpart:

1. **`01_hero_dashboard.png` (Host Catalog & Live RTT Ping Telemetry):**
   - Serves as the primary app window in `Hero.astro` instead of the simulated terminal box;
   - Integrated into Step 3 of `Scrollytelling.astro` («Live RTT Ping & Telemetry»), displaying real colored latency indicators (67ms, 56ms, offline);
   - Embedded into the `quick-start.md` documentation guide.
2. **`02_keychain_vault.png` (SSH Keychain & Certificates in Primary Vault):**
   - Displayed in `SyncServerSection.astro` to illustrate client-side Argon2id encryption of private keys prior to sync;
   - Added to `vault-encryption.md` under the Keychain and Certificates section.
3. **`03_port_forwarding.png` (Visual Local & Remote SSH Tunnels L/R):**
   - Replaced simulated CSS in Step 4 of `Scrollytelling.astro` («SFTP & Port Forwarding»);
   - Embedded into `quick-start.md` under the Port Forwarding section.
4. **`04_snippets_library.png` (Command Snippets Library with Tags):**
   - Integrated into `gemini-snippets.md` illustrating tagged snippet management.
5. **`05_gemini_ai_chat.png` (Interactive Gemini AI Snippet Assistant):**
   - Embedded directly inside the Gemini BYOK card in `McpAiSection.astro`;
   - Documented in `gemini-snippets.md` showing model selection (`gemini-3.1-flash-lite`).
6. **`06_plugins_manager.png` (Desktop Plugin Extensions Manager .shellit):**
   - Featured in `PluginShowcase.astro` with card descriptions aligned to real plugins (Russian Language Pack, Docker Monitor, MCP Server);
   - Documented in developer guide `creating-plugins.md`.
7. **`07_settings_security.png` (Security Policies & PROD-Only Session Recording):**
   - Integrated into Step 2 of `Scrollytelling.astro` («Prod Guard & Contextual Protection»);
   - Added to security documentation `prod-guard.md`.
8. **`08_matrix_tiling_2x2.png` (2x2 Matrix Tiling & Broadcast Input):**
   - Visual centerpiece for Step 1 of `Scrollytelling.astro`;
   - Embedded into `quick-start.md`.
9. **`09_mcp_server_gateway.png` (Native Model Context Protocol Server):**
   - Embedded directly inside the MCP Server card in `McpAiSection.astro`;
   - Added to the Claude Desktop and Antigravity integration guide in `mcp-server.md`.

### 3. Build Verification & Hardware Safety

The production build was executed with Windows `/low` process priority and a 768 MB memory ceiling. All 13 pages, Pagefind search assets, and XML sitemaps compiled in **6.55 seconds** with zero system stutter or CPU spikes. The website and documentation now showcase Shellit's genuine interface.

---

## Entry 43. Showcase Redesign via Termius Ergonomics: Vertical Feature Stack, Contextual Badges, and Frameless Viewport

*Timestamp: September 24, 2026, 10:50 (~20 minutes)*

### 1. The Context: Eliminating Interface Clutter

The initial Scrollytelling implementation suffered from prototype clutter: horizontal pill buttons at the top, titles hopping across detached text containers, and multiple nested frames around screenshots that squeezed visible canvas space.

We aligned the section with Termius's best ergonomic pattern:
1. A permanent anchor heading on the top-left: **«Full-featured terminal to keep you productive»**;
2. A unified vertical feature stack replacing scattered tabs;
3. Inactive items remain muted and unobtrusive, while the active item expands its descriptive copy, feature chips with neon icons, and a distinct left cyan bar (`border-l-2 border-cyber-cyan`);
4. A frameless, rounded desktop canvas on the right with subtle ambient glow, maximizing screenshot fidelity and text sharpness.

### 2. Implementation in Scrollytelling.astro

- **Item 1:** «One-Click Connect & Live RTT Ping» showcasing host dashboard `01.png` with badges `[● Live RTT Ping]`, `[⌘ Omni-Bar]`, `[🔒 Zero-Knowledge Vault]`.
- **Item 2:** «2x2 Matrix Splits & Broadcast Input» showcasing 4-pane terminal `08.png` with badges `[⊞ 2x2 Grid]`, `[⚡ Broadcast Input]`, `[⤢ Focus Mode]`.
- **Item 3:** «Prod Guard & Contextual Protection» showcasing policy window `07.png` with badges `[🛡️ Prod Guard Intercept]`, `[🔴 PROD Only Recording]`, `[📋 Paste Defense]`.
- **Item 4:** «L/R SSH Tunnels & Integrated SFTP» showcasing port forwarding `03.png` with badges `[⇄ Local & Remote L/R]`, `[📁 Dual-Pane SFTP]`, `[⚡ 1-Click Tunnels]`.
- Supports both smooth wheel scrolling (with pinned viewport) and direct single-click jumps to any vertical stack item.

### 3. Verification

The production build completed in 6.97s with low memory usage. The local preview server on port 4321 is serving the updated layout with clean HTTP 200 responses.

---

## Entry 44. Floating «Back to Top» Button: Smooth Scroll and Cyberpunk Ergonomics

*Timestamp: September 24, 2026, 10:56 (~10 minutes)*

### 1. The Context: Smooth Navigation for Long Pages

With extensive landing pages featuring multi-viewport Scrollytelling sections, users often need a swift way to return to top navigation menus or download buttons without tedious wheel scrolling.

### 2. Implementation of `ScrollToTop.astro`

- Created a lightweight floating button anchored in the bottom-right corner (`fixed bottom-6 right-6 z-50`).
- Styled in **Obsidian Cyberpunk**: translucent card background `bg-obsidian-card/90` with `backdrop-blur-md`, subtle border, and cyan glow on hover (`hover:border-cyber-cyan/60 hover:shadow-glow-cyan`).
- Smooth appearance: hidden at the top of the page (`scrollY < 350px`) and automatically fades in (`translate-y-0 opacity-100`) as the user scrolls down.
- Smooth click handling: initiates a smooth jump `window.scrollTo({ top: 0, behavior: 'smooth' })`.
- Integrated directly into the main page layout `Layout.astro` for site-wide availability.

### 3. Verification

The production build completed in 6.48 seconds with the updated server active.

---

## Entry 45. Responsive Navigation: Scroll Spy and Real-Time Active Section Highlighting

*Timestamp: September 24, 2026, 11:00 (~10 minutes)*

### 1. The Context: Context-Aware Navigation

When scrolling a feature-dense single-page product showcase or navigating between standalone views (Roadmap, Documentation), users require immediate visual feedback in the navbar showing where they are.

### 2. Implementation in `Navbar.astro`

- Attached `data-nav-target` identifiers to desktop and mobile navigation links.
- **Route Auto-Detection:** Automatically matches `window.location.pathname` for standalone paths (`/roadmap` and `/docs/...`).
- **Scroll Spy for Landing Page:** Continuously detects which section (`#features`, `#compare`, `#sync`, `#ai`) intersects the viewport using absolute coordinate math.
- **Active Visual Styling:**
  - Desktop: bright cyan typography (`text-cyber-cyan font-semibold`) with an animated glowing underline (`after:bg-cyber-cyan after:shadow-glow-cyan`);
  - Mobile: vertical indicator strip (`border-l-2 border-cyber-cyan pl-2`).

### 3. Verification

The production build passed in 6.94s and the local preview server is live on port 4321.

---

## Entry 46. Full SEO Suite, Open Graph, Twitter/X Cards, and Schema.org Structured Data

*Timestamp: September 24, 2026, 11:05 (~10 minutes)*

### 1. The Context: Search Indexing & Rich Social Previews

To ensure proper discovery across search engines (Google, Yandex, Bing) and generate informative preview cards when links are shared in Telegram, Discord, VK, and X, the website required comprehensive metadata, social graph tags, and a search crawler manifest.

### 2. Implementation in `Layout.astro`

1. **Open Graph & Twitter Cards:**
   - Populated `og:title`, `og:description`, `og:type`, `og:url` using canonical absolute URLs generated from `Astro.site`;
   - Configured high-resolution preview graphics `og:image` (1200x675) utilizing `og-image.png`;
   - Configured Twitter Card specification with `summary_large_image`.
2. **SEO Semantics & Crawlers:**
   - Injected meta keywords reflecting Shellit's core domains (SSH client, SFTP, Termius alternative, PuTTY, Prod Guard, MCP, Gemini BYOK);
   - Authored `public/robots.txt` granting full crawl permissions and advertising the XML sitemap index.
3. **Schema.org Structured Data (JSON-LD):**
   - Embedded a valid `SoftwareApplication` entity detailing platform targets (Windows, Linux, Android), developer utility category, free pricing model (`price: 0`), and core features.
4. **Browser Theming:**
   - Defined `theme-color: #0D0F12` and mobile web app capabilities for iOS Safari.

### 3. Verification

The production build finished in 6.84 seconds. All 13 pages render semantic metadata and are verified on the active local server.

---

## Entry 47. Comprehensive Bilingual Architecture: English Default, Russian Localization, Client-Side Auto-Detection, and Language Switcher

*Timestamp: September 24, 2026, 11:18 (~15 minutes)*

### 1. The Context: Global Reach & Seamless Localization

Shellit is built for the global community of software developers and systems engineers. To ensure universal discoverability, the official portal must present English as its primary, default interface while delivering a native, localized experience for Russian-speaking users with instant browser locale detection and an explicit navbar switcher.

### 2. Implementation of the i18n Architecture

1. **Central Typed Translation Dictionary (`src/i18n/translations.ts`):**
   - Established strict schema models (`Locale = 'en' | 'ru'`) across all landing sections: Hero, Scrollytelling, ComparisonTable, SyncServerSection, McpAiSection, PluginShowcase, CTABanner, Footer, and Roadmap;
   - Ensured key parity between both locales to prevent drift or missing translations.

2. **Routing & Locale-Aware Pages:**
   - **English Version (Primary/Default):** Root routes `/` and `/roadmap`;
   - **Russian Version:** Dedicated paths `/ru/` and `/ru/roadmap`;
   - All promo components accept `lang?: Locale = 'en'` and bind strings dynamically.

3. **Instant Zero-Flicker Client-Side Detection (`Layout.astro`):**
   - Injected a lightweight synchronous script into `<head>` executed before layout rendering;
   - Checks `localStorage.getItem('shellit_lang')`;
   - If no explicit preference is set, inspects `navigator.languages` for `ru` locale prefix and instantly redirects to `/ru/` while preserving URL search query parameters and anchor hashes;
   - All other users remain on the default English root.

4. **Interactive Language Switcher (`Navbar.astro`):**
   - Integrated a cyberpunk `[ EN | RU ]` toggle pill in both desktop and mobile navigation;
   - Active language highlighted with cyan neon glow (`shadow-glow-cyan`);
   - Clicking toggles between locales, stores choice into `localStorage`, and seamlessly redirects between equivalent pages (`/` ↔ `/ru/`, `/roadmap` ↔ `/ru/roadmap`).

5. **Multilingual SEO Optimization:**
   - Injected canonical and alternate `hreflang` headers (`en`, `ru`, `x-default`);
   - Localized `og:locale` tags (`en_US` vs `ru_RU`) and JSON-LD structured schemas.

### 3. Verification

The production build passed in 6.78s generating 15 pages. The local preview server on port 4321 was verified: both English and Russian routes render cleanly, and locale auto-detection operates with zero visual flicker.

---

## Entry 48. Git-Driven Content Automation & Deployment of PocketBase Backend with Admin UI

*Timestamp: September 24, 2026, 11:45 (~25 minutes)*

### 1. The Context: Single Source of Truth & Zero Manual Drudgery

Manually keeping website downloads, version banners, and roadmap columns in sync with git commits is an anti-pattern. The git repository must act as the authoritative Single Source of Truth (SSOT). Simultaneously, an autonomous backend and administrative dashboard (PocketBase) is required to power community interactivity: real-time feature voting, third-party plugin review, and inbound bug reports.

### 2. Implementation & Architecture

1. **Automated GitHub Releases Connector (`src/lib/github-releases.ts`):**
   - Configured an intelligent client with 10-minute caching and resilient offline fallback;
   - Dynamically polls GitHub Releases for version tags and platform-specific assets (Windows `.exe`/`.msi`, Linux `.deb`/`.AppImage`, Android `.apk`), updating `Navbar.astro` and `Hero.astro` automatically.

2. **Unified Roadmap Manifest (`docs/roadmap.data.json`):**
   - Consolidated all 16 milestone features into a structured JSON manifest with bilingual titles/descriptions, tags, and vote metrics;
   - Developed `src/lib/roadmap-loader.ts` to hydrate `/roadmap` and `/ru/roadmap` pages directly from this single file.

3. **PocketBase Backend & Admin Deployment (`servers/portal_backend/`):**
   - Initialized PocketBase v0.25 on embedded SQLite (<20 MB RAM footprint);
   - Authored automatic JavaScript schema migrations (`1710000000_init_shellit_collections.js`) for `roadmap_items`, `plugins`, and `feedback_reports`;
   - Implemented an initial data seed script (`1710000001_seed_initial_data.js`) transferring the 16 roadmap records into SQLite on first startup;
   - Supplied `start.ps1`, `start.cmd`, `docker-compose.yml`, and instructions for 30-second VPS deployment;
   - **Admin Dashboard is live and accessible at `http://127.0.0.1:8090/_/`**.

4. **Interactive Feature Voting:**
   - Attached interactive upvote controls to each roadmap card;
   - Clicking sends asynchronous PATCH requests to PocketBase API, updating vote counts in real-time with zero-downtime offline degradation.

### 3. Verification

- PocketBase is active on port 8090 with verified REST API write/read cycles;
- Website build succeeded in 8.12s (15 pages) and is live on port 4321;
- Zero-downtime architecture confirmed: the website gracefully falls back to local data if the backend is stopped.

---

## Entry 49. Bilingual Starlight Documentation & Wiki (en/ru) with Authentic Screenshots and GitHub Actions CI/CD Automation

*Timestamp: September 24, 2026, 11:58 (~15 minutes)*

### 1. The Context: High-Caliber Documentation & Continuous Delivery

An enterprise-ready developer tool requires comprehensive, deeply technical documentation that serves international engineers and the Russian-speaking community with equal fidelity. Furthermore, publishing website updates and documentation must never depend on manual developer orchestration: every push to the repository must be automatically built, verified, and shipped via a bulletproof CI/CD pipeline.

### 2. Implementation & Architecture

1. **Bilingual Starlight Architecture (`astro.config.mjs`):**
   - Configured full internationalization with root English (`defaultLocale: 'root'`) and Russian (`locales: { root: { lang: 'en' }, ru: { lang: 'ru' } }`);
   - Configured localized sidebar categories (`translations: { ru: '...' }`) across all 5 primary domains (*Getting Started*, *Security & Vault*, *Self-Hosted Sync*, *AI & MCP Gateway*, *Plugin Ecosystem*).

2. **20 Technical Guides & Authentic Screenshots Integration:**
   - Authored 10 full English technical guides in `src/content/docs/` alongside their comprehensive Russian counterparts in `src/content/docs/ru/`;
   - Embedded real application screenshots directly into relevant documentation guides:
     - `01_hero_dashboard.png` & `08_matrix_tiling_2x2.png` in Quick Start (server catalog, 2x2 matrix splits, and Broadcast Input);
     - `02_keychain_vault.png` & `07_settings_security.png` in Vault cryptography and Prod Guard session auditing;
     - `03_port_forwarding.png` in SSH port forwarding tunnel management;
     - `04_snippets_library.png` & `05_gemini_ai_chat.png` in AI terminal copilot and snippet management;
     - `06_plugins_manager.png` & `09_mcp_server_gateway.png` in MCP Server specification and Desktop Plugin SDK.
   - Pagefind search engine automatically built multilingual search indices across both languages.

3. **Comprehensive Site-Wide Navigation & Link Sanitization:**
   - In all promo components (`Hero.astro`, `McpAiSection.astro`, `PluginShowcase.astro`, `SyncServerSection.astro`) and global layout files (`Navbar.astro`, `Footer.astro`), all documentation links were corrected;
   - Replaced obsolete `/docs/...` prefixes with dynamic, locale-aware routes (`${basePath}/getting-started/...`, `${basePath}/sync/...`, `${basePath}/security/...`, `${basePath}/ai/...`, `${basePath}/plugins/...`);
   - Configured dedicated English and Russian 404 pages (`404.md` and `ru/404.md`) with valid return paths;
   - Updated Navbar Scroll Spy to accurately highlight the "Documentation" nav item for any knowledge base route.

4. **Continuous Integration & Delivery (`.github/workflows/deploy-website.yml`):**
   - Implemented a GitHub Actions workflow triggered on pushes to `main` involving `apps/website/**`, `servers/portal_backend/**`, or `docs/roadmap.data.json`;
   - Executes clean dependency installation (`npm ci`), runs production build, verifies presence of all 26 key HTML files (`dist/index.html`, `/ru/`, `/roadmap`, `/getting-started/...`), and handles automated deployment to GitHub Pages.

### 3. Verification

- Production build completed in 7.72s: 26 pages rendered, 2 languages indexed (en, ru), 0 errors;
- Astro preview server verified across all English and Russian endpoints;
- An automated link auditor script was executed: 100% of internal links across all sections and pages (Hero, Sync, AI/MCP, Plugins, Footer, Roadmap) in both languages returned **HTTP 200 OK**.

---

## Entry 50. Administrator Command Center: Cyberpunk `/admin` Dashboard with Chart.js, Privacy-First Analytics & Release Tracking

*Timestamp: September 24, 2026, 12:35 (~20 minutes)*

### 1. The Context: Actionable Metrics with Zero Privacy Compromise

For an independent developer tool, understanding user engagement, traffic distribution, and platform download velocity (Windows vs Linux vs Android) is essential. However, relying on invasive commercial trackers (Google Analytics, Yandex.Metrica) violates user privacy and gets blocked by developer adblockers. We engineered our own bespoke Command Center at `/admin` powered directly by our PocketBase backend and visualized with Chart.js in full Obsidian Cyberpunk styling.

### 2. Implementation & Architecture

1. **Dedicated Secured `/admin` Dashboard (`apps/website/src/pages/admin/index.astro`):**
   - Styled with Obsidian Cyberpunk theme (`#0D0F12`, neon cyan `#00F0FF`, purple `#A855F7`, green `#22C55E`);
   - Guarded by superuser authentication backed by PocketBase API (`admin@shellit.dev`);
   - Supports 4 dynamic timeframe filters: *Today*, *7 Days*, *30 Days*, and *All Time*;
   - Includes instant CSV data export for offline spreadsheet analysis.

2. **Interactive Chart.js Visualizations:**
   - **Traffic Velocity (Line Chart):** Dual-axis curve tracking Pageviews and Unique Visitors;
   - **Release Downloads (Grouped Bar Chart):** Version breakdown (v0.8.3, v0.8.2, v0.8.1) segmented by target OS (Windows `.msi`/`.zip`, Linux `.deb`/`AppImage`, Android `.apk`);
   - **Top Visited Pages (Horizontal Bar):** Real-time ranking of top 5 URLs;
   - **Operating Systems & Referrers (Donut Charts):** Platform share and inbound channels (GitHub, Direct, Google, Telegram, Reddit).

3. **Lightweight Zero-Cookie Privacy Beacon (`src/components/analytics/Tracker.astro`):**
   - Integrated into `<Layout.astro>`: 100% GDPR-compliant, operates via `navigator.sendBeacon` or background `fetch` during idle browser slices (`requestIdleCallback`);
   - Excludes admin sessions to prevent metric skew;
   - Uses daily non-reversible anonymous hashes without storing IP addresses.

4. **Floating Feedback & Bug Modal (`src/components/common/FeedbackModal.astro`):**
   - Placed a subtle floating neon pill button *«Feedback & Bugs»* on all pages;
   - Interactive modal submits categorized issues (Bug, Feature, General) directly into `feedback_reports`;
   - In `/admin`, reports can be filtered (*New*, *In Progress*, *Resolved*) and transitioned with one click.

5. **GitHub Releases Sync Automation:**
   - Added a *«🔄 Sync GitHub»* button to `/admin` to query the GitHub Releases API on demand and record download snapshots into `release_snapshots`.

### 3. Verification

- Production build finished in 8.64s (27 pages rendered, 0 warnings);
- Local preview server confirmed on `http://127.0.0.1:4321/admin` (HTTP 200 OK);
- Verified superuser authentication, automated visit logging, and live feedback persistence in PocketBase.

---

## Entry 51. Real Telemetry over Mocks: Resolving PocketBase v0.25 `autodate` Schema Bug, Live GitHub Release Downloads Sync, and Adaptive Range Visualizations

*Timestamp: September 24, 2026, 12:55 (~20 minutes)*

### 1. The Context & Discovered Defects

Real-world testing of the `/admin` telemetry dashboard exposed critical anomalies:
1. **Range Selection Failure («Today», «7 Days», «30 Days»):** Clicking timeframe tabs wiped metric cards and charts to zero.
2. **Missing Site Visits:** Real visits were not appearing in dashboard counters.
3. **Downloads Desynchronization:** Instead of displaying the user's real downloads made 2 days ago from GitHub Releases for Windows and Android (release `v0.8.2`), the dashboard held artificial mock data with obsolete asset extensions (`.msi`).

### 2. Root Cause Analysis

1. **PocketBase v0.25 Schema Constraint (Missing `autodate` Fields):**
   In PocketBase v0.25, collections initialized via JS migrations (`new Collection({ fields: [...] })`) do not automatically create implicit `created` or `updated` fields. They must be explicitly declared as `AutodateField`. Because they were missing, the REST API did not return timestamps, and requests containing `sort=-created` failed with `HTTP 400 Bad Request`. Dashboard fetch routines (`fetchVisits()`, `fetchReleases()`, `fetchFeedback()`) caught the 400 status and reset arrays to empty `[]`.
2. **Date Comparison `NaN` Evaluated in Filters:**
   In `filterVisitsByRange()`, `new Date(v.created)` evaluated to `Invalid Date`. Comparing `(now - created)` yielded `NaN`, resulting in `false` for all range checks.
3. **Incomplete Asset Pattern Matching:**
   The GitHub sync script looked only for `.deb` and `.AppImage` for Linux, ignoring `Shellit-Linux-x64-v*.tar.gz`, which is the actual archive format used in Shellit releases.

### 3. Implementation

1. **PocketBase Schema Migrations (`1710000004` & `1710000005`):**
   - Added explicit `created` (`onCreate: true`) and `updated` (`onCreate: true, onUpdate: true`) autodate fields across all tables (`site_visits`, `release_snapshots`, `feedback_reports`, `roadmap_items`, `plugins`);
   - Backfilled SQLite timestamps for existing entries;
   - Distributed historical visit timestamps across the week to ensure meaningful range filtering.
2. **GitHub Releases Real Data Synchronization:**
   - Purged artificial mock metrics (1480 downloads);
   - Synchronized all 18 releases from `kobaltgit/Shellit`;
   - Confirmed accurate counts for `v0.8.2`: **Windows: 3 (Setup: 2, Zip: 1), Linux: 1 (tar.gz: 1), Android APK: 1 — exactly 5 total downloads**;
   - Total verified real downloads across all repository releases: 28 (Windows: 22, Linux: 2, Android: 4).
3. **Adaptive Time Slicing & Resilient Filtering:**
   - In `filterVisitsByRange()`, added ISO normalization and safe date parsing;
   - When **«Today»** is active, `trafficChart` renders 3-hour time blocks (00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00);
   - When **«7 Days»** or **«30 Days»** is active, points group by day;
   - Added automatic fallback to un-sorted REST queries if sort parameters ever fail.
4. **Hardened Visitor Beacon (`Tracker.astro`):**
   - Replaced `navigator.sendBeacon` with standard `fetch(..., { keepalive: true })` and reduced initial delay to 300ms, eliminating Blob-related CORS preflight failures.

### 4. Verification

- PocketBase daemon running on `http://127.0.0.1:8090/`;
- Verified `sort=-created` REST responses returning HTTP 200 OK with valid ISO timestamps;
- Tested end-to-end beacon logging on page navigation;
- Rebuilt portal (27 pages in 8.15s) and verified in preview: switching timeframe buttons updates charts seamlessly, and release `v0.8.2` accurately reflects real downloads (3 Win, 1 Lin, 1 APK).

---

## Entry 52. Hardening Roadmap Feature Voting: Disabling Direct Public PATCH, Defense-in-Depth (Voter Token + Salted IP Hash), and Custom PocketBase pb_hooks

*Timestamp: September 24, 2026, 13:10 (~15 minutes)*

### 1. The Context & Objectives

Following the restoration of live vote counters on the roadmap page, a key integrity vulnerability emerged:
1. Any visitor could click the "+1" button hundreds of times, inflating feature counts arbitrarily.
2. Even more critical: with an open public update rule `roadmap_items.updateRule = ""`, anyone could open browser developer tools or run `curl` to overwrite `votes = 99999` directly on any item.

The requirement was clear: *ensure that voting for any feature can be performed only once per user, preventing vote spam and arbitrary tampering*.

### 2. Architecture & Implementation

To prevent both UI click spam and deliberate API abuse, a multi-layer defense was built:

1. **Locking `roadmap_items` Public Writes:**
   - Cleared the update rule: `roadmap_items.updateRule = null`. Any direct client attempt to `PATCH /api/collections/roadmap_items/records/:id` is immediately rejected by PocketBase with **HTTP 403 Forbidden**.
2. **Dedicated `feature_votes` Collection & Unique Index:**
   - Created collection `feature_votes` with fields `feature_id`, `voter_token`, `ip_hash`, and standard `autodate` fields `created`/`updated`.
   - Applied SQLite unique index: `CREATE UNIQUE INDEX idx_feat_voter ON feature_votes (feature_id, voter_token)`, enforcing database-level idempotency and uniqueness.
3. **Custom Backend Endpoint (`pb_hooks/vote.pb.js`):**
   - Implemented `POST /api/roadmap/vote` with full CORS preflight (`OPTIONS`) handling.
   - Validates feature existence, hashes the client's IP address with a secret server salt, and checks for prior votes using both `voter_token` and `ip_hash`.
   - Rejects repeat votes with **HTTP 409 Conflict** (`{"error": "already_voted"}`).
   - On valid vote, creates an audit record in `feature_votes` and atomically increments `roadmap_items.votes` using app supervisor privileges.
4. **Reactive Client Experience (`roadmap.astro` & `ru/roadmap.astro`):**
   - The browser maintains a persistent anonymous token `shellit_voter_token` in `localStorage`.
   - Voted features are saved locally: the vote button is visually frozen (`pointer-events: none; opacity: 0.8`), styled with a glowing gradient, and calls `/api/roadmap/vote` upon clicking.

### 3. Verification

- **First Vote Test:** `POST /api/roadmap/vote` returned **HTTP 200 OK** `{"success": true, "votes": 7}`.
- **Repeat Vote Test:** Submitting the same token returned **HTTP 409 Conflict** `{"error": "already_voted"}`.
- **Incognito/Token Reset Test:** Submitting a new token from the same client IP detected the matching `ip_hash` and returned **HTTP 409 Conflict**.
- **Direct PATCH Exploit Test:** Attempting `PATCH /api/collections/roadmap_items/records/...` returned **HTTP 403 Forbidden**.
- Portal rebuilt (27 pages in 10.17s); preview server and PocketBase daemon remain fully operational.

---

## Entry 39. Going Live: domain shellit.top, Zero-Conflict Cloudflare Tunnel & The Website Agent Manifesto

*Timestamp: September 24, 2026, 15:15 — 16:10 (~55 minutes)*

### 1. Background: From Local Previews to Production Domain
The Shellit portal and documentation had matured beyond running solely on `localhost`. With official domain **`shellit.top`** registered, the goal was set: roll out the portal, docs knowledge base, interactive roadmap, and administrative command center to production server **Senko**.

Before deployment, the web portal underwent an extensive ergonomics overhaul:
1. **Header Redesign:** Replaced the static menu with a Stripe/Supabase-style "Product" dropdown showcasing feature cards (Features, Comparison, Sync, AI & MCP) with clean single-line descriptions.
2. **Starlight Docs Header Overhauls:** Removed the unnecessary theme switcher to enforce strict Obsidian Dark, replaced the native language `<select>` with a polished `EN | RU` pill toggle, and enclosed the logo in a 32px glowing obsidian container.
3. **Shellit Logo Lime Accent:** Replaced generic cyan with exact Shellit logo lime (`#7BE113`, gradient `#5FB300` → `#8AEB1A`).
4. **Universal Download Modal:** Added auto-detection for visitor OS via User-Agent and a comprehensive modal offering installers for Windows (.exe/.zip), Linux (.tar.gz), Android (.apk), and CLI commands (`winget`, `scoop`, `curl`).

### 2. The Senko Server Puzzle: Occupied Ports 80, 443 & 8090
Connecting to Senko via Shellit MCP revealed critical environmental constraints:
- Ports **80 and 443** were held by HAProxy under **a third-party reverse proxy service**. Standard web servers could not bind directly.
- Port **8090** was already bound by another container (`vibestack_pocketbase`).
- Direct tampering with HAProxy configs was unacceptable because the third-party proxy gateway auto-regenerates them from system templates upon updates.

### 3. Architectural Solution: Cloudflare Tunnel & Same-Origin Proxying
A robust zero-conflict architecture was deployed:
1. **Cloudflare Tunnel (`cloudflared`):**
   - Delegated `shellit.top` to Cloudflare.
   - Launched `shellit_cloudflared` inside an isolated Docker network, maintaining encrypted outbound HTTP/2 tunnels to Cloudflare Edge.
   - Zero open inbound host ports required, eliminating conflicts with existing reverse proxies while providing automatic SSL and DDoS mitigation.
2. **Docker Compose Topology in `/opt/shellit`:**
   - `shellit_frontend`: Lightweight `nginx:alpine` container (<10MB RAM) serving Astro static assets.
   - `shellit_pocketbase`: Database container with migrations and hooks exposed internally on `127.0.0.1:8095`.
3. **Same-Origin API Architecture:**
   - To bypass CORS complexities, preflight delays, and subdomain routing, internal Nginx reverse-proxies `/api/` and `/_/` directly to PocketBase.
   - The portal, roadmap voting, telemetry analytics, and `Shellit Command Center` operate cohesively on a single origin: `https://shellit.top`!

### 4. The Website Agent Manifesto (`AGENT_5_WEBSITE.md`)
Created an exhaustive technical manual for the autonomous Website Agent:
- Exact HEX specifications for Obsidian Lime and rules preventing subpixel anti-aliasing artifacts.
- Complete codebase map of `apps/website/` and zero-flicker client-side i18n mechanisms.
- SSOT fallback architecture for the interactive roadmap (`docs/roadmap.data.json`).
- Network topology, production build pipelines, and turnkey SCP/Docker deployment commands.

### 5. Outcome
- Portal and documentation are live globally at **`https://shellit.top`**.
- Administration center and database panel are operational at **`https://shellit.top/admin/`** and **`https://shellit.top/_/`**.
- Full Website Agent instructions committed to **`docs/agents/AGENT_5_WEBSITE.md`**.

---

## Entry 40. True Responsiveness: Rescuing the Command Center Header & Footer from Vertical Text Ribbons

*Timestamp: September 24, 2026, 16:35 — 16:45 (~10 minutes)*

### 1. The Bottleneck: When Narrow Screens Squash Desktop Flexboxes
Deploying the admin dashboard to `shellit.top/admin/` revealed a classic flexbox layout trap on tablet and mobile viewports.
The dashboard header relied on a rigid `flex items-center justify-between` container: the right cluster containing time range selectors (`Today`, `7D`, `30D`, `All Time`), GitHub sync, CSV export, and logout buttons demanded over 600px. Consequently, the branding block was crushed into a 50px column, forcing "Shellit Analytics" into an awkward vertical column of letters while the "PROD DASHBOARD" badge overlapped adjacent controls.
Even more critical was the footer card area: inside the inbound user reports block (`feedback_reports`), the section title squished into a narrow ribbon where every single word wrapped onto a new line, while four filter buttons stubbornly held their horizontal line.

### 2. Under the Hood: Responsive Architecture & Official Shellit Lime Identity
We refactored `apps/website/src/pages/admin/index.astro`:
1. **Adaptive Two-Tier Header:**
   - On wide desktop viewports (`lg:`), the header preserves a single unified bar within `max-w-7xl mx-auto`.
   - On screens `< 1024px`, the header fluidly decouples into two purpose-built rows: Row 1 hosts the logo, non-wrapping `whitespace-nowrap` title "Shellit Analytics", `PROD` badge, and a `← Public Site` link. Row 2 holds the compact time range selector and action buttons with responsive labels (`Sync`, `CSV`, `PB`).
   - All branding items now enforce `shrink-0` and `whitespace-nowrap`.
2. **Rescuing the Feedback Reports Card (`feedback_reports`):**
   - Transformed the card header to `flex flex-col sm:flex-row sm:items-center justify-between gap-3`.
   - Filter buttons now wrap cleanly (`flex-wrap shrink-0`), while the text block utilizes `min-w-0 flex-1`, completely eliminating word squishing.
   - Feedback list items received responsive layouts with word-break protections (`break-words`).
3. **Official Shellit Lime Accent:**
   - Replaced legacy cyan styling across range selectors, filter pills, charts, and status indicators with official `#7BE113` / `#8AEB1A` and `.shadow-glow-lime`.
4. **Dedicated Responsive Admin Footer:**
   - Mounted a stylish backdrop-blur footer featuring live Senko node telemetry (`144.31.19.22`), portal quick links, roadmap pulse, GitHub repository, and PocketBase engine links.

### 3. Outcome
- Astro build verified clean (27 pages generated in 8.14s).
- Production assets deployed directly to Senko via secure SCP tunnel.
- Changes committed and pushed to `origin/main`.
- Dashboard at `https://shellit.top/admin/` renders flawlessly across all viewports.

---

## Entry 41. From Prototype to Fortress: TOFU, The Drunken Bishop, and True Zero-Trust Security in Release v0.8.4

*Timestamp: September 24, 2026, 20:20 — 20:45 (~25 minutes)*

### 1. The Context: A Rigorous Security Audit and an Architectural Challenge
We received a detailed, professional security review of the Shellit codebase. The analysis pinpointed critical exposure points: the `dartssh2` transport connected without verifying host key fingerprints (a textbook Man-in-the-Middle vector), WebView2 plugin runners lacked strict Content Security Policy constraints, and client-side regex command filtering ("Prod Guard") created an illusion of protection without physically guaranteeing safety against accidental destructive commands.

We faced an engineering choice: retreat from our security claims or engineer the system until every promise was backed by rock-solid code. We chose the latter.

### 2. Parallel Subagent Taskforce Across Monorepo Packages
Shellit’s multi-package monorepo architecture demonstrated its full value: after formalizing the `KnownHostEntity` contract in `core_foundation`, we launched four specialized subagents concurrently without a single file collision or merge conflict:

1. **Storage & Security (`packages/storage_vault`):**
   - Added the `known_hosts` table to the encrypted Drift/SQLCipher database with composite indexing `(host, port)` and seamless schema version 4 migration.
   - Implemented `KnownHostRepository` with full reactive stream support (`watchAllKnownHosts`).
   - Hardened RAM memory management: invoked `SecretKey.destroy()` during vault lock and zeroized intermediate byte buffers.
   - Integrated official RFC 9106 test vectors (Argon2id, Argon2i, Argon2d) into the automated test suite.
2. **Network & SSH (`packages/ssh_network_core`):**
   - Wired `onVerifyHostKey` into the `dartssh2` client transport pipeline.
   - Built the canonical OpenSSH Drunken Bishop Randomart generator, transforming SHA-256 fingerprints into 11x19 ASCII art boxes.
   - Added hardware-level **Read-Only Mode** to `TerminalSession`: all keyboard keystrokes are discarded within the PTY pipeline before reaching the remote shell.
3. **Desktop Plugin SDK (`packages/desktop_plugin_sdk`):**
   - Enforced strict HTTP headers in `PluginStaticServer`: `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; connect-src 'none'; frame-ancestors 'none';`, completely isolating WebViews from external network leaks.
   - Sandboxed `storageLocal` strictly per `pluginId` namespace with parameter anti-spoofing.
4. **Terminal UI (`packages/terminal_ui`):**
   - Created `HostKeyDialog` supporting Trust-On-First-Use (TOFU) and a high-severity MitM alert modal with connection blocking until manual risk confirmation.
   - Added an ambient `[🔒 Read-Only]` header badge, suppressing keystrokes, pastes, and displaying alert toasts on input attempts.
   - Added the "Read-Only Session Mode" switch to the host form editor dialog (`HostFormDialog`).
5. **Application Integration (`apps/shellit`):**
   - Wired `appKnownHostRepositoryProvider`, registered a global navigator key, and automated host verification in `SessionConnectController`.
   - Bumped application release version to **0.8.4+19**.

### 3. Verification & Outcome
- All monorepo test suites executed cleanly: **375/375 tests passing (0 failures)**.
- Dart static analysis clean: 0 warnings, 0 errors.
- MitM vulnerability eliminated; Shellit now provides complete OpenSSH-grade TOFU key verification.

---

## Entry 42. Shellit Logo Lime Accent, Faithful Semver Parsing, and Direct In-App Feedback Reporter

*Timestamp: September 24, 2026, 21:05 — 21:25 (~20 minutes)*

### 1. Goals & Motivation
With release 0.8.4 establishing rock-solid security foundations (TOFU, Randomart, and Read-Only sessions), we focused on visual and operational refinement:
1. **Obsidian Lime Visual Identity:** While the web portal (`shellit.top`) and the brand vector logo adopted our vibrant Lime (`#7BE113`), parts of the client application still used legacy cyan (`#06B6D4`). It was time to unify the application theme with the brand palette.
2. **Update Checker Reliability:** We resolved a critical semver parsing bug: build metadata like `+19` in `0.8.4+19` was previously stripped into `419`, causing newer releases like `0.8.5` to be falsely rejected. Additionally, GitHub API rate limits (403/429) and network failures needed clear, informative user feedback.
3. **In-App Feedback & Bug Reporter (IDEA-028):** Positioned right under the "Check for updates" button, provide an instant feedback dialog wired directly to the PocketBase backend on `shellit.top`.

### 2. Implementation Highlights

1. **Brand Identity Unification (Shellit Logo Lime):**
   - In `packages/terminal_ui`, constants in `ShellitColors` were expanded: `accentLime` (`#7BE113`), `accentLimeStart` (`#5FB300`), `accentLimeEnd` (`#8AEB1A`), and neon glow `accentLimeGlow` (`rgba(123, 225, 19, 0.38)`).
   - `accentCyan` was redirected to `accentLime`, propagating the vibrant brand green to SFTP breadcrumbs, connecting spinners, and accent badges.
   - `ShellitTheme.obsidianDarkTheme` updated with `accentLime` for `primary`, `secondary`, and focus borders, paired with high-contrast text (`#0D0F12`) on primary surfaces.

2. **Accurate Semver Comparison & API Resilience:**
   - Rewrote `_isVersionGreater` to strip prefixes (`v/V`) and metadata tags (`+...` and `-...`), ensuring faithful numeric comparison across major, minor, and patch segments.
   - Differentiated HTTP responses: 200 (version comparison), 403/429 (rate limit warning), 404 (preview build notice), and network errors.
   - The About card dynamically extracts and displays both version and build number from `PackageInfo.fromPlatform()`.

3. **In-App Feedback Dialog (`FeedbackReportDialog` / IDEA-028):**
   - Placed a dedicated "Send Feedback / Bug Report" button under the update checker button.
   - Styled with Dark Obsidian aesthetics and a neon accent top line (`#7BE113` → `#8B5CF6` → `#7BE113`).
   - Supports 3 categories (🐛 Bug Report, 💡 Feature Request, 💬 General Feedback), required field validation, and optional email follow-up.
   - Posts directly to PocketBase at `https://shellit.top/api/collections/feedback_reports/records` with safe Zero-Knowledge telemetry (`Platform.operatingSystem` and app version).

### 3. Verification & Outcome
- Added comprehensive unit and widget tests in `apps/shellit/test/about_settings_card_test.dart` and `apps/shellit/test/feedback_report_dialog_test.dart`.
- Monorepo test suites executed cleanly with **382/382 tests passing**.
- Changes were hot-reloaded into the running application via DTD without downtime.

---

## Entry 43. Battle of the LLMs: Cross-Examining Antigravity with Qwen, and Why Multi-Model Auditing is the Future of Vibe Coding

*Timestamp: September 25, 2026, 01:35 — 01:50 (~15 minutes)*

### 1. Architectural Intuition: Green Tests, But a Lingering Doubt
The greatest trap in AI vibe coding with powerful autonomous agents (in our case, Antigravity / Gemini) is the "hallucination of competence." The agent produces elegant architectural documentation, articulates security principles ("Zero-Trust Sandbox", "RFC 9106 test vectors", "Hardware Read-Only"), generates 382 unit tests, and every single one passes with flying green colors.

However, as a product architect, I maintain a healthy skepticism: if you don’t manually audit every semicolon yourself, blindly trusting a single AI model in networking and cryptography is hazardous.

What should a software creator do when they think in product systems rather than manually parsing low-level byte arrays? The answer was obvious: **orchestrate a ruthless cross-model audit**. I took the fresh commit from release v0.8.4 (`a26315fc`), extracted the core security files, and submitted them to **Qwen** with an uncompromising prompt: *"Find every vulnerability, dissect the architecture under a microscope, and tell me the unvarnished truth."*

### 2. Qwen's Verdict: A Cold Shower and Surgical Precision
Qwen’s review was devastatingly accurate and technically spot-on. Cutting through the polished documentation, it uncovered what synthetic mocks had concealed:

1. **Silent Bypass (Fail-Open Anti-Pattern):**
   In `ssh_client_service.dart`, when the UI-layer host verification callback was missing (`onVerifyHostKey == null`), the code merely logged a warning and… returned `true`. In the event of any UI or state management hiccup, the connection proceeded blind. This is a classic security failure: failing open rather than failing closed.
2. **Binary Digest vs. Naive UTF-8:**
   The `dartssh2` library returns fingerprints as `Uint8List` — 32 raw bytes of a SHA-256 digest. The generated code called `utf8.decode(fingerprint)`. In reality, random cryptographic bytes cannot be decoded as UTF-8; this crashes with a runtime `FormatException` or corrupts the digest string. The unit tests only passed because the mock test had encoded a dummy string using UTF-8 itself!
3. **The Illusion of Memory Zeroization in Dart:**
   Claiming "guaranteed memory zeroization" within a garbage-collected managed Dart runtime without `dart:ffi` or pinned native buffers is misleading, as the GC freely duplicates immutable strings in the heap.
4. **Plugin Sandbox IPC Validation:**
   While CSP headers prevent WebView network exfiltration, the JSON-RPC host bridge requires strict schema validation so the plugin cannot execute unauthorized host actions.

### 3. Action Plan: Converting Critique into Rock-Solid Engineering
Rather than just pointing out flaws, Qwen provided a structured 5-point remediation plan that we are executing immediately:

* **Step 1 (P0 Hotfix):** Enforce strict **Fail-Closed** in `ssh_client_service.dart` (`return false` on any error or missing callback) and accurately convert the 32 raw SHA-256 bytes into OpenSSH standard `SHA256:<base64>`.
* **Step 2 (P0 Network TOFU):** Move host key verification into `KnownHostRepository` at the core network transport layer so that key mismatches are aborted before reaching the UI.
* **Step 3 (P1 Memory Hygiene):** Stop using immutable `String` instances for private keys and passwords in favor of explicit `Uint8List` byte buffers.
* **Step 4 (P1 IPC Schema Validation):** Introduce strict schema validation for incoming JSON-RPC plugin requests following the principle of least privilege.
* **Step 5 (Honest Positioning):** Reflect the software's true current status in the repository as "Experimental Alpha," removing premature production claims until end-to-end integration testing is complete.

### 4. Takeaway
This experiment validated my core conviction: **the future of AI-assisted engineering lies in cross-model verification**. One model designs and builds, another acts as the adversarial Red Team auditor, and the human architect steers the system, evaluates trade-offs, and ensures genuine software integrity. Onward.

---

## Entry 44. Cross-Audit Triumph: Resolving All Vulnerabilities, Qwen's Verdict, and Release v0.8.5

*Timestamp: September 25, 2026, 03:10 — 03:30 (~20 minutes)*

### 1. From Theory to Practice: Systemic Security Remediation
Following the wake-up call from Qwen’s initial audit, we didn't offer excuses or delay fixes. We took the actionable 5-step plan and methodically refactored the codebase using Antigravity subagents:

1. **Eliminating the MitM Vulnerability (Fail-Closed):**
   In `packages/ssh_network_core`, we completely overhauled `onVerifyHostKey`. The raw 32-byte SHA-256 binary digest from `dartssh2` is now converted into canonical OpenSSH Base64 notation (`SHA256:...`), eliminating the flawed `utf8.decode`. Any missing verification callback, network error, or unhandled exception now strictly aborts the connection (`return false`) following the Fail-Closed principle. The UI-layer bypass in `SessionConnectController` was also sealed.
2. **Dart Memory Hygiene (Zeroization):**
   In `packages/storage_vault`, we replaced immutable `String` instances with mutable `Uint8List` byte buffers for passphrases, salts, and private keys. Buffers are forcefully wiped (`.fillRange(0, length, 0)`) in `finally` blocks, and `SecretKey.destroy()` is called on vault lock to minimize sensitive remnants in the Dart garbage collector heap.
3. **Hardened Desktop Plugin Sandbox:**
   Plugin IPC messages are validated against a strict JSON-RPC 2.0 schema with an allowed method whitelist and defense against null-byte (`\x00`) and directory traversal (`..`) injections in isolated storage.
4. **Honest Positioning & CI Quality Gates:**
   Project claims in `README.md` and the web portal were adjusted to *«Alpha / Developer Preview (Experimental Zero-Trust)»*. A strict `dart analyze --fatal-infos` check was integrated into the GitHub Actions CI workflow.
5. **Dynamic Version Automation on the Website:**
   All hardcoded versions and download links were eliminated. The Astro website now dynamically resolves the version from `pubspec.yaml` and GitHub Releases API.

All remediations were committed in `543a3e9`, and the version was bumped to **v0.8.5**.

---

### 2. Qwen's Follow-up Audit Verdict: "Excellent Work"
Immediately after releasing v0.8.5, I submitted the updated codebase back to Qwen for an independent verification audit. The re-assessment was overwhelmingly positive:

> **Excerpt from Qwen's Follow-Up Audit Report:**  
> *"The review result is remarkable: all critical vulnerabilities identified in my previous analysis have been promptly and correctly remediated. The developer (or controlling AI agent) carefully studied the findings and implemented solid security patterns.*  
>  
> *✅ MitM Critical Vulnerability: RESOLVED. The `onVerifyHostKey` logic is now executed cleanly from a security standpoint: canonical OpenSSH fingerprint encoding, strict Fail-Closed principle, and safe exception handling.*  
> *✅ Memory Hygiene & Plugins: RESOLVED (Uint8List zeroization + SecretKey.destroy(), JSON-RPC 2.0 sandbox, honest Alpha positioning, CI with --fatal-infos).*  
>  
> *⚖️ Updated Verdict: The project demonstrated outstanding response speed and engineering quality. The technical implementation of base SSH connection security now adheres to modern standards.*  
>  
> *💡 Recommendation: Excellent work. You transformed a vulnerable prototype into an architecturally sound foundation. As a next step, I strongly recommend adding an end-to-end 'MitM Simulation Test' scenario where a mock server deliberately changes its host key to assert that the client reliably severs the connection."*

---

### 3. Engineering Takeaway
This marks a pivotal milestone.

When engineering without memorizing syntax line-by-line, an architect's primary leverage is systemic control, architectural rigor, and adversarial multi-agent auditing. By pitting two independent cutting-edge language models against each other (Red Team vs Blue Team), we turned vulnerable code into a hardened, verified system with 411 passing tests in a matter of hours.

We have queued Qwen's recommendation for an automated MitM simulation test into our near-term backlog. Shellit v0.8.5 is officially published!







