import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/folders_provider.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../providers/session_manager_provider.dart';
import '../../providers/vault_provider.dart';
import '../../theme/shellit_theme.dart';
import '../app_shell/navigation_sidebar.dart';
import '../dialogs/unlock_vault_dialog.dart';
import '../hosts/host_form_dialog.dart';
import '../terminal/terminal_connecting_view.dart';
import 'mobile_hosts_view.dart';
import 'mobile_terminal_screen.dart';

class MobileAppShell extends ConsumerStatefulWidget {
  final Future<ITerminalSession> Function(
    HostEntity host, {
    void Function(String status)? onProgress,
  })? onConnectTerminal;
  final void Function(String connectionTarget)? onQuickConnectSubmit;
  final Widget Function(BuildContext context, SidebarSection section)?
      sectionBuilder;

  const MobileAppShell({
    super.key,
    this.onConnectTerminal,
    this.onQuickConnectSubmit,
    this.sectionBuilder,
  });

  @override
  ConsumerState<MobileAppShell> createState() => _MobileAppShellState();
}

class _MobileAppShellState extends ConsumerState<MobileAppShell> {
  int _currentNavIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _cancelledTabIds = <String>{};
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
    _searchController.dispose();
    _pingNotifier.stopMonitoring();
    super.dispose();
  }

  void _handleCancelConnection(String tabId) {
    _cancelledTabIds.add(tabId);
    ref.read(sessionManagerProvider.notifier).closeTab(tabId);
  }

  void _handleRetryConnection(SessionTab tab) {
    if (tab.host == null) return;
    ref.read(sessionManagerProvider.notifier).setTabConnecting(tabId: tab.id);
    _connectTerminalWithStatus(tab.id, tab.host!);
  }

  Future<void> _handleUnlockVaultForTab(SessionTab tab) async {
    final unlocked = await showUnlockVaultDialog(context, ref);
    if (unlocked == true && mounted) {
      _handleRetryConnection(tab);
    }
  }

  Future<void> _handleConnectHost(HostEntity host) async {
    // Single session on mobile: close existing tabs if any
    final existingTabs = ref.read(sessionManagerProvider).tabs;
    for (final t in existingTabs) {
      ref.read(sessionManagerProvider.notifier).closeTab(t.id);
    }

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

  void _handleQuickConnect(String target) {
    if (widget.onQuickConnectSubmit != null) {
      widget.onQuickConnectSubmit!(target);
      return;
    }

    final hosts = ref.read(hostsProvider);
    final found = hosts
        .where((h) => h.hostname == target || h.connectionTarget == target);
    if (found.isNotEmpty) {
      _handleConnectHost(found.first);
    } else {
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

  void _showQuickConnectBottomSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ShellitColors.obsidianSidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: ShellitColors.accentCyan),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('omni.quick_connect',
                        defaultText: 'Quick Connect'),
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  color: ShellitColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'user@hostname:22',
                  hintStyle: const TextStyle(color: ShellitColors.textMuted),
                  filled: true,
                  fillColor: ShellitColors.obsidianCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ShellitColors.border),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    Navigator.of(ctx).pop();
                    _handleQuickConnect(val.trim());
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final val = controller.text.trim();
                  if (val.isNotEmpty) {
                    Navigator.of(ctx).pop();
                    _handleQuickConnect(val);
                  }
                },
                child: Text(
                  context.tr('hosts.action_connect', defaultText: 'Connect'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddHostDialog() async {
    final keyManager = ref.read(keyManagerProvider);
    final keys = await keyManager?.getAllKeys() ?? [];
    final folders = ref.read(foldersProvider);

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => HostFormDialog(
        availableKeys: keys,
        availableFolders: folders,
        onCreateFolder: (name) async {
          final res =
              await ref.read(foldersProvider.notifier).createFolder(name: name);
          return res.valueOrNull;
        },
        onSave: (newHost, password) async {
          if (password != null && password.isNotEmpty && keyManager != null) {
            final credId = 'cred_${newHost.id}';
            await keyManager.savePasswordCredential(
              id: credId,
              label: 'Password for ${newHost.label}',
              password: password,
            );
            newHost = newHost.copyWith(credentialRefId: credId);
          }
          await ref.read(hostsProvider.notifier).addHost(newHost);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionManagerProvider);
    final activeTab = sessionState.activeTab;
    final vaultState = ref.watch(vaultProvider);

    // If there is an active session or connecting tab, render full-screen terminal
    if (activeTab != null) {
      if (activeTab.isConnecting || activeTab.connectionError != null) {
        return Scaffold(
          backgroundColor: ShellitColors.obsidianBackground,
          body: SafeArea(
            child: TerminalConnectingView(
              host: activeTab.host,
              statusMessage: activeTab.connectionStatus ?? 'Connecting...',
              errorMessage: activeTab.connectionError,
              isConnecting: activeTab.isConnecting,
              onCancel: () => _handleCancelConnection(activeTab.id),
              onRetry: () => _handleRetryConnection(activeTab),
              onUnlockVault: () => _handleUnlockVaultForTab(activeTab),
              onClose: () => ref
                  .read(sessionManagerProvider.notifier)
                  .closeTab(activeTab.id),
            ),
          ),
        );
      }

      if (activeTab.terminalSession != null) {
        return MobileTerminalScreen(
          session: activeTab.terminalSession!,
          host: activeTab.host,
          onDisconnect: () {
            ref.read(sessionManagerProvider.notifier).closeTab(activeTab.id);
          },
          onReconnect: activeTab.host != null
              ? () {
                  final host = activeTab.host!;
                  ref
                      .read(sessionManagerProvider.notifier)
                      .closeTab(activeTab.id);
                  _handleConnectHost(host);
                }
              : null,
        );
      }
    }

    // Otherwise render 3-tab Mobile Navigation
    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: _buildAppBar(context, vaultState),
      body: _buildCurrentSectionBody(),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton(
              backgroundColor: ShellitColors.accentBlue,
              foregroundColor: Colors.white,
              onPressed: _openAddHostDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: ShellitColors.obsidianSidebar,
        indicatorColor: ShellitColors.accentBlue.withValues(alpha: 0.25),
        onDestinationSelected: (index) {
          setState(() {
            _currentNavIndex = index;
            _isSearching = false;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dns_outlined),
            selectedIcon:
                const Icon(Icons.dns, color: ShellitColors.accentBlue),
            label: context.tr('sidebar.nav_hosts', defaultText: 'Hosts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.key_outlined),
            selectedIcon:
                const Icon(Icons.key, color: ShellitColors.accentBlue),
            label: context.tr('sidebar.nav_keychain', defaultText: 'Keychain'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon:
                const Icon(Icons.settings, color: ShellitColors.accentBlue),
            label: context.tr('sidebar.nav_settings', defaultText: 'Settings'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(
      BuildContext context, VaultState vaultState) {
    if (_currentNavIndex != 0) {
      return null;
    }

    if (_isSearching) {
      return AppBar(
        backgroundColor: ShellitColors.obsidianHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ShellitColors.textPrimary),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              ref.read(hostFilterProvider.notifier).state =
                  ref.read(hostFilterProvider).copyWith(searchQuery: '');
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: context.tr('hosts.search_placeholder',
                defaultText: 'Search hosts...'),
            hintStyle: const TextStyle(color: ShellitColors.textMuted),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            final filter = ref.read(hostFilterProvider);
            ref.read(hostFilterProvider.notifier).state =
                filter.copyWith(searchQuery: val);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: ShellitColors.textMuted),
              onPressed: () {
                _searchController.clear();
                final filter = ref.read(hostFilterProvider);
                ref.read(hostFilterProvider.notifier).state =
                    filter.copyWith(searchQuery: '');
              },
            ),
        ],
      );
    }

    return AppBar(
      backgroundColor: ShellitColors.obsidianHeader,
      elevation: 0,
      title: const Text(
        'Shellit',
        style: TextStyle(
          color: ShellitColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: ShellitColors.textSecondary),
          tooltip: context.tr('common.search', defaultText: 'Search'),
          onPressed: () {
            setState(() => _isSearching = true);
          },
        ),
        IconButton(
          icon: const Icon(Icons.bolt, color: ShellitColors.accentCyan),
          tooltip: context.tr('omni.quick_connect',
              defaultText: 'Quick Connect'),
          onPressed: () => _showQuickConnectBottomSheet(context),
        ),
        IconButton(
          icon: Icon(
            !vaultState.isUnlocked ? Icons.lock : Icons.lock_open,
            color: !vaultState.isUnlocked
                ? ShellitColors.statusYellow
                : ShellitColors.accentBlue,
          ),
          tooltip: !vaultState.isUnlocked ? 'Unlock Vault' : 'Vault Unlocked',
          onPressed: () async {
            if (!vaultState.isUnlocked) {
              await showUnlockVaultDialog(context, ref);
            } else {
              ref.read(vaultProvider.notifier).lock();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vault locked'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCurrentSectionBody() {
    switch (_currentNavIndex) {
      case 0:
        return MobileHostsView(
          onConnect: _handleConnectHost,
        );
      case 1:
        if (widget.sectionBuilder != null) {
          return widget.sectionBuilder!(context, SidebarSection.keychain);
        }
        return const SizedBox.shrink();
      case 2:
      default:
        if (widget.sectionBuilder != null) {
          return widget.sectionBuilder!(context, SidebarSection.settings);
        }
        return const SizedBox.shrink();
    }
  }
}
