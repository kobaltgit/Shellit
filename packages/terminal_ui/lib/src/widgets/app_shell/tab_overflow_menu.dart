import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';

class TabOverflowMenu extends ConsumerStatefulWidget {
  final ValueChanged<String> onSelectTab;
  final ValueChanged<String> onCloseTab;

  const TabOverflowMenu({
    super.key,
    required this.onSelectTab,
    required this.onCloseTab,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onSelectTab,
    required ValueChanged<String> onCloseTab,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 55, right: 180),
        child: SizedBox(
          width: 320,
          child: TabOverflowMenu(
            onSelectTab: (id) {
              Navigator.of(ctx).pop();
              onSelectTab(id);
            },
            onCloseTab: (id) {
              onCloseTab(id);
            },
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<TabOverflowMenu> createState() => _TabOverflowMenuState();
}

class _TabOverflowMenuState extends ConsumerState<TabOverflowMenu> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionManagerProvider);
    final tabs = sessionState.tabs;
    final activeId = sessionState.activeTabId;

    final filteredTabs = _query.isEmpty
        ? tabs
        : tabs.where((t) {
            final q = _query.toLowerCase();
            return t.displayTitle.toLowerCase().contains(q) ||
                (t.host?.hostname.toLowerCase().contains(q) ?? false) ||
                (t.host?.label.toLowerCase().contains(q) ?? false);
          }).toList();

    return Material(
      color: ShellitColors.obsidianCard,
      borderRadius: BorderRadius.circular(10),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ShellitColors.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search open tabs...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),
            const Divider(height: 1),

            // Tabs list
            Flexible(
              child: filteredTabs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No matching tabs',
                        style: TextStyle(
                            fontSize: 12, color: ShellitColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredTabs.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: ShellitColors.borderLight),
                      itemBuilder: (context, index) {
                        final tab = filteredTabs[index];
                        final isActive = tab.id == activeId;

                        IconData icon;
                        switch (tab.type) {
                          case TabType.terminal:
                            icon = Icons.terminal;
                            break;
                          case TabType.sftp:
                            icon = Icons.folder_shared_outlined;
                            break;
                          case TabType.splitTerminal:
                            icon = Icons.dashboard_customize_outlined;
                            break;
                        }

                        return InkWell(
                          onTap: () => widget.onSelectTab(tab.id),
                          child: Container(
                            color: isActive
                                ? ShellitColors.accentBlue
                                    .withValues(alpha: 0.12)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                if (tab.colorTag != null) ...[
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: tab.colorTag,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Icon(
                                  icon,
                                  size: 16,
                                  color: isActive
                                      ? ShellitColors.accentBlue
                                      : ShellitColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              tab.displayTitle,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isActive
                                                    ? Colors.white
                                                    : ShellitColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (tab.isPinned) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.push_pin,
                                                size: 11,
                                                color:
                                                    ShellitColors.accentBlue),
                                          ],
                                          if (tab.isProduction) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1),
                                              decoration: BoxDecoration(
                                                color: ShellitColors.statusRed
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                border: Border.all(
                                                    color:
                                                        ShellitColors.statusRed,
                                                    width: 0.5),
                                              ),
                                              child: const Text(
                                                'PROD',
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    color:
                                                        ShellitColors.statusRed,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (tab.host != null)
                                        Text(
                                          tab.host!.connectionTarget,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: ShellitColors.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 14),
                                  splashRadius: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 24, minHeight: 24),
                                  color: ShellitColors.textMuted,
                                  hoverColor: ShellitColors.statusRed
                                      .withValues(alpha: 0.2),
                                  onPressed: () => widget.onCloseTab(tab.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
