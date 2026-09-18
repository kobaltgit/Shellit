import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// Helper to detect destructive and dangerous commands before execution on servers.
class DangerousCommandChecker {
  DangerousCommandChecker._();

  static final List<RegExp> _dangerousPatterns = [
    RegExp(
        r'\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)\b',
        caseSensitive: false),
    RegExp(
        r'\brm\s+.*(-[a-zA-Z]*r[a-zA-Z]*\s+-[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*\s+-[a-zA-Z]*r[a-zA-Z]*)',
        caseSensitive: false),
    RegExp(r'\brm\s+.*--recursive', caseSensitive: false),
    RegExp(r'\breboot\b', caseSensitive: false),
    RegExp(r'\bshutdown\b', caseSensitive: false),
    RegExp(r'\binit\s+0\b', caseSensitive: false),
    RegExp(r'\binit\s+6\b', caseSensitive: false),
    RegExp(r'\bmkfs(\.[a-z0-9]+)?\b', caseSensitive: false),
    RegExp(r'\bdd\s+.*of=/dev/', caseSensitive: false),
    RegExp(r'\bdrop\s+(database|table)\b', caseSensitive: false),
    RegExp(r':\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:', caseSensitive: false),
    RegExp(r'>\s*/dev/sd[a-z]', caseSensitive: false),
  ];

  /// Returns true if the command matches any dangerous pattern.
  static bool isDangerous(String command) {
    final trimmed = command.trim();
    return _dangerousPatterns.any((pattern) => pattern.hasMatch(trimmed));
  }

  /// Returns description of the matched dangerous pattern or null.
  static String? detectPatternDescription(String command) {
    final trimmed = command.trim();
    for (final pattern in _dangerousPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return 'Potentially destructive command detected: "$trimmed"';
      }
    }
    return null;
  }
}

/// Modal confirmation dialog shown when a destructive command is intercepted on PROD.
class ProdConfirmationDialog extends StatelessWidget {
  final String command;
  final String hostLabel;

  const ProdConfirmationDialog({
    super.key,
    required this.command,
    required this.hostLabel,
  });

  static Future<bool> confirmDangerousCommand({
    required BuildContext context,
    required String command,
    required String hostLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProdConfirmationDialog(
        command: command,
        hostLabel: hostLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final warningIntro = context.tr('prod_guard.warning_intro',
        defaultText:
            'You are about to execute a dangerous command on {host} (PRODUCTION):');
    final parts = warningIntro.split('{host}');

    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.statusRed, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: ShellitColors.statusRed, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('prod_guard.title',
                  defaultText: 'PROD GUARD: Destructive Command'),
              style: const TextStyle(
                color: ShellitColors.statusRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13, color: ShellitColors.textPrimary),
              children: [
                TextSpan(
                    text: parts.isNotEmpty
                        ? parts[0]
                        : 'You are about to execute a dangerous command on '),
                TextSpan(
                  text: hostLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ShellitColors.statusRed,
                  ),
                ),
                TextSpan(
                    text: parts.length > 1 ? parts[1] : ' (PRODUCTION):'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: ShellitColors.statusRed.withValues(alpha: 0.5)),
            ),
            child: Text(
              command,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                color: Color(0xFFFF6E6E),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('prod_guard.warning_desc',
                defaultText:
                    'This action may lead to data loss or service unavailability. Are you absolutely sure?'),
            style: const TextStyle(
                fontSize: 12, color: ShellitColors.textSecondary),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: ShellitColors.textPrimary,
            side: const BorderSide(color: ShellitColors.border),
          ),
          child: Text(context.tr('prod_guard.cancel_btn',
              defaultText: 'Cancel (Abort)')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ShellitColors.statusRed,
            foregroundColor: Colors.white,
          ),
          child: Text(context.tr('prod_guard.execute_btn',
              defaultText: 'Execute Anyway')),
        ),
      ],
    );
  }
}
