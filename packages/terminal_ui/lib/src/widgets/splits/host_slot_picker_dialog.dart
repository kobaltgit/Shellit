import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// Modal dialog for instantly selecting and connecting a host into a specific split pane slot.
class HostSlotPickerDialog extends StatefulWidget {
  final List<HostEntity> hosts;
  final int slotIndex;
  final ValueChanged<HostEntity> onSelected;

  const HostSlotPickerDialog({
    super.key,
    required this.hosts,
    required this.slotIndex,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<HostEntity> hosts,
    required int slotIndex,
    required ValueChanged<HostEntity> onSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => HostSlotPickerDialog(
        hosts: hosts,
        slotIndex: slotIndex,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<HostSlotPickerDialog> createState() => _HostSlotPickerDialogState();
}

class _HostSlotPickerDialogState extends State<HostSlotPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HostEntity> get _filteredHosts {
    if (_searchQuery.isEmpty) return widget.hosts;
    return widget.hosts.where((h) {
      final label = h.label.toLowerCase();
      final hostname = h.hostname.toLowerCase();
      final username = h.username.toLowerCase();
      final tags = h.tags.map((t) => t.toLowerCase()).join(' ');
      return label.contains(_searchQuery) ||
          hostname.contains(_searchQuery) ||
          username.contains(_searchQuery) ||
          tags.contains(_searchQuery);
    }).toList();
  }

  HostEntity? _buildTransientHostIfQuickConnect(String query) {
    if (query.isEmpty) return null;
    String user = 'root';
    String host = query;
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

    if (host.isEmpty) return null;

    final now = DateTime.now();
    return HostEntity(
      id: 'transient-${now.millisecondsSinceEpoch}',
      label: query,
      hostname: host,
      port: port,
      username: user,
      authType: HostAuthType.password,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHosts;
    final quickHost = _buildTransientHostIfQuickConnect(_searchQuery);

    return Dialog(
      backgroundColor: ShellitColors.obsidianBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ShellitColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.splitscreen_outlined,
                      size: 18, color: ShellitColors.accentBlue),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('splits.picker_title',
                            defaultText: 'Connect Host to Split Pane {slot}')
                        .replaceAll('{slot}', (widget.slotIndex + 1).toString()),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ShellitColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: ShellitColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 13, color: ShellitColors.textPrimary),
                decoration: InputDecoration(
                  hintText: context.tr('splits.picker_search_placeholder',
                      defaultText:
                          'Search hosts by label, IP, username, or tag...'),
                  hintStyle: const TextStyle(
                      fontSize: 12, color: ShellitColors.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: ShellitColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 14, color: ShellitColors.textMuted),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: ShellitColors.obsidianCard,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: ShellitColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: ShellitColors.accentBlue),
                  ),
                ),
              ),
            ),

            // Host list or empty state
            Flexible(
              child: filtered.isEmpty && quickHost == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.dns_outlined,
                                size: 36, color: ShellitColors.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('splits.picker_no_hosts',
                                  defaultText: 'No matching hosts found'),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: ShellitColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        if (filtered.isNotEmpty)
                          ...filtered
                              .map((host) => _buildHostTile(context, host)),
                        if (quickHost != null &&
                            !filtered.any((h) =>
                                h.hostname.toLowerCase() ==
                                quickHost.hostname.toLowerCase())) ...[
                          const Divider(
                              color: ShellitColors.border, height: 16),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ShellitColors.accentBlue
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.bolt,
                                  size: 16, color: ShellitColors.accentBlue),
                            ),
                            title: Text(
                              context.tr('splits.picker_quick_connect',
                                      defaultText: 'Quick Connect: {target}')
                                  .replaceAll(
                                      '{target}', quickHost.connectionTarget),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ShellitColors.accentBlue,
                              ),
                            ),
                            subtitle: Text(
                              context.tr('splits.picker_quick_connect_desc',
                                      defaultText:
                                          'Connect to {target} as transient host')
                                  .replaceAll('{target}',
                                      '${quickHost.username}@${quickHost.hostname}:${quickHost.port}'),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: ShellitColors.textSecondary),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 12, color: ShellitColors.textMuted),
                            dense: true,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            hoverColor:
                                ShellitColors.accentBlue.withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelected(quickHost);
                            },
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHostTile(BuildContext context, HostEntity host) {
    Color? badgeColor;
    String? badgeText;
    if (host.environment == HostEnvironment.production) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = context.tr('hosts.card.env_prod', defaultText: 'PROD');
    } else if (host.environment == HostEnvironment.staging) {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = context.tr('hosts.card.env_stage', defaultText: 'STAGE');
    } else if (host.environment == HostEnvironment.development) {
      badgeColor = const Color(0xFF3B82F6);
      badgeText = context.tr('hosts.card.env_dev', defaultText: 'DEV');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: ShellitColors.obsidianCard.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: ShellitColors.border.withValues(alpha: 0.6)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.computer,
                size: 16, color: ShellitColors.textSecondary),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  host.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ShellitColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: badgeColor!.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: badgeColor.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            host.connectionTarget,
            style: const TextStyle(
              fontSize: 11,
              color: ShellitColors.textMuted,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          trailing: const Icon(Icons.login,
              size: 14, color: ShellitColors.accentBlue),
          dense: true,
          hoverColor: ShellitColors.accentBlue.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () {
            Navigator.of(context).pop();
            widget.onSelected(host);
          },
        ),
      ),
    );
  }
}
