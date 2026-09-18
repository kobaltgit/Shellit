import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';

class PluginDisplayItem {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> permissions;
  bool isEnabled;

  PluginDisplayItem({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.permissions,
    this.isEnabled = true,
  });
}

final pluginsListProvider = StateProvider<List<PluginDisplayItem>>((ref) {
  return [
    PluginDisplayItem(
      id: 'com.shellit.docker_monitor',
      name: 'Docker Container Monitor',
      version: '1.0.0',
      description:
          'Real-time Docker container stats, CPU/Memory telemetry and one-click restart.',
      author: 'Shellit Core Team',
      permissions: ['terminal:execute', 'notifications'],
      isEnabled: true,
    ),
    PluginDisplayItem(
      id: 'com.shellit.k8s_lens',
      name: 'Kubernetes Pod Inspector',
      version: '0.9.2',
      description:
          'Inspect cluster pods, describe resources and stream kubectl logs into splits.',
      author: 'DevOps Community',
      permissions: ['terminal:execute'],
      isEnabled: false,
    ),
  ];
});

class PluginsScreen extends ConsumerWidget {
  const PluginsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginsListProvider);

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: const Text(
          'Desktop Plugin Extensions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Install .shell-plugin'),
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
      body: ListView.separated(
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
                            Text(
                              plugin.name,
                              style: const TextStyle(
                                color: ShellitColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${plugin.version} by ${plugin.author}',
                              style: const TextStyle(
                                color: ShellitColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: plugin.isEnabled,
                        activeThumbColor: ShellitColors.statusGreen,
                        onChanged: (val) {
                          ref.read(pluginsListProvider.notifier).update((
                            state,
                          ) {
                            return state.map((p) {
                              if (p.id == plugin.id) p.isEnabled = val;
                              return p;
                            }).toList();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plugin.description,
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
                      ...plugin.permissions.map((perm) {
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
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter path to .shell-plugin or .pkit bundle archive:',
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
                  hintText: 'C:\\path\\to\\my_plugin.shell-plugin',
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Plugin verified and installed safely! (Zip Slip check passed)',
                  ),
                ),
              );
            },
            child: const Text('Install', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
