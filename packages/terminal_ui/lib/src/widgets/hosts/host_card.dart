import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ping_monitor_provider.dart';
import '../../theme/shellit_theme.dart';
import 'os_icon_badge.dart';

class HostCard extends ConsumerWidget {
  final HostEntity host;
  final VoidCallback? onConnect;
  final VoidCallback? onOpenSftp;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDense;

  const HostCard({
    super.key,
    required this.host,
    this.onConnect,
    this.onOpenSftp,
    this.onEdit,
    this.onDelete,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pingState = ref.watch(pingMonitorProvider);
    final latency = pingState.latencyFor(host.id) ?? host.lastPingLatencyMs;
    final pingStatus = latency.pingStatus;

    if (isDense) {
      return _buildDenseRow(context, latency, pingStatus);
    }
    return _buildGridCard(context, latency, pingStatus);
  }

  Widget _buildGridCard(
      BuildContext context, int? latency, PingStatus pingStatus) {
    return Card(
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
                  _buildEnvironmentBadge(host.environment),
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
                  _buildPingDot(pingStatus, latency),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.folder_shared_outlined, size: 18),
                    tooltip: 'Open SFTP',
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenSftp,
                    color: ShellitColors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Host',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEdit,
                    color: ShellitColors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.terminal, size: 18),
                    tooltip: 'Connect Terminal',
                    visualDensity: VisualDensity.compact,
                    onPressed: onConnect,
                    color: ShellitColors.accentBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDenseRow(
      BuildContext context, int? latency, PingStatus pingStatus) {
    return Container(
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: ShellitColors.border, width: 0.5)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPingDot(pingStatus, latency, showLabel: false),
            const SizedBox(width: 8),
            _buildOsIcon(host.osType, size: 20),
          ],
        ),
        title: Row(
          children: [
            Text(
              host.label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            _buildEnvironmentBadge(host.environment),
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
              tooltip: 'SFTP',
              onPressed: onOpenSftp,
              color: ShellitColors.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.terminal, size: 16),
              tooltip: 'Connect',
              onPressed: onConnect,
              color: ShellitColors.accentBlue,
            ),
          ],
        ),
        onTap: onConnect,
      ),
    );
  }

  Widget _buildOsIcon(OsType os, {double size = 26}) {
    final padding = size >= 24 ? 6.0 : 3.0;
    return OsIconBadge(os: os, size: size, padding: padding);
  }

  Widget _buildEnvironmentBadge(HostEnvironment env) {
    String label;
    Color bg;
    Color text;

    switch (env) {
      case HostEnvironment.production:
        label = 'PROD';
        bg = ShellitColors.envProdBg;
        text = ShellitColors.envProdText;
        break;
      case HostEnvironment.staging:
        label = 'STAGE';
        bg = ShellitColors.envStageBg;
        text = ShellitColors.envStageText;
        break;
      case HostEnvironment.development:
        label = 'DEV';
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

  Widget _buildPingDot(PingStatus status, int? latency,
      {bool showLabel = true}) {
    final color = _getPingColor(status);
    final text = latency != null ? '${latency}ms' : 'offline';

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
