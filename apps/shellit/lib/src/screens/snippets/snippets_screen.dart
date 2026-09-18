import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

final snippetsListProvider = FutureProvider.autoDispose<List<SnippetEntity>>((
  ref,
) async {
  final repo = ref.watch(appSnippetRepositoryProvider);
  return repo.getAllSnippets();
});

class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetsListProvider);
    final activeTab = ref.watch(sessionManagerProvider).activeTab;

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: const Text(
          'Command Snippets Library',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Snippet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () => _showEditSnippetDialog(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Search snippets by title, command, or tags...',
                hintStyle: const TextStyle(color: ShellitColors.textMuted),
                prefixIcon: const Icon(
                  Icons.search,
                  color: ShellitColors.textMuted,
                  size: 18,
                ),
                filled: true,
                fillColor: ShellitColors.obsidianCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ShellitColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ShellitColors.accentBlue),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: snippetsAsync.when(
              data: (snippets) {
                final filtered = snippets.where((s) {
                  if (_searchQuery.isEmpty) return true;
                  return s.title.toLowerCase().contains(_searchQuery) ||
                      s.command.toLowerCase().contains(_searchQuery) ||
                      s.tags.any((t) => t.toLowerCase().contains(_searchQuery));
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.code_outlined,
                          size: 48,
                          color: ShellitColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snippets.isEmpty
                              ? 'No Snippets Saved Yet'
                              : 'No snippets match "$_searchQuery"',
                          style: const TextStyle(
                            color: ShellitColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Save frequently used commands for instant 1-click execution.',
                          style: TextStyle(
                            color: ShellitColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (snippets.isEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First Snippet'),
                            onPressed: () => _showEditSnippetDialog(context),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final snippet = filtered[index];
                    return Card(
                      color: ShellitColors.obsidianCard,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: ShellitColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.terminal,
                                  color: ShellitColors.accentCyan,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    snippet.title,
                                    style: const TextStyle(
                                      color: ShellitColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (activeTab?.terminalSession != null)
                                  Tooltip(
                                    message:
                                        'Execute in active terminal (${activeTab!.title})',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.play_arrow,
                                        color: ShellitColors.statusGreen,
                                        size: 20,
                                      ),
                                      onPressed: () => _executeSnippet(snippet),
                                    ),
                                  ),
                                Tooltip(
                                  message: 'Copy to clipboard',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      color: ShellitColors.textSecondary,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: snippet.command),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Copied "${snippet.title}" to clipboard',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: ShellitColors.textMuted,
                                    size: 18,
                                  ),
                                  color: ShellitColors.obsidianCard,
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _showEditSnippetDialog(
                                        context,
                                        snippet: snippet,
                                      );
                                    } else if (action == 'delete') {
                                      _deleteSnippet(snippet.id);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: ShellitColors.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: ShellitColors.statusRed,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (snippet.description != null &&
                                snippet.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                snippet.description!,
                                style: const TextStyle(
                                  color: ShellitColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ShellitColors.border.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: SelectableText(
                                snippet.command,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  color: ShellitColors.accentCyan,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (snippet.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: snippet.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ShellitColors.border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: ShellitColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: ShellitColors.statusRed),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeSnippet(SnippetEntity snippet) {
    final activeTab = ref.read(sessionManagerProvider).activeTab;
    if (activeTab?.terminalSession != null) {
      final cmdWithNewline = snippet.command.endsWith('\n')
          ? snippet.command
          : '${snippet.command}\n';
      activeTab!.terminalSession!.inputStream.add(
        Uint8List.fromList(utf8.encode(cmdWithNewline)),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Executed "${snippet.title}" in ${activeTab.title}'),
          backgroundColor: ShellitColors.obsidianCard,
        ),
      );
    }
  }

  Future<void> _deleteSnippet(String id) async {
    final repo = ref.read(appSnippetRepositoryProvider);
    await repo.deleteSnippet(id);
    ref.invalidate(snippetsListProvider);
  }

  void _showEditSnippetDialog(BuildContext context, {SnippetEntity? snippet}) {
    final isEditing = snippet != null;
    final titleCtrl = TextEditingController(text: snippet?.title ?? '');
    final cmdCtrl = TextEditingController(text: snippet?.command ?? '');
    final descCtrl = TextEditingController(text: snippet?.description ?? '');
    final tagsCtrl = TextEditingController(
      text: snippet?.tags.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Text(
          isEditing ? 'Edit Snippet' : 'New Command Snippet',
          style: const TextStyle(
            color: ShellitColors.textPrimary,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Snippet Title (e.g. Restart Docker Swarm)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cmdCtrl,
                  maxLines: 4,
                  style: const TextStyle(
                    color: ShellitColors.accentCyan,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Command / Script',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsCtrl,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    labelText:
                        'Tags (comma separated, e.g. docker, prod, logs)',
                  ),
                ),
              ],
            ),
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
              if (titleCtrl.text.trim().isEmpty ||
                  cmdCtrl.text.trim().isEmpty) {
                return;
              }

              final tags = tagsCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              final newSnippet = SnippetEntity(
                id:
                    snippet?.id ??
                    'snip-${DateTime.now().millisecondsSinceEpoch}',
                title: titleCtrl.text.trim(),
                command: cmdCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                tags: tags,
                folderId: snippet?.folderId,
                createdAt: snippet?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final repo = ref.read(appSnippetRepositoryProvider);
              await repo.saveSnippet(newSnippet);
              ref.invalidate(snippetsListProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              isEditing ? 'Save Changes' : 'Create Snippet',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
