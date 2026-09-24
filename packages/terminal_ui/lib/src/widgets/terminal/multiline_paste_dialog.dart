import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';
import 'prod_confirmation_dialog.dart';

/// Modal dialog warning the user before pasting multiline text into the terminal.
/// Provides line preview, dangerous command detection, newline stripping,
/// and strict confirmation on PRODUCTION servers.
class MultilinePasteDialog extends StatefulWidget {
  final String text;
  final HostEntity? host;
  final bool isProduction;

  const MultilinePasteDialog({
    super.key,
    required this.text,
    this.host,
    this.isProduction = false,
  });

  /// Displays the dialog and returns the prepared text to paste, or null if cancelled.
  static Future<String?> show({
    required BuildContext context,
    required String text,
    HostEntity? host,
    bool? isProduction,
  }) {
    final effectiveIsProd = isProduction ?? (host?.isProduction ?? false);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MultilinePasteDialog(
        text: text,
        host: host,
        isProduction: effectiveIsProd,
      ),
    );
  }

  @override
  State<MultilinePasteDialog> createState() => _MultilinePasteDialogState();
}

class _MultilinePasteDialogState extends State<MultilinePasteDialog> {
  late bool _stripTrailingNewline;
  bool _prodConfirmed = false;
  late final List<String> _lines;

  @override
  void initState() {
    super.initState();
    // Default to true to prevent accidental auto-execution of last command
    _stripTrailingNewline = true;
    _lines = widget.text.split(RegExp(r'\r\n|\r|\n'));
  }

  String _prepareText() {
    var result = widget.text;
    if (_stripTrailingNewline) {
      while (result.endsWith('\n') || result.endsWith('\r')) {
        result = result.substring(0, result.length - 1);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isProd = widget.isProduction;
    final primaryColor =
        isProd ? ShellitColors.statusRed : ShellitColors.statusYellow;

    return AlertDialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isProd ? ShellitColors.statusRed : ShellitColors.border,
          width: isProd ? 1.5 : 1,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Icon(
            isProd ? Icons.warning_rounded : Icons.content_paste_go_outlined,
            color: primaryColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(
                'terminal.multiline_paste_title',
                defaultText: 'Multiline Paste Warning',
              ),
              style: TextStyle(
                color: isProd ? ShellitColors.statusRed : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              context.tr(
                'terminal.multiline_paste_lines_badge',
                params: {'count': _lines.length.toString()},
                defaultText: '${_lines.length} lines',
              ),
              style: TextStyle(
                color: primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isProd) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ShellitColors.statusRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ShellitColors.statusRed),
              ),
              child: const Text(
                'PROD',
                style: TextStyle(
                  color: ShellitColors.statusRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isProd) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: ShellitColors.statusRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: ShellitColors.statusRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: ShellitColors.statusRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr(
                            'terminal.multiline_paste_prod_banner',
                            defaultText:
                                'Pasting multiple commands to a PRODUCTION server will execute intermediate commands immediately.',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                context.tr(
                  'terminal.multiline_paste_preview_label',
                  defaultText: 'Content preview:',
                ),
                style: const TextStyle(
                  color: ShellitColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ShellitColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      final isDangerous =
                          isProd && DangerousCommandChecker.isDangerous(line);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        color: isDangerous
                            ? ShellitColors.statusRed.withValues(alpha: 0.18)
                            : (index.isOdd
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.transparent),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  color: isDangerous
                                      ? ShellitColors.statusRed
                                      : Colors.white30,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                line.isEmpty ? ' ' : line,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  color: isDangerous
                                      ? const Color(0xFFFF8A80)
                                      : Colors.white70,
                                ),
                              ),
                            ),
                            if (isDangerous)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: ShellitColors.statusRed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PROD GUARD',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option: Strip trailing newline
              InkWell(
                onTap: () {
                  setState(() {
                    _stripTrailingNewline = !_stripTrailingNewline;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _stripTrailingNewline,
                          activeColor: ShellitColors.accentCyan,
                          onChanged: (val) {
                            setState(() {
                              _stripTrailingNewline = val ?? true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr(
                            'terminal.multiline_paste_strip_newline',
                            defaultText:
                                'Strip trailing newline (avoids auto-executing the last line)',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // PROD confirmation checkbox
              if (isProd) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      _prodConfirmed = !_prodConfirmed;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: _prodConfirmed,
                            activeColor: ShellitColors.statusRed,
                            onChanged: (val) {
                              setState(() {
                                _prodConfirmed = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr(
                              'terminal.multiline_paste_confirm_prod',
                              defaultText:
                                  'I understand the risks and confirm execution on PRODUCTION',
                            ),
                            style: const TextStyle(
                              color: ShellitColors.statusRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            context.tr('common.cancel', defaultText: 'Cancel'),
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        ElevatedButton(
          onPressed: (isProd && !_prodConfirmed)
              ? null
              : () => Navigator.of(context).pop(_prepareText()),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isProd ? ShellitColors.statusRed : ShellitColors.accentCyan,
            foregroundColor: isProd ? Colors.white : Colors.black,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white30,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            context.tr(
              'terminal.multiline_paste_submit_btn',
              params: {'count': _lines.length.toString()},
              defaultText: 'Paste ${_lines.length} lines',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
