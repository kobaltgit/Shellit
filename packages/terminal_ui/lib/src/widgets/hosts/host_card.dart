import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/folders_provider.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../theme/shellit_theme.dart';
import 'host_context_menu.dart';
import 'os_icon_badge.dart';

class HostCard extends ConsumerWidget {
  final HostEntity host;
  final VoidCallback? onConnect;
  final VoidCallback? onOpenSftp;
  final VoidCallback? onConnectInSplit;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final ValueChanged<String?>? onMoveToFolder;
  final VoidCallback? onDelete;
  final bool isDense;
  final FocusNode? focusNode;
  final bool autofocus;

  const HostCard({
    super.key,
    required this.host,
    this.onConnect,
    this.onOpenSftp,
    this.onConnectInSplit,
    this.onEdit,
    this.onDuplicate,
    this.onMoveToFolder,
    this.onDelete,
    this.isDense = false,
    this.focusNode,
    this.autofocus = false,
  });

  void _openContextMenu(BuildContext context, WidgetRef ref, Offset position) {
    final folders = ref.read(foldersProvider);
    HostContextMenu.show(
      context: context,
      globalPosition: position,
      host: host,
      folders: folders,
      onConnect: onConnect,
      onOpenSftp: onOpenSftp,
      onConnectInSplit: onConnectInSplit,
      onEdit: onEdit,
      onDuplicate: onDuplicate,
      onMoveToFolder: onMoveToFolder,
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pingState = ref.watch(pingMonitorProvider);
    final latency = pingState.latencyFor(host.id) ?? host.lastPingLatencyMs;
    final pingStatus = latency.pingStatus;

    final child = isDense
        ? _buildDenseRow(context, ref, latency, pingStatus)
        : _buildGridCard(context, ref, latency, pingStatus);

    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            onConnect?.call();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyE) {
            onEdit?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  Widget _buildGridCard(BuildContext context, WidgetRef ref, int? latency,
      PingStatus pingStatus) {
    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _openContextMenu(context, ref, details.globalPosition),
      onLongPressStart: (details) =>
          _openContextMenu(context, ref, details.globalPosition),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onConnect,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: OS Icon + Environment badge + Ping latency indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildOsIcon(host.osType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: ShellitColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            host.connectionTarget,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ShellitColors.textSecondary,
                              fontFamily: 'JetBrains Mono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildEnvironmentBadge(context, host.environment),
                  ],
                ),

                const SizedBox(height: 12),

                // Middle: Tags
                if (host.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: host.tags.map((tag) => _buildTag(tag)).toList(),
                  ),

                const Spacer(),

                const Divider(height: 16),

                // Bottom row: Ping Status + Actions
                Row(
                  children: [
                    _buildPingDot(context, pingStatus, latency),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.folder_shared_outlined, size: 18),
                      tooltip: context.tr(
                        'hosts.card.tooltip_sftp',
                        defaultText: 'Open SFTP',
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: onOpenSftp,
                      color: ShellitColors.textSecondary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: context.tr(
                        'hosts.card.tooltip_edit',
                        defaultText: 'Edit Host',
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                      color: ShellitColors.textSecondary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.terminal, size: 18),
                      tooltip: context.tr(
                        'hosts.card.tooltip_connect',
                        defaultText: 'Connect Terminal',
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: onConnect,
                      color: ShellitColors.accentBlue,
                    ),
                    Builder(
                      builder: (btnCtx) {
                        return IconButton(
                          icon: const Icon(Icons.more_vert, size: 18),
                          tooltip: context.tr(
                            'hosts.card.tooltip_more',
                            defaultText: 'More Actions',
                          ),
                          visualDensity: VisualDensity.compact,
                          color: ShellitColors.textSecondary,
                          onPressed: () {
                            final box = btnCtx.findRenderObject() as RenderBox?;
                            final offset =
                                box?.localToGlobal(Offset.zero) ?? Offset.zero;
                            _openContextMenu(
                                context, ref, offset + const Offset(0, 30));
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDenseRow(BuildContext context, WidgetRef ref, int? latency,
      PingStatus pingStatus) {
    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _openContextMenu(context, ref, details.globalPosition),
      onLongPressStart: (details) =>
          _openContextMenu(context, ref, details.globalPosition),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: ShellitColors.border, width: 0.5)),
        ),
        child: ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPingDot(context, pingStatus, latency, showLabel: false),
              const SizedBox(width: 8),
              _buildOsIcon(host.osType, size: 20),
            ],
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  host.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildEnvironmentBadge(context, host.environment),
            ],
          ),
          subtitle: Text(
            host.connectionTarget,
            style: const TextStyle(
              fontSize: 11,
              color: ShellitColors.textSecondary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (latency != null)
                Text(
                  '${latency}ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getPingColor(pingStatus),
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.folder_shared_outlined, size: 16),
                tooltip: context.tr(
                  'hosts.card.tooltip_sftp',
                  defaultText: 'Open SFTP',
                ),
                onPressed: onOpenSftp,
                color: ShellitColors.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.terminal, size: 16),
                tooltip: context.tr(
                  'hosts.card.tooltip_connect',
                  defaultText: 'Connect Terminal',
                ),
                onPressed: onConnect,
                color: ShellitColors.accentBlue,
              ),
              Builder(
                builder: (btnCtx) {
                  return IconButton(
                    icon: const Icon(Icons.more_vert, size: 16),
                    tooltip: context.tr(
                      'hosts.card.tooltip_more',
                      defaultText: 'More Actions',
                    ),
                    color: ShellitColors.textSecondary,
                    onPressed: () {
                      final box = btnCtx.findRenderObject() as RenderBox?;
                      final offset =
                          box?.localToGlobal(Offset.zero) ?? Offset.zero;
                      _openContextMenu(
                          context, ref, offset + const Offset(0, 24));
                    },
                  );
                },
              ),
            ],
          ),
          onTap: onConnect,
        ),
      ),
    );
  }

  Widget _buildOsIcon(OsType os, {double size = 26}) {
    final padding = size >= 24 ? 6.0 : 3.0;
    return OsIconBadge(os: os, size: size, padding: padding);
  }

  Widget _buildEnvironmentBadge(BuildContext context, HostEnvironment env) {
    String label;
    Color bg;
    Color text;

    switch (env) {
      case HostEnvironment.production:
        label = context.tr('hosts.card.env_prod', defaultText: 'PROD');
        bg = ShellitColors.envProdBg;
        text = ShellitColors.envProdText;
        break;
      case HostEnvironment.staging:
        label = context.tr('hosts.card.env_stage', defaultText: 'STAGE');
        bg = ShellitColors.envStageBg;
        text = ShellitColors.envStageText;
        break;
      case HostEnvironment.development:
        label = context.tr('hosts.card.env_dev', defaultText: 'DEV');
        bg = ShellitColors.envDevBg;
        text = ShellitColors.envDevText;
        break;
      case HostEnvironment.defaultEnv:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: text, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ShellitColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: ShellitColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getPingColor(PingStatus status) {
    switch (status) {
      case PingStatus.fast:
        return ShellitColors.statusGreen;
      case PingStatus.medium:
        return ShellitColors.statusYellow;
      case PingStatus.slow:
        return Colors.orange;
      case PingStatus.offline:
        return ShellitColors.statusGrey;
    }
  }

  Widget _buildPingDot(
    BuildContext context,
    PingStatus status,
    int? latency, {
    bool showLabel = true,
  }) {
    final color = _getPingColor(status);
    final text = latency != null
        ? context
            .tr('hosts.status.latency_ms', defaultText: '{ms}ms')
            .replaceAll('{ms}', latency.toString())
        : context.tr('hosts.status.offline', defaultText: 'offline');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: status == PingStatus.fast
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
