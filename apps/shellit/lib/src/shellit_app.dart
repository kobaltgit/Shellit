import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'controllers/session_connect_controller.dart';
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

class ShellitApp extends ConsumerWidget {
  const ShellitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectController = ref.read(sessionConnectControllerProvider);
    final snippets = ref.watch(snippetsListProvider).valueOrNull ?? [];
    final localizationService = ref.watch(localizationServiceProvider);
    final activeLocale = ref.watch(activeLocaleProvider);

    final isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final effectiveLocale = isMobilePlatform ? 'en' : activeLocale;

    // Automatically start MCP Server on desktop platforms
    if (!isMobilePlatform) {
      ref.watch(mcpServerServiceProvider);
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
        topBarTrailing: isMobilePlatform
            ? null
            : Consumer(
          builder: (context, ref, _) {
            final activePlugin = ref.watch(activeSidebarPluginProvider);
            final pluginsAsync = ref.watch(pluginManagerProvider);
            final installedPlugins = pluginsAsync.valueOrNull ?? [];
            final enabledSidebarPlugins = installedPlugins
                .where((p) =>
                    p.isEnabled &&
                    p.manifest.target == PluginTarget.sidebar)
                .toList();

            if (enabledSidebarPlugins.isEmpty) return const SizedBox.shrink();

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: enabledSidebarPlugins.map((plugin) {
                final isSelected =
                    activePlugin?.manifest.id == plugin.manifest.id;
                final isMcp = plugin.manifest.id == 'com.shellit.mcp-server';
                final isDocker =
                    plugin.manifest.id == 'com.shellit.docker-monitor';
                final label = isMcp
                    ? context.tr(
                        'plugins.mcp_short_name',
                        defaultText: 'MCP AI',
                      )
                    : (isDocker
                        ? context.tr(
                            'plugins.docker_short_name',
                            defaultText: 'Docker',
                          )
                        : plugin.manifest.name);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: isSelected
                        ? context.tr(
                            'plugins.close_plugin',
                            defaultText: 'Close {name}',
                            params: {'name': label},
                          )
                        : context.tr(
                            'plugins.open_plugin',
                            defaultText: 'Open {name}',
                            params: {'name': label},
                          ),
                    child: InkWell(
                      onTap: () {
                        // If plugin is already open, clicking toggles it closed
                        if (isSelected) {
                          ref.read(activeSidebarPluginProvider.notifier).state =
                              null;
                          return;
                        }

                        // For Docker, check if an active tab exists or switch to one
                        if (isDocker) {
                          final sessionState = ref.read(sessionManagerProvider);
                          if (sessionState.activeTab == null) {
                            if (sessionState.tabs.isNotEmpty) {
                              ref
                                  .read(sessionManagerProvider.notifier)
                                  .setActiveTab(sessionState.tabs.last.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.tr(
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

                        ref.read(activeSidebarPluginProvider.notifier).state =
                            plugin;
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isMcp
                                  ? ShellitColors.accentPurple
                                      .withValues(alpha: 0.18)
                                  : ShellitColors.accentCyan
                                      .withValues(alpha: 0.15))
                              : ShellitColors.obsidianBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? (isMcp
                                    ? ShellitColors.accentPurple
                                    : ShellitColors.accentCyan)
                                : ShellitColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMcp)
                              McpVectorIcon(
                                size: 13,
                                color: isSelected
                                    ? ShellitColors.accentPurple
                                    : ShellitColors.accentCyan,
                              )
                            else
                              Text(
                                isDocker ? '🐳' : '🧩',
                                style: const TextStyle(fontSize: 13),
                              ),
                            const SizedBox(width: 5),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? (isMcp
                                        ? ShellitColors.accentPurple
                                        : ShellitColors.accentCyan)
                                    : ShellitColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        pluginSidebarBuilder: isMobilePlatform
            ? null
            : (context) {

                final activePlugin = ref.watch(activeSidebarPluginProvider);
                if (activePlugin == null) return const SizedBox.shrink();

                final activeTab = ref.watch(sessionManagerProvider).activeTab;
                // Docker monitor requires an active tab to query container stats
                if (activePlugin.manifest.id == 'com.shellit.docker-monitor' &&
                    activeTab == null) {
                  return const SizedBox.shrink();
                }

                return DesktopPluginHostView(
                  key: ValueKey(activePlugin.manifest.id),
                  plugin: activePlugin,
                  onClose: () =>
                      ref.read(activeSidebarPluginProvider.notifier).state = null,
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
