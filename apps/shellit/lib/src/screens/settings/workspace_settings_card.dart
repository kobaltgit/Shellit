import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

/// Card for configuring Workspace Session Restoration in Settings.
class WorkspaceSettingsCard extends ConsumerStatefulWidget {
  const WorkspaceSettingsCard({super.key});

  @override
  ConsumerState<WorkspaceSettingsCard> createState() =>
      _WorkspaceSettingsCardState();
}

class _WorkspaceSettingsCardState extends ConsumerState<WorkspaceSettingsCard> {
  bool _restoreSessions = true;
  bool _autoReconnect = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(appVaultRepositoryProvider);
    final settings = await repo.getSettings();
    if (mounted) {
      setState(() {
        _restoreSessions = settings.restoreWorkspaceSessions;
        _autoReconnect = settings.autoReconnectOnRestore;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings({
    bool? restoreSessions,
    bool? autoReconnect,
  }) async {
    final repo = ref.read(appVaultRepositoryProvider);
    final current = await repo.getSettings();
    final updated = current.copyWith(
      restoreWorkspaceSessions: restoreSessions ?? _restoreSessions,
      autoReconnectOnRestore: autoReconnect ?? _autoReconnect,
    );
    await repo.updateSettings(updated);
    if (restoreSessions == false) {
      await repo.setMetadata('workspace_tabs', '');
    }
    if (mounted) {
      setState(() {
        if (restoreSessions != null) _restoreSessions = restoreSessions;
        if (autoReconnect != null) _autoReconnect = autoReconnect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SwitchListTile(
            activeThumbColor: ShellitColors.accentCyan,
            value: _restoreSessions,
            onChanged: (val) => _updateSettings(restoreSessions: val),
            secondary: const Icon(
              Icons.tab_outlined,
              color: ShellitColors.accentCyan,
            ),
            title: Text(
              context.tr(
                'settings.workspace.restore_tabs_title',
                defaultText: 'Restore Open Tabs on Startup',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              context.tr(
                'settings.workspace.restore_tabs_subtitle',
                defaultText:
                    'Preserve open terminal and SFTP tabs when closing and reopening Shellit',
              ),
              style: const TextStyle(
                color: ShellitColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          if (_restoreSessions) ...[
            const Divider(color: ShellitColors.border, height: 1),
            SwitchListTile(
              activeThumbColor: ShellitColors.accentCyan,
              value: _autoReconnect,
              onChanged: (val) => _updateSettings(autoReconnect: val),
              secondary: const Icon(
                Icons.sync_outlined,
                color: ShellitColors.accentCyan,
              ),
              title: Text(
                context.tr(
                  'settings.workspace.auto_reconnect_title',
                  defaultText: 'Auto-Reconnect Restored Tabs',
                ),
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                context.tr(
                  'settings.workspace.auto_reconnect_subtitle',
                  defaultText:
                      'Automatically initiate SSH connections for restored tabs instead of waiting for click',
                ),
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
