import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';
import '../hosts/host_views_switcher.dart';
import '../mobile/mobile_accessory_bar.dart';
import '../omni_bar/omni_search_modal.dart';
import '../sftp/sftp_tab_view.dart';
import '../splits/split_matrix_view.dart';
import '../terminal/terminal_screen.dart';
import 'navigation_sidebar.dart';
import 'top_bar_tabs.dart';

class ShellitAppShell extends ConsumerStatefulWidget {
  final Future<ITerminalSession> Function(HostEntity host)? onConnectTerminal;
  final Future<ISftpSession> Function(HostEntity host)? onConnectSftp;
  final void Function(String connectionTarget)? onQuickConnectSubmit;
  final Widget Function(BuildContext context, SidebarSection section)?
      sectionBuilder;
  final List<SnippetEntity>? snippets;
  final ValueChanged<SnippetEntity>? onExecuteSnippet;

  const ShellitAppShell({
    super.key,
    this.onConnectTerminal,
    this.onConnectSftp,
    this.onQuickConnectSubmit,
    this.sectionBuilder,
    this.snippets,
    this.onExecuteSnippet,
  });

  @override
  ConsumerState<ShellitAppShell> createState() => _ShellitAppShellState();
}

class _ShellitAppShellState extends ConsumerState<ShellitAppShell> {
  SidebarSection _currentSection = SidebarSection.hosts;
  bool _isSidebarCollapsed = false;
  final FocusNode _shellFocusNode =
      FocusNode(canRequestFocus: false, skipTraversal: true);
  late final PingMonitorNotifier _pingNotifier;

  @override
  void initState() {
    super.initState();
    _pingNotifier = ref.read(pingMonitorProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pingNotifier.startMonitoring();
    });
  }

  @override
  void dispose() {
    _shellFocusNode.dispose();
    _pingNotifier.stopMonitoring();
    super.dispose();
  }

  void _openOmniBar() {
    OmniSearchModal.show(
      context,
      onSelectHost: _handleConnectHost,
      snippets: widget.snippets,
      onExecuteSnippet: widget.onExecuteSnippet ?? _handleExecuteSnippet,
    );
  }

  void _handleExecuteSnippet(SnippetEntity snippet) {
    final activeTab = ref.read(sessionManagerProvider).activeTab;
    if (activeTab?.terminalSession != null) {
      final cmd = snippet.command.endsWith('\n')
          ? snippet.command
          : '${snippet.command}\n';
      activeTab!.terminalSession!.inputStream
          .add(Uint8List.fromList(utf8.encode(cmd)));
    }
  }

  Future<void> _handleConnectHost(HostEntity host) async {
    if (widget.onConnectTerminal != null) {
      try {
        final session = await widget.onConnectTerminal!(host);
        ref.read(sessionManagerProvider.notifier).openTerminalTab(
              host: host,
              session: session,
            );
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: $err')),
          );
        }
      }
    }
  }

  Future<void> _handleOpenSftp(HostEntity host) async {
    if (widget.onConnectSftp != null) {
      try {
        final session = await widget.onConnectSftp!(host);
        ref.read(sessionManagerProvider.notifier).openSftpTab(
              host: host,
              session: session,
            );
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open SFTP: $err')),
          );
        }
      }
    }
  }

  void _handleQuickConnect(String target) {
    if (widget.onQuickConnectSubmit != null) {
      widget.onQuickConnectSubmit!(target);
    } else {
      // Find matching host or create transient host
      final hosts = ref.read(hostsProvider);
      final found = hosts
          .where((h) => h.hostname == target || h.connectionTarget == target);
      if (found.isNotEmpty) {
        _handleConnectHost(found.first);
      } else {
        // Parse user@host:port
        String user = 'root';
        String host = target;
        int port = 22;

        if (host.contains('@')) {
          final parts = host.split('@');
          user = parts[0];
          host = parts[1];
        }
        if (host.contains(':')) {
          final parts = host.split(':');
          host = parts[0];
          port = int.tryParse(parts[1]) ?? 22;
        }

        final now = DateTime.now();
        final transientHost = HostEntity(
          id: 'transient-${now.millisecondsSinceEpoch}',
          label: target,
          hostname: host,
          port: port,
          username: user,
          authType: HostAuthType.password,
          createdAt: now,
          updatedAt: now,
        );
        _handleConnectHost(transientHost);
      }
    }
  }

  KeyEventResult _handleGlobalKeys(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;

      // Ctrl+K / Cmd+K -> Omni-Bar
      if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
        _openOmniBar();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionManagerProvider);
    final activeTab = sessionState.activeTab;

    return Focus(
      focusNode: _shellFocusNode,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handleGlobalKeys,
      child: Scaffold(
        backgroundColor: ShellitColors.obsidianBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            final effectiveSidebarCollapsed =
                _isSidebarCollapsed || isSmallScreen;

            return Row(
              children: [
                // Left Navigation Sidebar
                NavigationSidebar(
                  currentSection: _currentSection,
                  isCollapsed: effectiveSidebarCollapsed,
                  onSectionSelected: (section) {
                    setState(() {
                      _currentSection = section;
                    });
                    ref.read(sessionManagerProvider.notifier).showCatalog();
                  },
                  onToggleCollapse: isSmallScreen
                      ? null
                      : () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                ),

                // Main Content Workspace
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar & Tabs
                      TopBarTabs(
                        onQuickConnect: _handleQuickConnect,
                        onOmniBarOpen: _openOmniBar,
                      ),

                      // Workspace Body (Preserved across tabs & catalog)
                      Expanded(
                        child: _buildWorkspaceStack(sessionState),
                      ),

                      // Mobile Accessory Bar on touch devices or small screens
                      if ((defaultTargetPlatform == TargetPlatform.android ||
                              defaultTargetPlatform == TargetPlatform.iOS ||
                              isSmallScreen) &&
                          activeTab != null &&
                          activeTab.type != TabType.sftp)
                        MobileAccessoryBar(
                          onKeyPress: (key) {
                            if (activeTab.terminalSession != null) {
                              activeTab.terminalSession!.inputStream
                                  .add(Uint8List.fromList(key.codeUnits));
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkspaceStack(SessionManagerState sessionState) {
    int currentIndex = 0;
    if (sessionState.activeTabId != null) {
      final foundIndex =
          sessionState.tabs.indexWhere((t) => t.id == sessionState.activeTabId);
      if (foundIndex != -1) {
        currentIndex = foundIndex + 1;
      }
    }

    return IndexedStack(
      index: currentIndex,
      children: [
        // Index 0: Catalog / Sidebar views (Hosts, Keychain, Settings, etc.)
        _buildCatalogView(),
        // Index 1..N: Active tabs (Terminal, Split, SFTP)
        for (final tab in sessionState.tabs) _buildSessionTabWidget(tab),
      ],
    );
  }

  Widget _buildSessionTabWidget(SessionTab tab) {
    switch (tab.type) {
      case TabType.terminal:
        return TerminalScreen(
          key: ValueKey(tab.id),
          session: tab.terminalSession!,
          host: tab.host,
          onOpenSftp:
              tab.host != null ? () => _handleOpenSftp(tab.host!) : null,
        );
      case TabType.splitTerminal:
        return SplitMatrixView(
          key: ValueKey(tab.id),
          sessions: tab.splitSessions,
          host: tab.host,
          initialLayout: tab.splitLayout,
        );
      case TabType.sftp:
        return SftpTabView(
          key: ValueKey(tab.id),
          host: tab.host!,
          sftpSession: tab.sftpSession!,
        );
    }
  }

  Widget _buildCatalogView() {
    if (widget.sectionBuilder != null &&
        _currentSection != SidebarSection.hosts) {
      return widget.sectionBuilder!(context, _currentSection);
    }

    switch (_currentSection) {
      case SidebarSection.hosts:
        return HostViewsSwitcher(
          onConnect: _handleConnectHost,
          onOpenSftp: _handleOpenSftp,
        );
      default:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction,
                size: 48,
                color: ShellitColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                '${_currentSection.name.toUpperCase()} View',
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Under construction',
                style:
                    TextStyle(color: ShellitColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        );
    }
  }
}
