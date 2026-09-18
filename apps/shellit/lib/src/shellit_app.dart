import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'controllers/session_connect_controller.dart';
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

    return MaterialApp(
      title: 'Shellit',
      debugShowCheckedModeBanner: false,
      theme: ShellitTheme.obsidianDarkTheme,
      home: ShellitAppShell(
        snippets: snippets,
        onConnectTerminal: (host) => connectController.connectTerminal(host),
        onConnectSftp: (host) => connectController.connectSftp(host),
        onToggleRecording: (session, host) =>
            connectController.toggleRecording(session, host),
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
    );
  }
}
