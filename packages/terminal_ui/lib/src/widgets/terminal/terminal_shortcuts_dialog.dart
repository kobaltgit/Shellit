import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

class TerminalShortcutsDialog extends StatelessWidget {
  const TerminalShortcutsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => const TerminalShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final cmdOrCtrl = isMac ? '⌘' : 'Ctrl';

    return Dialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ShellitColors.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.keyboard_outlined,
                      color: ShellitColors.accentCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terminal Keyboard Shortcuts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ShellitColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quick reference for clipboard, selection, font zoom, and navigation',
                          style: TextStyle(
                            fontSize: 12,
                            color: ShellitColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: ShellitColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ShellitColors.border),

            // Shortcuts Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.content_copy_rounded,
                      title: 'Clipboard & Text Selection',
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutRow(
                      label: 'Copy selected text',
                      keys: [
                        '$cmdOrCtrl + Shift + C',
                        '$cmdOrCtrl + C (with selection)',
                        if (!isMac) 'Ctrl + Insert',
                      ],
                      note: 'If no text is selected, $cmdOrCtrl + C sends interrupt (SIGINT)',
                    ),
                    _buildShortcutRow(
                      label: 'Paste from clipboard',
                      keys: [
                        '$cmdOrCtrl + Shift + V',
                        '$cmdOrCtrl + V',
                        if (!isMac) 'Shift + Insert',
                      ],
                    ),
                    _buildShortcutRow(
                      label: 'Select all text in terminal',
                      keys: ['$cmdOrCtrl + Shift + A'],
                    ),
                    _buildShortcutRow(
                      label: 'Clear selection',
                      keys: ['Esc', 'Left click'],
                    ),
                    _buildShortcutRow(
                      label: 'Mouse selection',
                      keys: ['Left drag (characters)', 'Double click (word)'],
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      icon: Icons.mouse_outlined,
                      title: 'Mouse & Context Menu',
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutRow(
                      label: 'Context menu (Copy / Paste / Clear)',
                      keys: ['Right click'],
                    ),
                    _buildShortcutRow(
                      label: 'Quick paste from clipboard',
                      keys: ['Middle click (wheel)'],
                      note: 'Classic X11/Linux terminal behavior',
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      icon: Icons.zoom_in_outlined,
                      title: 'Font Zoom',
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutRow(
                      label: 'Increase font size',
                      keys: ['$cmdOrCtrl + +', '$cmdOrCtrl + ='],
                    ),
                    _buildShortcutRow(
                      label: 'Decrease font size',
                      keys: ['$cmdOrCtrl + -'],
                    ),
                    _buildShortcutRow(
                      label: 'Reset default size (13pt)',
                      keys: ['$cmdOrCtrl + 0'],
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      icon: Icons.terminal_outlined,
                      title: 'Screen & Session Controls',
                    ),
                    const SizedBox(height: 8),
                    _buildShortcutRow(
                      label: 'Clear terminal buffer',
                      keys: ['$cmdOrCtrl + Shift + K'],
                    ),
                    _buildShortcutRow(
                      label: 'Interrupt running command (SIGINT)',
                      keys: ['$cmdOrCtrl + C'],
                      note: 'Only when no text is selected',
                    ),
                    _buildShortcutRow(
                      label: 'Command Palette & Quick Connect (Omni-Bar)',
                      keys: ['$cmdOrCtrl + K'],
                    ),
                    _buildShortcutRow(
                      label: 'Open this shortcuts sheet',
                      keys: ['F1', '⌨ toolbar icon'],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: ShellitColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShellitColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Got it', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ShellitColors.accentCyan),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ShellitColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutRow({
    required String label,
    required List<String> keys,
    String? note,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ShellitColors.obsidianSidebar.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ShellitColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ShellitColors.textPrimary,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: keys.map((key) => _buildKeyBadge(key)).toList(),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: ShellitColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBadge(String keyText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: ShellitColors.obsidianCardHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ShellitColors.borderLight),
      ),
      child: Text(
        keyText,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ShellitColors.accentCyan,
        ),
      ),
    );
  }
}
