import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import 'terminal_link_detector.dart';

class TerminalContextMenu {
  const TerminalContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required bool hasSelection,
    String? selectedText,
    TerminalLinkMatch? detectedLink,
    VoidCallback? onOpenLink,
    VoidCallback? onCopyLink,
    required VoidCallback onCopy,
    required VoidCallback onPaste,
    required VoidCallback onSelectAll,
    required VoidCallback onClear,
    required VoidCallback onShowShortcuts,
  }) async {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final cmdOrCtrl = isMac ? '⌘' : 'Ctrl';

    final items = <PopupMenuEntry<String>>[];

    // 1. Link / File Path actions if detected at click position
    if (detectedLink != null) {
      final isUrl = detectedLink.isUrl;
      final rawTarget = detectedLink.text;
      final shortTarget = rawTarget.length > 28
          ? '${rawTarget.substring(0, 25)}...'
          : rawTarget;

      items.add(
        PopupMenuItem<String>(
          value: 'openLink',
          enabled: true,
          height: 38,
          child: _buildMenuItem(
            icon: isUrl
                ? Icons.open_in_new_rounded
                : Icons.file_open_outlined,
            title: isUrl
                ? context
                    .tr('terminal.context_menu_open_url',
                        defaultText: 'Open URL: {url}')
                    .replaceAll('{url}', shortTarget)
                : context
                    .tr('terminal.context_menu_open_file',
                        defaultText: 'Open File: {path}')
                    .replaceAll('{path}', shortTarget),
            shortcut: '$cmdOrCtrl+Click',
            enabled: true,
            highlightAccent: true,
          ),
        ),
      );

      items.add(
        PopupMenuItem<String>(
          value: 'copyLink',
          enabled: true,
          height: 38,
          child: _buildMenuItem(
            icon: Icons.link_rounded,
            title: isUrl
                ? context.tr('terminal.context_menu_copy_url',
                    defaultText: 'Copy Link Address')
                : context.tr('terminal.context_menu_copy_path',
                    defaultText: 'Copy File Path'),
            shortcut: '',
            enabled: true,
          ),
        ),
      );

      items.add(const PopupMenuDivider(height: 8));
    }

    // 2. Standard Clipboard & Buffer actions
    items.addAll([
      PopupMenuItem<String>(
        value: 'copy',
        enabled: hasSelection,
        height: 38,
        child: _buildMenuItem(
          icon: Icons.content_copy_rounded,
          title: hasSelection &&
                  selectedText != null &&
                  selectedText.trim().isNotEmpty
              ? context
                  .tr('terminal.context_menu_copy_count',
                      defaultText: 'Copy ({count})')
                  .replaceAll(
                      '{count}', selectedText.trim().length.toString())
              : context.tr('terminal.context_menu_copy', defaultText: 'Copy'),
          shortcut: '$cmdOrCtrl+Shift+C',
          enabled: hasSelection,
        ),
      ),
      PopupMenuItem<String>(
        value: 'paste',
        enabled: true,
        height: 38,
        child: _buildMenuItem(
          icon: Icons.paste_rounded,
          title: context.tr('terminal.context_menu_paste', defaultText: 'Paste'),
          shortcut: '$cmdOrCtrl+Shift+V',
          enabled: true,
        ),
      ),
      PopupMenuItem<String>(
        value: 'selectAll',
        enabled: true,
        height: 38,
        child: _buildMenuItem(
          icon: Icons.select_all_rounded,
          title: context.tr('terminal.context_menu_select_all',
              defaultText: 'Select All'),
          shortcut: '$cmdOrCtrl+Shift+A',
          enabled: true,
        ),
      ),
      const PopupMenuDivider(height: 8),
      PopupMenuItem<String>(
        value: 'clear',
        enabled: true,
        height: 38,
        child: _buildMenuItem(
          icon: Icons.cleaning_services_outlined,
          title: context.tr('terminal.context_menu_clear_buffer',
              defaultText: 'Clear Buffer'),
          shortcut: '$cmdOrCtrl+Shift+K',
          enabled: true,
        ),
      ),
      PopupMenuItem<String>(
        value: 'shortcuts',
        enabled: true,
        height: 38,
        child: _buildMenuItem(
          icon: Icons.keyboard_outlined,
          title: context.tr('terminal.context_menu_shortcuts',
              defaultText: 'Keyboard Shortcuts...'),
          shortcut: 'F1',
          enabled: true,
        ),
      ),
    ]);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      color: ShellitColors.obsidianCard,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      items: items,
    );

    if (result == null) return;

    switch (result) {
      case 'openLink':
        onOpenLink?.call();
        break;
      case 'copyLink':
        onCopyLink?.call();
        break;
      case 'copy':
        onCopy();
        break;
      case 'paste':
        onPaste();
        break;
      case 'selectAll':
        onSelectAll();
        break;
      case 'clear':
        onClear();
        break;
      case 'shortcuts':
        onShowShortcuts();
        break;
    }
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String shortcut,
    required bool enabled,
    bool highlightAccent = false,
  }) {
    final color = enabled
        ? (highlightAccent ? ShellitColors.accentCyan : ShellitColors.textPrimary)
        : ShellitColors.textMuted;
    final shortcutColor =
        enabled ? ShellitColors.accentCyan : ShellitColors.textMuted;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: highlightAccent ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (shortcut.isNotEmpty) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: enabled ? ShellitColors.obsidianSidebar : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: enabled ? ShellitColors.borderLight : Colors.transparent,
              ),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: shortcutColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
