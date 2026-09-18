import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/shellit_theme.dart';
import 'host_card.dart';
import 'host_form_dialog.dart';

class HostViewsSwitcher extends ConsumerWidget {
  final void Function(HostEntity host)? onConnect;
  final void Function(HostEntity host)? onOpenSftp;

  const HostViewsSwitcher({
    super.key,
    this.onConnect,
    this.onOpenSftp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(hostCatalogViewModeProvider);
    final hosts = ref.watch(filteredHostsProvider);
    final filter = ref.watch(hostFilterProvider);

    return Column(
      children: [
        // Top action bar: Search, Filter chips, View switcher, Add Host button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: ShellitColors.obsidianBackground,
            border: Border(
                bottom: BorderSide(color: ShellitColors.border, width: 1)),
          ),
          child: Row(
            children: [
              // Search input
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    style: const TextStyle(
                        fontSize: 13, color: ShellitColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search hosts by name, IP, or tag...',
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: ShellitColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      suffixIcon: filter.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                ref.read(hostFilterProvider.notifier).state =
                                    filter.copyWith(searchQuery: '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      ref.read(hostFilterProvider.notifier).state =
                          filter.copyWith(searchQuery: val);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // View Mode Segmented Buttons
              Container(
                decoration: BoxDecoration(
                  color: ShellitColors.obsidianCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ShellitColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeButton(
                      ref: ref,
                      icon: Icons.grid_view,
                      mode: HostCatalogViewMode.grid,
                      tooltip: 'Grid View',
                      isActive: viewMode == HostCatalogViewMode.grid,
                    ),
                    _buildViewModeButton(
                      ref: ref,
                      icon: Icons.view_headline,
                      mode: HostCatalogViewMode.denseList,
                      tooltip: 'Dense List View',
                      isActive: viewMode == HostCatalogViewMode.denseList,
                    ),
                    _buildViewModeButton(
                      ref: ref,
                      icon: Icons.account_tree_outlined,
                      mode: HostCatalogViewMode.folderTree,
                      tooltip: 'Folder Tree View',
                      isActive: viewMode == HostCatalogViewMode.folderTree,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Add Host Button
              ElevatedButton.icon(
                onPressed: () => _openAddHostDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Host', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShellitColors.accentBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Body: Views
        Expanded(
          child: hosts.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildCurrentView(context, ref, viewMode, hosts),
        ),
      ],
    );
  }

  Widget _buildViewModeButton({
    required WidgetRef ref,
    required IconData icon,
    required HostCatalogViewMode mode,
    required String tooltip,
    required bool isActive,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          ref.read(hostCatalogViewModeProvider.notifier).state = mode;
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: isActive
              ? ShellitColors.accentBlue.withValues(alpha: 0.2)
              : Colors.transparent,
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? ShellitColors.accentBlue
                : ShellitColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dns_outlined,
              size: 48, color: ShellitColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No hosts found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ShellitColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create a new host or adjust search filters.',
            style: TextStyle(fontSize: 13, color: ShellitColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _openAddHostDialog(context, ref),
            child: const Text('Create Host'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    WidgetRef ref,
    HostCatalogViewMode mode,
    List<HostEntity> hosts,
  ) {
    switch (mode) {
      case HostCatalogViewMode.grid:
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                (constraints.maxWidth / 300).floor().clamp(1, 4);
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.6,
              ),
              itemCount: hosts.length,
              itemBuilder: (context, index) {
                final host = hosts[index];
                return HostCard(
                  key: ValueKey(host.id),
                  host: host,
                  onConnect: () => onConnect?.call(host),
                  onOpenSftp: () => onOpenSftp?.call(host),
                  onEdit: () => _openEditHostDialog(context, ref, host),
                  onDelete: () => _handleDeleteHost(context, ref, host.id),
                );
              },
            );
          },
        );

      case HostCatalogViewMode.denseList:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: hosts.length,
          itemBuilder: (context, index) {
            final host = hosts[index];
            return HostCard(
              key: ValueKey(host.id),
              host: host,
              isDense: true,
              onConnect: () => onConnect?.call(host),
              onOpenSftp: () => onOpenSftp?.call(host),
              onEdit: () => _openEditHostDialog(context, ref, host),
              onDelete: () => _handleDeleteHost(context, ref, host.id),
            );
          },
        );

      case HostCatalogViewMode.folderTree:
        return _buildFolderTreeView(context, ref, hosts);
    }
  }

  Widget _buildFolderTreeView(
      BuildContext context, WidgetRef ref, List<HostEntity> hosts) {
    // Group hosts by folderId or 'Uncategorized'
    final Map<String, List<HostEntity>> grouped = {};
    for (final host in hosts) {
      final key = host.folderId ?? 'Uncategorized';
      grouped.putIfAbsent(key, () => []).add(host);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.folder_outlined,
                color: ShellitColors.accentBlue),
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              '${entry.value.length} hosts',
              style:
                  const TextStyle(color: ShellitColors.textMuted, fontSize: 12),
            ),
            children: entry.value.map((host) {
              return HostCard(
                key: ValueKey(host.id),
                host: host,
                isDense: true,
                onConnect: () => onConnect?.call(host),
                onOpenSftp: () => onOpenSftp?.call(host),
                onEdit: () => _openEditHostDialog(context, ref, host),
                onDelete: () => _handleDeleteHost(context, ref, host.id),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openAddHostDialog(BuildContext context, WidgetRef ref) async {
    final keyManager = ref.read(keyManagerProvider);
    final keys = await keyManager?.getAllKeys() ?? [];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => HostFormDialog(
        availableKeys: keys,
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
          final res = await ref.read(hostsProvider.notifier).addHost(newHost);
          if (res.isError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Failed to save host: ${res.failureOrNull?.message}'),
                backgroundColor: ShellitColors.statusRed,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _openEditHostDialog(
      BuildContext context, WidgetRef ref, HostEntity host) async {
    final keyManager = ref.read(keyManagerProvider);
    final keys = await keyManager?.getAllKeys() ?? [];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => HostFormDialog(
        initialHost: host,
        availableKeys: keys,
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
          final res =
              await ref.read(hostsProvider.notifier).updateHost(updatedHost);
          if (res.isError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to update host: ${res.failureOrNull?.message}'),
                backgroundColor: ShellitColors.statusRed,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _handleDeleteHost(
      BuildContext context, WidgetRef ref, String hostId) async {
    final res = await ref.read(hostsProvider.notifier).deleteHost(hostId);
    if (res.isError && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete host: ${res.failureOrNull?.message}'),
          backgroundColor: ShellitColors.statusRed,
        ),
      );
    }
  }
}
