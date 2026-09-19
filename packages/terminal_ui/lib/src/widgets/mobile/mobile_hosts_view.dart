import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/folders_provider.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../theme/shellit_theme.dart';
import '../hosts/host_form_dialog.dart';
import '../hosts/os_icon_badge.dart';

class MobileHostsView extends ConsumerWidget {
  final void Function(HostEntity host)? onConnect;

  const MobileHostsView({
    super.key,
    this.onConnect,
  });

  Future<void> _openAddHostDialog(BuildContext context, WidgetRef ref) async {
    final keyManager = ref.read(keyManagerProvider);
    final keys = await keyManager?.getAllKeys() ?? [];
    final folders = ref.read(foldersProvider);

    if (!context.mounted) return;

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

  Future<void> _openEditHostDialog(
      BuildContext context, WidgetRef ref, HostEntity host) async {
    final keyManager = ref.read(keyManagerProvider);
    final keys = await keyManager?.getAllKeys() ?? [];
    final folders = ref.read(foldersProvider);

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => HostFormDialog(
        initialHost: host,
        availableKeys: keys,
        availableFolders: folders,
        onCreateFolder: (name) async {
          final res =
              await ref.read(foldersProvider.notifier).createFolder(name: name);
          return res.valueOrNull;
        },
        onSave: (updatedHost, password) async {
          if (password != null && password.isNotEmpty && keyManager != null) {
            final credId =
                updatedHost.credentialRefId ?? 'cred_${updatedHost.id}';
            await keyManager.savePasswordCredential(
              id: credId,
              label: 'Password for ${updatedHost.label}',
              password: password,
            );
            updatedHost = updatedHost.copyWith(credentialRefId: credId);
          }
          await ref.read(hostsProvider.notifier).updateHost(updatedHost);
        },
      ),
    );
  }

  void _handleDuplicateHost(
      BuildContext context, WidgetRef ref, HostEntity host) {
    final copy = host.copyWith(
      id: 'host_${DateTime.now().millisecondsSinceEpoch}',
      label: '${host.label} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    ref.read(hostsProvider.notifier).addHost(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr('hosts.duplicated_msg',
              params: {'name': copy.label},
              defaultText: 'Host "${copy.label}" created'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleDeleteHost(BuildContext context, WidgetRef ref, String hostId) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(
          context.tr('hosts.delete_confirm_title', defaultText: 'Delete Host?'),
          style: const TextStyle(color: ShellitColors.textPrimary),
        ),
        content: Text(
          context.tr('hosts.delete_confirm_desc',
              defaultText:
                  'Are you sure you want to delete this host configuration?'),
          style: const TextStyle(color: ShellitColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.tr('common.cancel', defaultText: 'Cancel'),
              style: const TextStyle(color: ShellitColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr('common.delete', defaultText: 'Delete')),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(hostsProvider.notifier).deleteHost(hostId);
      }
    });
  }

  void _showHostOptionsBottomSheet(
      BuildContext context, WidgetRef ref, HostEntity host) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ShellitColors.obsidianSidebar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: ShellitColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      OsIconBadge(os: host.osType, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              host.label,
                              style: const TextStyle(
                                color: ShellitColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${host.username}@${host.hostname}:${host.port}',
                              style: const TextStyle(
                                color: ShellitColors.textMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: ShellitColors.border, height: 16),
                ListTile(
                  leading: const Icon(Icons.terminal,
                      color: ShellitColors.accentCyan),
                  title: Text(
                    context.tr('hosts.action_connect',
                        defaultText: 'Connect Terminal'),
                    style: const TextStyle(color: ShellitColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onConnect?.call(host);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: Colors.white70),
                  title: Text(
                    context.tr('common.edit', defaultText: 'Edit Host'),
                    style: const TextStyle(color: ShellitColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openEditHostDialog(context, ref, host);
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.copy_outlined, color: Colors.white70),
                  title: Text(
                    context.tr('common.duplicate',
                        defaultText: 'Duplicate Host'),
                    style: const TextStyle(color: ShellitColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleDuplicateHost(context, ref, host);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: ShellitColors.statusRed),
                  title: Text(
                    context.tr('common.delete', defaultText: 'Delete Host'),
                    style: const TextStyle(color: ShellitColors.statusRed),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _handleDeleteHost(context, ref, host.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(filteredHostsProvider);
    final pingState = ref.watch(pingMonitorProvider);

    if (hosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dns_outlined,
                  size: 56, color: ShellitColors.textMuted),
              const SizedBox(height: 16),
              Text(
                context.tr('hosts.empty_title', defaultText: 'No hosts found'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ShellitColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('hosts.empty_desc',
                    defaultText: 'Create a new host or adjust search filters.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: ShellitColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openAddHostDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('hosts.btn_new_host',
                    defaultText: 'Create Host')),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: hosts.length,
      itemBuilder: (context, index) {
        final host = hosts[index];
        final latency = pingState.latencyFor(host.id) ?? host.lastPingLatencyMs;
        final pingStatus = latency.pingStatus;

        return Card(
          color: ShellitColors.obsidianCard,
          margin: const EdgeInsets.only(bottom: 10),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: ShellitColors.border, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () => onConnect?.call(host),
            onLongPress: () => _showHostOptionsBottomSheet(context, ref, host),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  OsIconBadge(os: host.osType, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                host.label,
                                style: const TextStyle(
                                  color: ShellitColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (host.environment != HostEnvironment.production)
                              _buildEnvBadge(host.environment),
                            if (host.environment == HostEnvironment.production)
                              _buildProdBadge(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${host.username}@${host.hostname}:${host.port}',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  color: ShellitColors.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildPingIndicator(latency, pingStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: ShellitColors.textSecondary, size: 20),
                    onPressed: () =>
                        _showHostOptionsBottomSheet(context, ref, host),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvBadge(HostEnvironment env) {
    Color bg;
    Color fg;
    String label;

    switch (env) {
      case HostEnvironment.staging:
        bg = ShellitColors.statusYellow.withValues(alpha: 0.15);
        fg = ShellitColors.statusYellow;
        label = 'STAGE';
        break;
      case HostEnvironment.development:
        bg = ShellitColors.accentBlue.withValues(alpha: 0.15);
        fg = ShellitColors.accentBlue;
        label = 'DEV';
        break;
      case HostEnvironment.production:
        bg = ShellitColors.statusRed.withValues(alpha: 0.15);
        fg = ShellitColors.statusRed;
        label = 'PROD';
        break;
      case HostEnvironment.defaultEnv:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProdBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ShellitColors.statusRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ShellitColors.statusRed, width: 1),
      ),
      child: const Text(
        'PROD',
        style: TextStyle(
          color: ShellitColors.statusRed,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPingIndicator(int? latency, PingStatus pingStatus) {
    Color dotColor;
    switch (pingStatus) {
      case PingStatus.fast:
        dotColor = ShellitColors.statusGreen;
        break;
      case PingStatus.medium:
        dotColor = ShellitColors.statusYellow;
        break;
      case PingStatus.slow:
        dotColor = ShellitColors.statusOrange;
        break;
      case PingStatus.offline:
        dotColor = ShellitColors.textMuted;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (latency != null) ...[
          Text(
            '${latency}ms',
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'JetBrains Mono',
              color: ShellitColors.textMuted,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
