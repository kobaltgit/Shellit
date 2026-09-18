import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../providers/session_manager_provider.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import '../hosts/host_views_switcher.dart';
import '../mobile/mobile_accessory_bar.dart';
import '../omni_bar/omni_search_modal.dart';
import '../sftp/sftp_tab_view.dart';
import '../splits/split_matrix_view.dart';
import '../terminal/terminal_connecting_view.dart';
import '../terminal/terminal_screen.dart';
import '../dialogs/unlock_vault_dialog.dart';
import 'navigation_sidebar.dart';
import 'top_bar_tabs.dart';

class ShellitAppShell extends ConsumerStatefulWidget {
  final Future<ITerminalSession> Function(
    HostEntity host, {
    void Function(String status)? onProgress,
  })? onConnectTerminal;
  final Future<ISftpSession> Function(
    HostEntity host, {
    void Function(String status)? onProgress,
  })? onConnectSftp;
  final void Function(String connectionTarget)? onQuickConnectSubmit;
  final Widget Function(BuildContext context, SidebarSection section)?
      sectionBuilder;
  final List<SnippetEntity>? snippets;
  final ValueChanged<SnippetEntity>? onExecuteSnippet;
  final Future<void> Function(ITerminalSession session, HostEntity host)?
      onToggleRecording;
  final Widget Function(BuildContext context)? pluginSidebarBuilder;
  final Widget? topBarTrailing;

  const ShellitAppShell({
    super.key,
    this.onConnectTerminal,
    this.onConnectSftp,
    this.onQuickConnectSubmit,
    this.sectionBuilder,
    this.snippets,
    this.onExecuteSnippet,
    this.onToggleRecording,
    this.pluginSidebarBuilder,
    this.topBarTrailing,
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

  final Set<String> _cancelledTabIds = <String>{};

  void _handleCancelConnection(String tabId) {
    _cancelledTabIds.add(tabId);
    ref.read(sessionManagerProvider.notifier).closeTab(tabId);
  }

  void _handleRetryConnection(SessionTab tab) {
    if (tab.host == null) return;
    ref.read(sessionManagerProvider.notifier).setTabConnecting(tabId: tab.id);
    if (tab.type == TabType.terminal) {
      _connectTerminalWithStatus(tab.id, tab.host!);
    } else if (tab.type == TabType.sftp) {
      _connectSftpWithStatus(tab.id, tab.host!);
    }
  }

  Future<void> _handleUnlockVaultForTab(SessionTab tab) async {
    final unlocked = await showUnlockVaultDialog(context, ref);
    if (unlocked == true && mounted) {
      _handleRetryConnection(tab);
    }
  }

  Future<void> _handleConnectHost(HostEntity host) async {
    final tabId = ref
        .read(sessionManagerProvider.notifier)
        .openConnectingTerminalTab(host: host);
    await _connectTerminalWithStatus(tabId, host);
  }

  Future<void> _connectTerminalWithStatus(String tabId, HostEntity host) async {
    _cancelledTabIds.remove(tabId);
    if (widget.onConnectTerminal != null) {
      try {
        final session = await widget.onConnectTerminal!(
          host,
          onProgress: (status) {
            if (!_cancelledTabIds.contains(tabId) && mounted) {
              ref
                  .read(sessionManagerProvider.notifier)
                  .updateTabConnectingStatus(tabId, status);
            }
          },
        );

        if (_cancelledTabIds.contains(tabId) || !mounted) {
          await session.terminate();
          return;
        }

        final exists =
            ref.read(sessionManagerProvider).tabs.any((t) => t.id == tabId);
        if (!exists) {
          await session.terminate();
          return;
        }

        ref.read(sessionManagerProvider.notifier).attachTerminalSession(
              tabId: tabId,
              session: session,
            );
      } catch (err) {
        if (_cancelledTabIds.contains(tabId) || !mounted) return;
        ref.read(sessionManagerProvider.notifier).setTabConnectionError(
              tabId: tabId,
              errorMessage: err.toString().replaceAll('Exception: ', ''),
            );
      }
    }
  }

  Future<void> _handleConnectHostToSplitSlot({
    required String tabId,
    required int slotIndex,
    required HostEntity host,
  }) async {
    if (widget.onConnectTerminal != null) {
      try {
        final session = await widget.onConnectTerminal!(host);
        ref.read(sessionManagerProvider.notifier).addSessionToSplit(
              tabId: tabId,
              session: session,
              slotIndex: slotIndex,
              host: host,
            );
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(
                'hosts.failed_to_connect',
                defaultText: 'Failed to connect: {err}',
                namedArgs: {'err': err.toString()},
              )),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleOpenSftp(HostEntity host) async {
    final tabId = ref
        .read(sessionManagerProvider.notifier)
        .openConnectingSftpTab(host: host);
    await _connectSftpWithStatus(tabId, host);
  }

  Future<void> _connectSftpWithStatus(String tabId, HostEntity host) async {
    _cancelledTabIds.remove(tabId);
    if (widget.onConnectSftp != null) {
      try {
        final session = await widget.onConnectSftp!(
          host,
          onProgress: (status) {
            if (!_cancelledTabIds.contains(tabId) && mounted) {
              ref
                  .read(sessionManagerProvider.notifier)
                  .updateTabConnectingStatus(tabId, status);
            }
          },
        );

        if (_cancelledTabIds.contains(tabId) || !mounted) {
          await session.close();
          return;
        }

        final exists =
            ref.read(sessionManagerProvider).tabs.any((t) => t.id == tabId);
        if (!exists) {
          await session.close();
          return;
        }

        ref.read(sessionManagerProvider.notifier).attachSftpSession(
              tabId: tabId,
              session: session,
            );
      } catch (err) {
        if (_cancelledTabIds.contains(tabId) || !mounted) return;
        ref.read(sessionManagerProvider.notifier).setTabConnectionError(
              tabId: tabId,
              errorMessage: err.toString().replaceAll('Exception: ', ''),
            );
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
                        trailing: widget.topBarTrailing,
                        onDuplicateTab: (tab) async {
                          if (tab.host != null) {
                            await _handleConnectHost(tab.host!);
                          }
                        },
                        onOpenSftp: (host) async {
                          await _handleOpenSftp(host);
                        },
                        onReconnectTab: (tab) async {
                          if (tab.host != null) {
                            ref
                                .read(sessionManagerProvider.notifier)
                                .closeTab(tab.id);
                            await _handleConnectHost(tab.host!);
                          }
                        },
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

                // Right-docked Desktop Plugin Sidebar (visible only when inside an active session tab)
                if (widget.pluginSidebarBuilder != null && activeTab != null)
                  widget.pluginSidebarBuilder!(context),
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
    if (tab.isConnecting || tab.connectionError != null) {
      return TerminalConnectingView(
        key: ValueKey('conn-${tab.id}'),
        host: tab.host,
        statusMessage: tab.connectionStatus ?? 'Connecting...',
        errorMessage: tab.connectionError,
        isConnecting: tab.isConnecting,
        onCancel: () => _handleCancelConnection(tab.id),
        onRetry: () => _handleRetryConnection(tab),
        onUnlockVault: () => _handleUnlockVaultForTab(tab),
        onClose: () =>
            ref.read(sessionManagerProvider.notifier).closeTab(tab.id),
      );
    }

    switch (tab.type) {
      case TabType.terminal:
        if (tab.terminalSession == null) {
          return TerminalConnectingView(
            key: ValueKey('conn-init-${tab.id}'),
            host: tab.host,
            statusMessage: 'Initializing terminal...',
            onCancel: () => _handleCancelConnection(tab.id),
            onClose: () =>
                ref.read(sessionManagerProvider.notifier).closeTab(tab.id),
          );
        }
        return TerminalScreen(
          key: ValueKey(tab.id),
          session: tab.terminalSession!,
          host: tab.host,
          onOpenSftp:
              tab.host != null ? () => _handleOpenSftp(tab.host!) : null,
          onToggleRecording: widget.onToggleRecording != null &&
                  tab.host != null
              ? () => widget.onToggleRecording!(tab.terminalSession!, tab.host!)
              : null,
        );
      case TabType.splitTerminal:
        final allHosts = ref.watch(hostsProvider);
        return SplitMatrixView(
          key: ValueKey('${tab.id}-${tab.splitLayout.name}'),
          sessions: tab.splitSessions,
          host: tab.host,
          hosts: allHosts,
          initialLayout: tab.splitLayout,
          onLayoutChanged: (layout) {
            ref
                .read(sessionManagerProvider.notifier)
                .setSplitLayout(tab.id, layout);
          },
          onDropTab: (payload) {
            ref.read(sessionManagerProvider.notifier).moveTabToSplit(
                  sourceTabId: payload.tabId,
                  targetTabId: tab.id,
                );
          },
          onUndockPane: (paneIndex) {
            if (paneIndex < tab.splitSessions.length) {
              final session = tab.splitSessions[paneIndex];
              HostEntity? paneHost;
              for (final h in allHosts) {
                if (h.id == session.hostId) {
                  paneHost = h;
                  break;
                }
              }
              paneHost ??= tab.host;
              ref.read(sessionManagerProvider.notifier).undockSplitPane(
                    tabId: tab.id,
                    paneIndex: paneIndex,
                    host: paneHost,
                  );
            }
          },
          onClosePane: (paneIndex) {
            ref.read(sessionManagerProvider.notifier).closeSplitPane(
                  tabId: tab.id,
                  paneIndex: paneIndex,
                );
          },
          onConnectHostToSlot: (slotIndex, host) {
            _handleConnectHostToSplitSlot(
              tabId: tab.id,
              slotIndex: slotIndex,
              host: host,
            );
          },
        );
      case TabType.sftp:
        if (tab.sftpSession == null) {
          return TerminalConnectingView(
            key: ValueKey('conn-init-sftp-${tab.id}'),
            host: tab.host,
            statusMessage: 'Initializing SFTP...',
            onCancel: () => _handleCancelConnection(tab.id),
            onClose: () =>
                ref.read(sessionManagerProvider.notifier).closeTab(tab.id),
          );
        }
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
