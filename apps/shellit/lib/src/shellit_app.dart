import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/session_connect_controller.dart';
import 'di/app_providers.dart';
import 'localization/localization_providers.dart';
import 'mcp/mcp_icon.dart';
import 'mcp/mcp_provider.dart';
import 'plugins/desktop_plugin_host_view.dart';
import 'plugins/plugin_manager_provider.dart';
import 'screens/keychain/keychain_screen.dart';
import 'screens/logs/audit_logs_screen.dart';
import 'screens/plugins/plugins_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/snippets/snippets_screen.dart';
import 'screens/tunnels/tunnels_screen.dart';

class ShellitApp extends ConsumerStatefulWidget {
  const ShellitApp({super.key});

  @override
  ConsumerState<ShellitApp> createState() => _ShellitAppState();
}

class _ShellitAppState extends ConsumerState<ShellitApp> with WindowListener {
  bool _isWindowMaximized = false;
  bool _hasRestoredWorkspace = false;

  bool get _isDesktop =>
      !kIsWeb &&
      !Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _checkWindowMaximized();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkWindowMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isWindowMaximized = maximized;
        });
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isWindowMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isWindowMaximized = false);
  }

  Future<void> _tryRestoreWorkspace(List<HostEntity> hosts) async {
    if (_hasRestoredWorkspace) return;
    final vaultRepo = ref.read(appVaultRepositoryProvider);
    try {
      final settings = await vaultRepo.getSettings();
      if (!settings.restoreWorkspaceSessions) {
        _hasRestoredWorkspace = true;
        return;
      }

      final savedJson = await vaultRepo.getMetadata('workspace_tabs');
      if (savedJson != null && savedJson.isNotEmpty) {
        final tabStates = WorkspaceTabState.decodeList(savedJson);
        if (tabStates.isNotEmpty && mounted) {
          _hasRestoredWorkspace = true;
          ref.read(sessionManagerProvider.notifier).restoreWorkspaceTabs(
                tabStates,
                hosts,
                autoReconnect: settings.autoReconnectOnRestore,
              );
        }
      } else {
        _hasRestoredWorkspace = true;
      }
    } catch (_) {
      _hasRestoredWorkspace = true;
    }
  }

  Future<void> _persistWorkspaceTabs(List<SessionTab> tabs) async {
    try {
      final vaultRepo = ref.read(appVaultRepositoryProvider);
      final settings = await vaultRepo.getSettings();
      if (!settings.restoreWorkspaceSessions) return;

      final tabStates =
          ref.read(sessionManagerProvider.notifier).exportWorkspaceState();
      final jsonStr = WorkspaceTabState.encodeList(tabStates);
      await vaultRepo.setMetadata('workspace_tabs', jsonStr);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final connectController = ref.read(sessionConnectControllerProvider);
    final snippets = ref.watch(snippetsListProvider).valueOrNull ?? [];
    final localizationService = ref.watch(localizationServiceProvider);
    final activeLocale = ref.watch(activeLocaleProvider);

    final isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final effectiveLocale = isMobilePlatform ? 'en' : activeLocale;

    // Automatically start MCP Server on desktop platforms
    if (!isMobilePlatform) {
      ref.watch(mcpServerServiceProvider);
    }

    // Attempt workspace restoration once vault is unlocked and hosts are loaded (Desktop only)
    final vaultState = ref.watch(vaultProvider);
    final hosts = ref.watch(hostsProvider);
    if (!isMobilePlatform &&
        !_hasRestoredWorkspace &&
        vaultState.isUnlocked &&
        hosts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasRestoredWorkspace) {
          _tryRestoreWorkspace(hosts);
        }
      });
    }

    // Auto-save tabs on change (Desktop only)
    ref.listen<SessionManagerState>(sessionManagerProvider, (prev, next) {
      if (!isMobilePlatform && prev?.tabs != next.tabs) {
        _persistWorkspaceTabs(next.tabs);
      }
    });

    // Build right activity rail items for sidebar plugins
    List<PluginActivityRailItem>? pluginRailItems;
    if (!isMobilePlatform) {
      final activePlugin = ref.watch(activeSidebarPluginProvider);
      final pluginsAsync = ref.watch(pluginManagerProvider);
      final installedPlugins = pluginsAsync.valueOrNull ?? [];
      final enabledSidebarPlugins = installedPlugins
          .where(
            (p) =>
                p.isEnabled && p.manifest.target == PluginTarget.sidebar,
          )
          .toList();

      if (enabledSidebarPlugins.isNotEmpty) {
        pluginRailItems = enabledSidebarPlugins.map<PluginActivityRailItem>((plugin) {
          final isSelected = activePlugin?.manifest.id == plugin.manifest.id;
          final isMcp = plugin.manifest.id == 'com.shellit.mcp-server';
          final isDocker = plugin.manifest.id == 'com.shellit.docker-monitor';
          final label = isMcp
              ? localizationService.translate(
                  'plugins.mcp_short_name',
                  defaultText: 'MCP AI',
                )
              : (isDocker
                  ? localizationService.translate(
                      'plugins.docker_short_name',
                      defaultText: 'Docker',
                    )
                  : plugin.manifest.name);

          return PluginActivityRailItem(
            id: plugin.manifest.id,
            label: label,
            icon: isMcp
                ? McpVectorIcon(
                    size: 16,
                    color: isSelected
                        ? ShellitColors.accentPurple
                        : ShellitColors.textMuted,
                  )
                : Text(
                    isDocker ? '🐳' : '🧩',
                    style: const TextStyle(fontSize: 16),
                  ),
            tooltip: label,
            isSelected: isSelected,
            onTap: () {
              if (isSelected) {
                ref.read(activeSidebarPluginProvider.notifier).state = null;
                return;
              }

              if (isDocker) {
                final sessionState = ref.read(sessionManagerProvider);
                if (sessionState.activeTab == null) {
                  if (sessionState.tabs.isNotEmpty) {
                    ref.read(sessionManagerProvider.notifier).setActiveTab(
                          sessionState.tabs.last.id,
                        );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          localizationService.translate(
                            'plugins.docker_connect_ssh_first',
                            defaultText:
                                'Connect to an SSH host first to use Docker plugin',
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                }
              }

              ref.read(activeSidebarPluginProvider.notifier).state = plugin;
            },
          );
        }).toList();
      }
    }

    return LocalizationScope(
      service: localizationService,
      locale: effectiveLocale,
      child: MaterialApp(
        title: 'Shellit',
        debugShowCheckedModeBanner: false,
        theme: ShellitTheme.obsidianDarkTheme,
        home: ShellitAppShell(
          snippets: isMobilePlatform ? null : snippets,
          onConnectTerminal: (host, {onProgress}) =>
              connectController.connectTerminal(host, onProgress: onProgress),
          onConnectSftp: isMobilePlatform
              ? null
              : (host, {onProgress}) =>
                  connectController.connectSftp(host, onProgress: onProgress),
          onToggleRecording: (session, host) =>
              connectController.toggleRecording(session, host),
          onWindowMinimize: _isDesktop ? () => windowManager.minimize() : null,
          onWindowMaximize: _isDesktop
              ? () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                }
              : null,
          onWindowClose: _isDesktop ? () => windowManager.close() : null,
          isWindowMaximized: _isWindowMaximized,
          dragAreaBuilder: _isDesktop
              ? (context, child) => DragToMoveArea(child: child)
              : null,
          pluginRailItems: pluginRailItems,
          pluginSidebarBuilder: isMobilePlatform
              ? null
              : (context) {
                  final activePlugin = ref.watch(activeSidebarPluginProvider);
                  if (activePlugin == null) return const SizedBox.shrink();

                  final activeTab =
                      ref.watch(sessionManagerProvider).activeTab;
                  if (activePlugin.manifest.id ==
                          'com.shellit.docker-monitor' &&
                      activeTab == null) {
                    return const SizedBox.shrink();
                  }

                  return DesktopPluginHostView(
                    key: ValueKey(activePlugin.manifest.id),
                    plugin: activePlugin,
                    onClose: () =>
                        ref.read(activeSidebarPluginProvider.notifier).state =
                            null,
                  );
                },
          sectionBuilder: (context, section) {
            switch (section) {
              case SidebarSection.keychain:
                return const KeychainScreen();
              case SidebarSection.tunnels:
                return const TunnelsScreen();
              case SidebarSection.plugins:
                return const PluginsScreen();
              case SidebarSection.settings:
                return const SettingsScreen();
              case SidebarSection.snippets:
                return const SnippetsScreen();
              case SidebarSection.logs:
                return const AuditLogsScreen();
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
