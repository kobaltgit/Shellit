import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/shellit_theme.dart';

class MobileAccessoryBar extends StatefulWidget {
  final ValueChanged<String> onKeyPress;

  const MobileAccessoryBar({
    super.key,
    required this.onKeyPress,
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
                    fontWeight: isModifier ? FontWeight.bold : FontWeight.w500,
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
    );
  }
}
