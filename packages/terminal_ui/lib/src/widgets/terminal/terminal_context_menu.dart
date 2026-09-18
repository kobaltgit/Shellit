import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

class TerminalContextMenu {
  const TerminalContextMenu._();

  static Future<void> show({
    required BuildContext context,
    required Offset globalPosition,
    required bool hasSelection,
    String? selectedText,
    required VoidCallback onCopy,
    required VoidCallback onPaste,
    required VoidCallback onSelectAll,
    required VoidCallback onClear,
    required VoidCallback onShowShortcuts,
  }) async {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final cmdOrCtrl = isMac ? '⌘' : 'Ctrl';

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
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          enabled: hasSelection,
          height: 38,
          child: _buildMenuItem(
            icon: Icons.content_copy_rounded,
            title: hasSelection && selectedText != null && selectedText.trim().isNotEmpty
                ? 'Copy (${selectedText.trim().length})'
                : 'Copy',
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
            title: 'Paste',
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
            title: 'Select All',
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
            title: 'Clear Buffer',
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
            title: 'Keyboard Shortcuts...',
            shortcut: 'F1',
            enabled: true,
          ),
        ),
      ],
    );

    if (result == null) return;

    switch (result) {
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
  }) {
    final color = enabled ? ShellitColors.textPrimary : ShellitColors.textMuted;
    final shortcutColor = enabled ? ShellitColors.accentCyan : ShellitColors.textMuted;

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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: enabled
                ? ShellitColors.obsidianSidebar
                : Colors.transparent,
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
    );
  }
}
