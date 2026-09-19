import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../controllers/ai_snippet_controller.dart';
import '../../di/app_providers.dart';
import 'snippets_screen.dart';

/// Full-fledged interactive multi-turn chat view for generating shell snippets with Gemini.
class AiSnippetChatView extends ConsumerStatefulWidget {
  final VoidCallback onOpenSettings;

  const AiSnippetChatView({
    super.key,
    required this.onOpenSettings,
  });

  @override
  ConsumerState<AiSnippetChatView> createState() => _AiSnippetChatViewState();
}

class _AiSnippetChatViewState extends ConsumerState<AiSnippetChatView> {
  late final TextEditingController _inputController;
  late final ScrollController _scrollController;
  final Set<String> _savedSnippetIds = {};

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? customPrompt]) async {
    final text = customPrompt ?? _inputController.text;
    if (text.trim().isEmpty) return;

    if (customPrompt == null) {
      _inputController.clear();
    }

    final activeTab = ref.read(sessionManagerProvider).activeTab;
    final osType = activeTab?.title != null ? 'Linux/Unix Terminal' : null;

    await ref
        .read(aiChatControllerProvider.notifier)
        .sendPrompt(text, osType: osType);
    _scrollToBottom();
  }

  void _executeCommand(String command, String title, [SessionTab? specificTab]) {
    final sessionState = ref.read(sessionManagerProvider);
    final connectedTabs = sessionState.tabs
        .where((t) => t.terminalSession != null)
        .toList();

    final tab = specificTab ??
        (sessionState.activeTab?.terminalSession != null
            ? sessionState.activeTab
            : (connectedTabs.isNotEmpty ? connectedTabs.first : null));

    if (tab?.terminalSession != null) {
      final cmdWithNewline =
          command.endsWith('\n') ? command : '$command\n';
      tab!.terminalSession!.inputStream.add(
        Uint8List.fromList(utf8.encode(cmdWithNewline)),
      );
      final tabTitle = tab.title.isNotEmpty ? tab.title : 'terminal';
      final hostInfo = tab.host?.hostname != null ? ' (${tab.host!.hostname})' : '';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: ShellitColors.statusGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Command sent to ',
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '$tabTitle$hostInfo',
                        style: const TextStyle(
                          color: ShellitColors.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View in Terminal',
            textColor: ShellitColors.accentCyan,
            onPressed: () {
              ref.read(sessionManagerProvider.notifier).setActiveTab(tab.id);
            },
          ),
          backgroundColor: ShellitColors.obsidianCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: ShellitColors.border),
          ),
        ),
      );
    } else {
      final noSessionMsg = context.tr(
        'snippets.ai.no_active_terminal',
        defaultText: 'No active terminal session to execute command',
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  noSessionMsg,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: ShellitColors.obsidianCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: ShellitColors.border),
          ),
        ),
      );
    }
  }

  Future<void> _saveSnippetToLibrary(AiSnippetResponse snippet) async {
    final repo = ref.read(appSnippetRepositoryProvider);
    final entity = SnippetEntity(
      id: 'ai-snip-${DateTime.now().millisecondsSinceEpoch}',
      title: snippet.title,
      command: snippet.command,
      description: snippet.description.isNotEmpty
          ? snippet.description
          : snippet.explanation,
      tags: snippet.tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await repo.saveSnippet(entity);
    ref.invalidate(snippetsListProvider);

    setState(() {
      _savedSnippetIds.add(snippet.title);
    });

    if (mounted) {
      final savedMsg = context.tr(
        'snippets.ai.saved_success',
        defaultText: 'Snippet "{title}" saved to library',
        params: {'title': snippet.title},
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bookmark_added_outlined,
                  size: 16, color: ShellitColors.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  savedMsg,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: ShellitColors.obsidianCard,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: ShellitColors.border),
          ),
        ),
      );
    }
  }

  Widget _buildRunInTerminalButton(AiSnippetResponse snippet) {
    final sessionState = ref.watch(sessionManagerProvider);
    final connectedTabs = sessionState.tabs
        .where((t) => t.terminalSession != null)
        .toList();

    if (connectedTabs.isEmpty) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.play_arrow, size: 14, color: ShellitColors.textMuted),
        label: Text(
          context.tr('snippets.ai.btn_run_terminal', defaultText: 'Run in Terminal'),
          style: const TextStyle(color: ShellitColors.textMuted, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: const BorderSide(color: ShellitColors.border),
        ),
        onPressed: () => _executeCommand(snippet.command, snippet.title, null),
      );
    }

    if (connectedTabs.length == 1) {
      final singleTab = connectedTabs.first;
      return OutlinedButton.icon(
        icon: const Icon(Icons.play_arrow, size: 14, color: ShellitColors.statusGreen),
        label: Text(
          'Run in ${singleTab.title}',
          style: const TextStyle(
            color: ShellitColors.statusGreen,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: const BorderSide(color: ShellitColors.statusGreen),
        ),
        onPressed: () => _executeCommand(snippet.command, snippet.title, singleTab),
      );
    }

    final defaultTab = (sessionState.activeTab?.terminalSession != null)
        ? sessionState.activeTab!
        : connectedTabs.first;

    return PopupMenuButton<SessionTab>(
      tooltip: 'Select target host',
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ShellitColors.border),
      ),
      onSelected: (tab) => _executeCommand(snippet.command, snippet.title, tab),
      itemBuilder: (context) {
        return connectedTabs.map((tab) {
          final isSelected = tab.id == defaultTab.id;
          return PopupMenuItem<SessionTab>(
            value: tab,
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 15,
                  color: isSelected ? ShellitColors.statusGreen : ShellitColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tab.title,
                    style: TextStyle(
                      color: isSelected ? ShellitColors.statusGreen : ShellitColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tab.host?.hostname != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    tab.host!.hostname,
                    style: const TextStyle(color: ShellitColors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: OutlinedButton.icon(
        icon: const Icon(Icons.play_arrow, size: 14, color: ShellitColors.statusGreen),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Run in ${defaultTab.title}',
              style: const TextStyle(
                color: ShellitColors.statusGreen,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: ShellitColors.statusGreen),
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          side: const BorderSide(color: ShellitColors.statusGreen),
        ),
        onPressed: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider);
    final vaultRepo = ref.watch(appVaultRepositoryProvider);

    return FutureBuilder<VaultSettingsEntity>(
      future: vaultRepo.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final hasKey = settings?.geminiApiKey != null &&
            settings!.geminiApiKey!.trim().isNotEmpty;

        if (!hasKey) {
          return _buildNoApiKeyView();
        }

        return Column(
          children: [
            // Top chat bar (model indicator and clear button)
            _buildChatHeader(settings.geminiModelId),

            // Quick Prompt Chips
            _buildQuickPromptsBar(),

            // Chat Messages Thread
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildEmptyWelcomeView()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // Generating indicator
            if (chatState.isGenerating) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(
                        'snippets.ai.thinking',
                        defaultText: 'Generating snippet...',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.accentCyan,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error banner
            if (chatState.error != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ShellitColors.statusRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ShellitColors.statusRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: ShellitColors.statusRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          'snippets.ai.error_prefix',
                          defaultText: 'AI Error: {error}',
                          params: {'error': chatState.error!},
                        ),
                        style: const TextStyle(
                          color: ShellitColors.statusRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bottom Input Bar
            _buildInputBar(chatState.isGenerating),
          ],
        );
      },
    );
  }

  Widget _buildNoApiKeyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ShellitColors.accentCyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: ShellitColors.accentCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                'snippets.ai.need_key_title',
                defaultText: 'Gemini API Key Required',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                context.tr(
                  'snippets.ai.need_key_desc',
                  defaultText:
                      'Please configure your free Gemini API key in Settings to use the AI Snippet Assistant.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: Text(
                context.tr(
                  'snippets.ai.btn_open_settings',
                  defaultText: 'Open Settings',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ShellitColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: widget.onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader(String modelId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianCard,
        border: Border(
          bottom: BorderSide(color: ShellitColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ShellitColors.accentCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ShellitColors.accentCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: ShellitColors.accentCyan,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr(
                    'snippets.ai.active_model',
                    defaultText: 'Model: {model}',
                    params: {'model': modelId},
                  ),
                  style: const TextStyle(
                    color: ShellitColors.accentCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            color: ShellitColors.textMuted,
            tooltip: context.tr(
              'snippets.ai.btn_clear_chat',
              defaultText: 'Clear Chat',
            ),
            onPressed: () {
              ref.read(aiChatControllerProvider.notifier).clearChat();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final prompts = [
      context.tr('snippets.ai.quick_docker', defaultText: 'Docker clean stopped containers'),
      context.tr('snippets.ai.quick_large_files', defaultText: 'Find files >100MB'),
      context.tr('snippets.ai.quick_ports', defaultText: 'List listening TCP ports'),
      context.tr('snippets.ai.quick_ram', defaultText: 'Top 10 memory consuming processes'),
      context.tr('snippets.ai.quick_logs', defaultText: 'Compress logs older than 7 days'),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = prompts[index];
          return ActionChip(
            label: Text(p),
            labelStyle: const TextStyle(
              color: ShellitColors.textSecondary,
              fontSize: 11,
            ),
            backgroundColor: ShellitColors.obsidianCard,
            side: const BorderSide(color: ShellitColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onPressed: () => _handleSend(p),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.terminal_outlined,
              size: 40,
              color: ShellitColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                'snippets.ai.welcome_title',
                defaultText: 'AI Snippet Assistant',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                context.tr(
                  'snippets.ai.welcome_desc',
                  defaultText:
                      'Describe any task or command you need in plain English or Russian, and Gemini will generate ready-to-run shell scripts.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 550),
          decoration: BoxDecoration(
            color: ShellitColors.accentBlue.withValues(alpha: 0.25),
            border: Border.all(
              color: ShellitColors.accentBlue.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: ShellitColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Assistant response with optional snippet card
    final snippet = message.snippet;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: ShellitColors.obsidianCard,
          border: Border.all(color: ShellitColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Assistant Title
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: ShellitColors.accentCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snippet?.title ?? 'Assistant',
                    style: const TextStyle(
                      color: ShellitColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            if (snippet?.description != null &&
                snippet!.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                snippet.description,
                style: const TextStyle(
                  color: ShellitColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],

            // Destructive danger warning badge
            if (snippet?.isDangerous == true) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ShellitColors.statusRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ShellitColors.statusRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: ShellitColors.statusRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        snippet?.dangerWarning ??
                            context.tr(
                              'snippets.ai.danger_badge',
                              defaultText: 'DESTRUCTIVE COMMAND',
                            ),
                        style: const TextStyle(
                          color: ShellitColors.statusRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Command Code Box
            if (snippet != null && snippet.command.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ShellitColors.border.withValues(alpha: 0.8),
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

              // Tags
              if (snippet.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: snippet.tags.map((t) {
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
                        t,
                        style: const TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              // Action Buttons: Run in Terminal & Save to Snippets
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 14),
                    label: Text(context.tr('common.copy', defaultText: 'Copy')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ShellitColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: snippet.command));
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 14, color: ShellitColors.statusGreen),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('snippets.copied_snackbar',
                                    defaultText: 'Copied to clipboard'),
                                style: const TextStyle(
                                  color: ShellitColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: ShellitColors.obsidianCard,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: ShellitColors.border),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildRunInTerminalButton(snippet),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(
                      _savedSnippetIds.contains(snippet.title)
                          ? Icons.check
                          : Icons.bookmark_add_outlined,
                      size: 14,
                    ),
                    label: Text(
                      context.tr(
                        'snippets.ai.btn_save_snippet',
                        defaultText: 'Save to Snippets',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _savedSnippetIds.contains(snippet.title)
                          ? ShellitColors.statusGreen.withValues(alpha: 0.2)
                          : ShellitColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    onPressed: _savedSnippetIds.contains(snippet.title)
                        ? null
                        : () => _saveSnippetToLibrary(snippet),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isGenerating) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianCard,
        border: Border(
          top: BorderSide(color: ShellitColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  final isCtrl = HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed;
                  final isEnter =
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter;
                  if (isCtrl && isEnter && !isGenerating) {
                    _handleSend();
                  }
                }
              },
              child: TextField(
                controller: _inputController,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: context.tr(
                    'snippets.ai.chat_placeholder',
                    defaultText:
                        'Ask for a snippet... (Ctrl+Enter to send)',
                  ),
                  hintStyle: const TextStyle(color: ShellitColors.textMuted),
                  filled: true,
                  fillColor: ShellitColors.obsidianBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ShellitColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: ShellitColors.accentCyan),
                  ),
                ),
                // Enter = newline (default behavior), Ctrl+Enter handled by KeyboardListener
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Circular send button with arrow icon (like modern chat apps)
          Tooltip(
            message: context.tr(
              'snippets.ai.send_tooltip',
              defaultText: 'Send (Ctrl+Enter)',
            ),
            child: InkWell(
              onTap: isGenerating ? null : () => _handleSend(),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGenerating
                      ? ShellitColors.accentBlue.withValues(alpha: 0.5)
                      : ShellitColors.accentBlue,
                ),
                child: Center(
                  child: isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
