import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';

class TabContextMenu {
  static const List<Color> tagColors = [
    Color(0xFFFF5252), // Red
    Color(0xFFFFB300), // Amber
    Color(0xFF00E676), // Emerald
    Color(0xFF2979FF), // Electric Blue
    Color(0xFFAB47BC), // Purple
    Color(0xFF00E5FF), // Cyan
  ];

  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required SessionTab tab,
    required WidgetRef ref,
    VoidCallback? onDuplicate,
    VoidCallback? onOpenSftp,
    VoidCallback? onReconnect,
  }) async {
    final sessionNotifier = ref.read(sessionManagerProvider.notifier);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: [
        // 1. Session Operations
        if (onDuplicate != null)
          _buildItem(
            value: 'duplicate',
            icon: Icons.copy_rounded,
            title: context.tr(
              'tabs.menu_duplicate',
              defaultText: 'Duplicate Session',
            ),
            shortcut: 'Ctrl+D',
          ),
        if (onOpenSftp != null && tab.host != null)
          _buildItem(
            value: 'open_sftp',
            icon: Icons.folder_shared_outlined,
            title: tab.type == TabType.sftp
                ? context.tr(
                    'tabs.menu_open_terminal',
                    defaultText: 'Open Terminal for Host',
                  )
                : context.tr(
                    'tabs.menu_open_sftp',
                    defaultText: 'Open SFTP for this Host',
                  ),
          ),
        if (onReconnect != null)
          _buildItem(
            value: 'reconnect',
            icon: Icons.refresh,
            title: context.tr(
              'tabs.menu_reconnect',
              defaultText: 'Reconnect Session',
            ),
          ),

        const PopupMenuDivider(height: 8),

        // 2. Splits
        _buildItem(
          value: 'split_h',
          icon: Icons.view_column_outlined,
          title: context.tr(
            'tabs.menu_split_h',
            defaultText: 'Split Horizontally',
          ),
        ),
        _buildItem(
          value: 'split_v',
          icon: Icons.table_rows_outlined,
          title: context.tr(
            'tabs.menu_split_v',
            defaultText: 'Split Vertically',
          ),
        ),
        _buildItem(
          value: 'split_2x2',
          icon: Icons.grid_view_sharp,
          title: context.tr(
            'tabs.menu_split_2x2',
            defaultText: 'Split 2x2 Grid',
          ),
        ),
        if (tab.type == TabType.splitTerminal)
          _buildItem(
            value: 'split_single',
            icon: Icons.crop_square,
            title: context.tr(
              'tabs.menu_split_single',
              defaultText: 'Collapse to Single Pane',
            ),
          ),

        const PopupMenuDivider(height: 8),

        // 3. Customization
        _buildItem(
          value: 'rename',
          icon: Icons.drive_file_rename_outline,
          title: context.tr(
            'tabs.menu_rename',
            defaultText: 'Rename Tab...',
          ),
        ),
        _buildItem(
          value: 'color_tag',
          icon: Icons.palette_outlined,
          title: context.tr(
            'tabs.menu_color_tag',
            defaultText: 'Set Color Tag...',
          ),
        ),
        _buildItem(
          value: 'toggle_pin',
          icon: tab.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          title: tab.isPinned
              ? context.tr('tabs.menu_unpin', defaultText: 'Unpin Tab')
              : context.tr('tabs.menu_pin', defaultText: 'Pin Tab'),
        ),

        const PopupMenuDivider(height: 8),

        // 4. Closing hygiene
        _buildItem(
          value: 'close',
          icon: Icons.close,
          title: context.tr(
            'tabs.menu_close',
            defaultText: 'Close Tab',
          ),
          shortcut: 'Ctrl+W',
          isDestructive: true,
        ),
        _buildItem(
          value: 'close_others',
          icon: Icons.tab_unselected,
          title: context.tr(
            'tabs.menu_close_others',
            defaultText: 'Close Other Tabs',
          ),
        ),
        _buildItem(
          value: 'close_right',
          icon: Icons.arrow_forward,
          title: context.tr(
            'tabs.menu_close_right',
            defaultText: 'Close Tabs to the Right',
          ),
        ),
        _buildItem(
          value: 'close_disconnected',
          icon: Icons.cleaning_services_outlined,
          title: context.tr(
            'tabs.menu_close_disconnected',
            defaultText: 'Close Disconnected Sessions',
          ),
        ),
      ],
    );

    if (selected == null || !context.mounted) return;

    switch (selected) {
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'open_sftp':
        onOpenSftp?.call();
        break;
      case 'reconnect':
        onReconnect?.call();
        break;
      case 'split_h':
        sessionNotifier.setSplitLayout(tab.id, SplitLayoutType.horizontal);
        break;
      case 'split_v':
        sessionNotifier.setSplitLayout(tab.id, SplitLayoutType.vertical);
        break;
      case 'split_2x2':
        sessionNotifier.setSplitLayout(tab.id, SplitLayoutType.grid2x2);
        break;
      case 'split_single':
        sessionNotifier.setSplitLayout(tab.id, SplitLayoutType.single);
        break;
      case 'rename':
        _showRenameDialog(context, tab, sessionNotifier);
        break;
      case 'color_tag':
        _showColorDialog(context, tab, sessionNotifier);
        break;
      case 'toggle_pin':
        sessionNotifier.togglePinTab(tab.id);
        break;
      case 'close':
        sessionNotifier.closeTab(tab.id);
        break;
      case 'close_others':
        sessionNotifier.closeOtherTabs(tab.id);
        break;
      case 'close_right':
        sessionNotifier.closeTabsToTheRight(tab.id);
        break;
      case 'close_disconnected':
        sessionNotifier.closeDisconnectedTabs();
        break;
    }
  }

  static PopupMenuItem<String> _buildItem({
    required String value,
    required IconData icon,
    required String title,
    String? shortcut,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 34,
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isDestructive
                ? ShellitColors.statusRed
                : ShellitColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive
                    ? ShellitColors.statusRed
                    : ShellitColors.textPrimary,
              ),
            ),
          ),
          if (shortcut != null) ...[
            const SizedBox(width: 8),
            Text(
              shortcut,
              style: const TextStyle(
                fontSize: 11,
                color: ShellitColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showRenameDialog(
    BuildContext context,
    SessionTab tab,
    SessionManagerNotifier notifier,
  ) {
    final controller = TextEditingController(text: tab.displayTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ShellitColors.border, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.drive_file_rename_outline,
                size: 20, color: ShellitColors.accentBlue),
            const SizedBox(width: 8),
            Text(
              context.tr(
                'tabs.rename_dialog_title',
                defaultText: 'Rename Tab',
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.tr(
              'tabs.rename_dialog_hint',
              defaultText: 'Enter custom tab name (e.g. Docker Logs)',
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () => controller.clear(),
            ),
          ),
          onSubmitted: (val) {
            notifier.renameTab(tab.id, val);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.renameTab(tab.id, null); // Reset
              Navigator.of(ctx).pop();
            },
            child: Text(
              context.tr(
                'tabs.rename_dialog_reset',
                defaultText: 'Reset to Default',
              ),
              style: const TextStyle(color: ShellitColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.renameTab(tab.id, controller.text);
              Navigator.of(ctx).pop();
            },
            child: Text(context.tr('common.save', defaultText: 'Save')),
          ),
        ],
      ),
    );
  }

  static void _showColorDialog(
    BuildContext context,
    SessionTab tab,
    SessionManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: ShellitColors.border, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.palette_outlined,
                size: 20, color: ShellitColors.accentBlue),
            const SizedBox(width: 8),
            Text(
              context.tr(
                'tabs.color_dialog_title',
                defaultText: 'Set Tab Color Tag',
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in tagColors)
              InkWell(
                onTap: () {
                  notifier.setTabColor(tab.id, c);
                  Navigator.of(ctx).pop();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          tab.colorTag == c ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            InkWell(
              onTap: () {
                notifier.setTabColor(tab.id, null);
                Navigator.of(ctx).pop();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ShellitColors.obsidianBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: ShellitColors.border),
                ),
                child: const Icon(Icons.block, size: 16, color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('common.close', defaultText: 'Close')),
          ),
        ],
      ),
    );
  }
}
