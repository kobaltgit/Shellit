import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/shellit_theme.dart';

class MobileAccessoryBar extends StatefulWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback? onPaste;
  final VoidCallback? onHideKeyboard;

  const MobileAccessoryBar({
    super.key,
    required this.onKeyPress,
    this.onPaste,
    this.onHideKeyboard,
  });

  @override
  State<MobileAccessoryBar> createState() => _MobileAccessoryBarState();
}

class _MobileAccessoryBarState extends State<MobileAccessoryBar> {
  bool _ctrlActive = false;
  bool _altActive = false;

  void _handleKey(String keyLabel, String keySequence) {
    HapticFeedback.lightImpact();

    if (keyLabel == 'Ctrl') {
      setState(() => _ctrlActive = !_ctrlActive);
      return;
    }
    if (keyLabel == 'Alt') {
      setState(() => _altActive = !_altActive);
      return;
    }

    String sequence = keySequence;
    if (_ctrlActive) {
      if (keySequence.length == 1) {
        final code = keySequence.codeUnitAt(0);
        if (code >= 97 && code <= 122) {
          // a-z -> 1-26
          sequence = String.fromCharCode(code - 96);
        } else if (code >= 65 && code <= 90) {
          // A-Z -> 1-26
          sequence = String.fromCharCode(code - 64);
        }
      }
      setState(() => _ctrlActive = false);
    } else if (_altActive) {
      sequence = '\x1b$sequence';
      setState(() => _altActive = false);
    }

    widget.onKeyPress(sequence);
  }

  Future<void> _handlePaste() async {
    HapticFeedback.lightImpact();
    if (widget.onPaste != null) {
      widget.onPaste!();
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.onKeyPress(data.text!);
    }
  }

  void _handleHideKeyboard() {
    HapticFeedback.lightImpact();
    if (widget.onHideKeyboard != null) {
      widget.onHideKeyboard!();
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ('ESC', '\x1b'),
      ('TAB', '\t'),
      ('Ctrl', ''),
      ('Alt', ''),
      ('|', '|'),
      ('/', '/'),
      ('-', '-'),
      ('~', '~'),
      ('↑', '\x1b[A'),
      ('↓', '\x1b[B'),
      ('←', '\x1b[D'),
      ('→', '\x1b[C'),
    ];

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianSidebar,
        border: Border(top: BorderSide(color: ShellitColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              itemCount: keys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final (label, seq) = keys[index];
                final isModifier = label == 'Ctrl' || label == 'Alt';
                final isActive = (label == 'Ctrl' && _ctrlActive) ||
                    (label == 'Alt' && _altActive);

                return Material(
                  color: isActive
                      ? ShellitColors.accentBlue
                      : ShellitColors.obsidianCard,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _handleKey(label, seq),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isActive
                              ? ShellitColors.accentBlue
                              : ShellitColors.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight:
                              isModifier ? FontWeight.bold : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isModifier
                                  ? ShellitColors.accentCyan
                                  : ShellitColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: ShellitColors.border,
          ),
          // Fast actions: PASTE and HIDE keyboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: ShellitColors.obsidianCard,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _handlePaste,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ShellitColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_paste,
                              size: 14, color: ShellitColors.accentCyan),
                          SizedBox(width: 4),
                          Text(
                            'PASTE',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ShellitColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Hide Keyboard',
                  child: Material(
                    color: ShellitColors.obsidianCard,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _handleHideKeyboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: ShellitColors.border),
                        ),
                        child: const Icon(
                          Icons.keyboard_hide_outlined,
                          size: 16,
                          color: ShellitColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
