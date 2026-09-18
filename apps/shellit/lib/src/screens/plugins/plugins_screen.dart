import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../../plugins/plugin_manager_provider.dart';

class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsAsync = ref.watch(pluginManagerProvider);

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: const Text(
          'Desktop Plugin Extensions (.shellit)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Install .shellit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () => _showInstallDialog(context, ref),
            ),
          ),
        ],
      ),
      body: pluginsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ShellitColors.accentCyan),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading plugins: $err',
            style: const TextStyle(color: ShellitColors.statusRed),
          ),
        ),
        data: (plugins) {
          if (plugins.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.extension_off_outlined,
                    size: 48,
                    color: ShellitColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No plugins installed',
                    style: TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Install .shellit package to extend Shellit with custom tools',
                    style: TextStyle(
                      color: ShellitColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Install .shellit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShellitColors.accentBlue,
                    ),
                    onPressed: () => _showInstallDialog(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: plugins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plugin = plugins[index];
              return Card(
                color: ShellitColors.obsidianCard,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: ShellitColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ShellitColors.accentBlue.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.extension_outlined,
                              color: ShellitColors.accentCyan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      plugin.manifest.name,
                                      style: const TextStyle(
                                        color: ShellitColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ShellitColors.obsidianBackground,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: ShellitColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        plugin.manifest.target.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: ShellitColors.accentBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'v${plugin.manifest.version} by ${plugin.manifest.author} • ${plugin.manifest.id}',
                                  style: const TextStyle(
                                    color: ShellitColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: ShellitColors.statusRed,
                            ),
                            tooltip: 'Uninstall Plugin',
                            onPressed: () => _confirmUninstall(context, ref, plugin),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: plugin.isEnabled,
                            activeThumbColor: ShellitColors.statusGreen,
                            onChanged: (val) {
                              ref
                                  .read(pluginManagerProvider.notifier)
                                  .togglePlugin(plugin.manifest.id, val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        plugin.manifest.description,
                        style: const TextStyle(
                          color: ShellitColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Permissions: ',
                            style: TextStyle(
                              color: ShellitColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (plugin.manifest.permissions.isEmpty)
                            const Text(
                              'None',
                              style: TextStyle(
                                color: ShellitColors.textMuted,
                                fontSize: 11,
                              ),
                            )
                          else
                            ...plugin.manifest.permissions.map((perm) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    perm,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: ShellitColors.accentCyan,
                                    ),
                                  ),
                                  backgroundColor: ShellitColors.obsidianBackground,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              );
                            }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmUninstall(
    BuildContext context,
    WidgetRef ref,
    InstalledPlugin plugin,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(
          'Uninstall ${plugin.manifest.name}?',
          style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 15),
        ),
        content: Text(
          'Are you sure you want to remove this plugin and all its files?',
          style: const TextStyle(color: ShellitColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ref
                  .read(pluginManagerProvider.notifier)
                  .uninstallPlugin(plugin.manifest.id);
              if (context.mounted) {
                if (res.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Uninstalled ${plugin.manifest.name}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${res.failureOrNull?.message}')),
                  );
                }
              }
            },
            child: const Text('Uninstall', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInstallDialog(BuildContext context, WidgetRef ref) {
    final pathCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: const Text(
          'Install Plugin Package',
          style: TextStyle(color: ShellitColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter full file path to .shellit (or .zip) bundle archive:',
                style: TextStyle(
                  color: ShellitColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pathCtrl,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  labelText: 'Plugin Archive File Path',
                  hintText: r'C:\path\to\docker_monitor.shellit',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
            ),
            onPressed: () async {
              final path = pathCtrl.text.trim();
              if (path.isEmpty) return;
              Navigator.pop(ctx);

              final res = await ref
                  .read(pluginManagerProvider.notifier)
                  .installFromArchive(path);

              if (context.mounted) {
                if (res.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Plugin "${res.getOrThrow().manifest.name}" installed safely!',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: ${res.failureOrNull?.message}'),
                      backgroundColor: ShellitColors.statusRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Install', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
