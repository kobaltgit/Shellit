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
