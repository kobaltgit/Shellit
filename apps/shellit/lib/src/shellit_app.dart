import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'controllers/session_connect_controller.dart';
import 'localization/localization_providers.dart';
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
            final enabledPlugins = installedPlugins
                .where((p) => p.isEnabled)
                .toList();

            if (enabledPlugins.isEmpty) return const SizedBox.shrink();

            final isDocker = enabledPlugins.any(
              (p) => p.manifest.id == 'com.shellit.docker-monitor',
            );

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: activePlugin != null
                    ? 'Close ${activePlugin.manifest.name}'
                    : 'Toggle ${enabledPlugins.first.manifest.name}',
                child: InkWell(
                  onTap: () {
                    final sessionState = ref.read(sessionManagerProvider);
                    // If on hosts catalog, switch to active tab or show hint
                    if (sessionState.activeTab == null) {
                      if (sessionState.tabs.isNotEmpty) {
                        ref
                            .read(sessionManagerProvider.notifier)
                            .setActiveTab(sessionState.tabs.last.id);
                        ref.read(activeSidebarPluginProvider.notifier).state =
                            enabledPlugins.first;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Connect to an SSH host first to use Docker plugin',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      return;
                    }

                    final current = ref.read(activeSidebarPluginProvider);
                    if (current != null) {
                      ref.read(activeSidebarPluginProvider.notifier).state =
                          null;
                    } else {
                      ref.read(activeSidebarPluginProvider.notifier).state =
                          enabledPlugins.first;
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (activePlugin != null &&
                              ref.watch(sessionManagerProvider).activeTab !=
                                  null)
                          ? ShellitColors.accentCyan.withValues(alpha: 0.15)
                          : ShellitColors.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            (activePlugin != null &&
                                ref.watch(sessionManagerProvider).activeTab !=
                                    null)
                            ? ShellitColors.accentCyan
                            : ShellitColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDocker ? '🐳' : '🧩',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDocker ? 'Docker' : 'Plugins',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                (activePlugin != null &&
                                    ref
                                            .watch(sessionManagerProvider)
                                            .activeTab !=
                                        null)
                                ? ShellitColors.accentCyan
                                : ShellitColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        pluginSidebarBuilder: isMobilePlatform
            ? null
            : (context) {
                final activeTab = ref.watch(sessionManagerProvider).activeTab;
                if (activeTab == null) return const SizedBox.shrink();

                final activePlugin = ref.watch(activeSidebarPluginProvider);
                if (activePlugin == null) return const SizedBox.shrink();
                return DesktopPluginHostView(
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
