import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/session_manager_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vault_provider.dart';
import '../../theme/shellit_theme.dart';
import '../../theme/terminal_color_schemes.dart';

enum OmniItemType {
  host,
  action,
  snippet,
  theme,
}

class OmniCommandItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final OmniItemType type;
  final VoidCallback onSelect;

  const OmniCommandItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onSelect,
  });
}

class OmniSearchModal extends ConsumerStatefulWidget {
  final ValueChanged<HostEntity>? onSelectHost;
  final List<SnippetEntity>? snippets;
  final ValueChanged<SnippetEntity>? onExecuteSnippet;

  const OmniSearchModal({
    super.key,
    this.onSelectHost,
    this.snippets,
    this.onExecuteSnippet,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<HostEntity>? onSelectHost,
    List<SnippetEntity>? snippets,
    ValueChanged<SnippetEntity>? onExecuteSnippet,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => OmniSearchModal(
        onSelectHost: onSelectHost,
        snippets: snippets,
        onExecuteSnippet: onExecuteSnippet,
      ),
    );
  }

  @override
  ConsumerState<OmniSearchModal> createState() => _OmniSearchModalState();
}

class _OmniSearchModalState extends ConsumerState<OmniSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OmniCommandItem> _buildItems(BuildContext context, String query) {
    final hosts = ref.read(hostsProvider);
    final sessionState = ref.read(sessionManagerProvider);
    final activeTab = sessionState.activeTab;
    final items = <OmniCommandItem>[];

    final q = query.trim().toLowerCase();

    // 0. Open Tabs
    for (final tab in sessionState.tabs) {
      if (q.isEmpty ||
          tab.displayTitle.toLowerCase().contains(q) ||
          (tab.host?.hostname.toLowerCase().contains(q) ?? false) ||
          (tab.host?.label.toLowerCase().contains(q) ?? false)) {
        final isActive = tab.id == activeTab?.id;
        IconData tabIcon = Icons.terminal;
        switch (tab.type) {
          case TabType.terminal:
            tabIcon = Icons.terminal;
            break;
          case TabType.sftp:
            tabIcon = Icons.folder_shared_outlined;
            break;
          case TabType.splitTerminal:
            tabIcon = Icons.dashboard_customize_outlined;
            break;
        }

        items.add(
          OmniCommandItem(
            id: 'tab-${tab.id}',
            title: tab.displayTitle,
            subtitle: isActive
                ? context.tr('omni.switch_tab_active',
                    defaultText: 'Switch Tab (Active)')
                : context.tr('omni.switch_tab_target',
                        defaultText: 'Switch Tab ({target})')
                    .replaceAll(
                        '{target}',
                        tab.host?.connectionTarget ??
                            context.tr('omni.session', defaultText: 'Session')),
            icon: tabIcon,
            type: OmniItemType.action,
            onSelect: () {
              Navigator.of(context).pop();
              ref.read(sessionManagerProvider.notifier).setActiveTab(tab.id);
            },
          ),
        );
      }
    }

    // 1. Hosts
    for (final host in hosts) {
      if (q.isEmpty ||
          host.label.toLowerCase().contains(q) ||
          host.hostname.toLowerCase().contains(q) ||
          host.tags.any((t) => t.toLowerCase().contains(q))) {
        items.add(
          OmniCommandItem(
            id: 'host-${host.id}',
            title: host.label,
            subtitle: context.tr('omni.connect_ssh',
                    defaultText: 'Connect SSH ({target})')
                .replaceAll('{target}', host.connectionTarget),
            icon: Icons.dns_outlined,
            type: OmniItemType.host,
            onSelect: () {
              Navigator.of(context).pop();
              widget.onSelectHost?.call(host);
            },
          ),
        );
      }
    }

    // 2. Actions
    final actions = [
      if (activeTab != null) ...[
        OmniCommandItem(
          id: 'action-split-h',
          title: context.tr('splits.split_horizontal',
              defaultText: 'Split Horizontally'),
          subtitle: context.tr('omni.split_h_subtitle',
              defaultText: 'Split active terminal pane horizontally'),
          icon: Icons.view_column_outlined,
          type: OmniItemType.action,
          onSelect: () {
            Navigator.of(context).pop();
            ref
                .read(sessionManagerProvider.notifier)
                .setSplitLayout(activeTab.id, SplitLayoutType.horizontal);
          },
        ),
        OmniCommandItem(
          id: 'action-split-v',
          title: context.tr('splits.split_vertical',
              defaultText: 'Split Vertically'),
          subtitle: context.tr('omni.split_v_subtitle',
              defaultText: 'Split active terminal pane vertically'),
          icon: Icons.table_rows_outlined,
          type: OmniItemType.action,
          onSelect: () {
            Navigator.of(context).pop();
            ref
                .read(sessionManagerProvider.notifier)
                .setSplitLayout(activeTab.id, SplitLayoutType.vertical);
          },
        ),
        OmniCommandItem(
          id: 'action-split-2x2',
          title: context.tr('splits.split_grid',
              defaultText: 'Split 2x2 Grid'),
          subtitle: context.tr('omni.split_grid_subtitle',
              defaultText: 'Split into 4 terminal panes'),
          icon: Icons.grid_view_sharp,
          type: OmniItemType.action,
          onSelect: () {
            Navigator.of(context).pop();
            ref
                .read(sessionManagerProvider.notifier)
                .setSplitLayout(activeTab.id, SplitLayoutType.grid2x2);
          },
        ),
      ],
      OmniCommandItem(
        id: 'action-lock-vault',
        title: context.tr('omni.lock_vault', defaultText: 'Lock Vault'),
        subtitle: context.tr('omni.lock_vault_subtitle',
            defaultText: 'Secure database and wipe keys from memory'),
        icon: Icons.lock_outline,
        type: OmniItemType.action,
        onSelect: () {
          Navigator.of(context).pop();
          ref.read(vaultProvider.notifier).lock();
        },
      ),
    ];

    for (final act in actions) {
      if (q.isEmpty ||
          act.title.toLowerCase().contains(q) ||
          act.subtitle.toLowerCase().contains(q)) {
        items.add(act);
      }
    }

    // 3. Snippets
    final snippets = widget.snippets ?? [];
    for (final snip in snippets) {
      if (q.isEmpty ||
          snip.title.toLowerCase().contains(q) ||
          snip.command.toLowerCase().contains(q) ||
          snip.tags.any((t) => t.toLowerCase().contains(q))) {
        items.add(
          OmniCommandItem(
            id: 'snippet-${snip.id}',
            title: snip.title,
            subtitle: context.tr('omni.run_snippet',
                    defaultText: 'Run: {cmd}')
                .replaceAll('{cmd}', snip.command),
            icon: Icons.play_arrow_outlined,
            type: OmniItemType.snippet,
            onSelect: () {
              Navigator.of(context).pop();
              widget.onExecuteSnippet?.call(snip);
            },
          ),
        );
      }
    }

    // 3. Themes
    for (final themeName in TerminalColorSchemes.allSchemes.keys) {
      if (q.isEmpty ||
          themeName.toLowerCase().contains(q) ||
          'theme'.contains(q)) {
        items.add(
          OmniCommandItem(
            id: 'theme-$themeName',
            title: context.tr('omni.set_theme',
                    defaultText: 'Set Terminal Theme: {name}')
                .replaceAll('{name}', themeName),
            subtitle: context.tr('omni.set_theme_subtitle',
                defaultText: 'Switch active color scheme'),
            icon: Icons.palette_outlined,
            type: OmniItemType.theme,
            onSelect: () {
              Navigator.of(context).pop();
              ref.read(terminalSchemeNameProvider.notifier).state = themeName;
            },
          ),
        );
      }
    }

    return items;
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final items = _buildItems(context, _searchController.text);
    if (items.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex = (_selectedIndex + 1) % items.length);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() =>
          _selectedIndex = (_selectedIndex - 1 + items.length) % items.length);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex < items.length) {
        items[_selectedIndex].onSelect();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context, _searchController.text);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKey,
        child: Container(
          width: 580,
          decoration: BoxDecoration(
            color: ShellitColors.obsidianCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ShellitColors.borderFocus, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 15, color: ShellitColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.tr('omni.search_hint',
                        defaultText:
                            'Type a command, host, or action (Ctrl+K)...'),
                    prefixIcon: const Icon(Icons.search,
                        color: ShellitColors.accentBlue, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (_) {
                    setState(() => _selectedIndex = 0);
                  },
                ),
              ),
              const Divider(height: 1),

              // Results list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.tr('omni.no_results',
                              defaultText:
                                  'No matching commands or hosts found'),
                          style: const TextStyle(
                              color: ShellitColors.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: item.onSelect,
                            onHover: (hovering) {
                              if (hovering) {
                                setState(() => _selectedIndex = index);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ShellitColors.accentBlue
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isSelected
                                        ? ShellitColors.accentBlue
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 18,
                                    color: isSelected
                                        ? ShellitColors.accentBlue
                                        : ShellitColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: ShellitColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: ShellitColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Text(
                                      context.tr('omni.key_enter',
                                          defaultText: '↵ Enter'),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: ShellitColors.accentBlue,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Divider(height: 1),

              // Footer hints
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      context.tr('omni.footer_navigate',
                          defaultText: '↑↓ Navigate'),
                      style: const TextStyle(
                          fontSize: 11, color: ShellitColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('omni.footer_select',
                          defaultText: '↵ Select'),
                      style: const TextStyle(
                          fontSize: 11, color: ShellitColors.textMuted),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('omni.footer_close',
                          defaultText: 'Esc Close'),
                      style: const TextStyle(
                          fontSize: 11, color: ShellitColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
