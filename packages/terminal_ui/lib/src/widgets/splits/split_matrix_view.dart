import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';
import '../terminal/terminal_screen.dart';
import 'broadcast_input_bar.dart';

class SplitMatrixView extends StatefulWidget {
  final List<ITerminalSession> sessions;
  final HostEntity? host;
  final SplitLayoutType initialLayout;

  const SplitMatrixView({
    super.key,
    required this.sessions,
    this.host,
    this.initialLayout = SplitLayoutType.single,
  });

  @override
  State<SplitMatrixView> createState() => _SplitMatrixViewState();
}

class _SplitMatrixViewState extends State<SplitMatrixView> {
  late SplitLayoutType _layout;
  bool _isBroadcastEnabled = false;
  int _focusedIndex = 0;
  final FocusNode _focusNode =
      FocusNode(canRequestFocus: false, skipTraversal: true);

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleBroadcast(String data, int senderIndex) {
    if (!_isBroadcastEnabled) return;

    final bytes = Uint8List.fromList(utf8.encode(data));
    for (int i = 0; i < widget.sessions.length; i++) {
      if (i != senderIndex) {
        widget.sessions[i].inputStream.add(bytes);
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final isAlt = HardwareKeyboard.instance.isAltPressed;
    if (!isAlt) return;

    final count = _getPaneCount();
    if (count <= 1) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() => _focusedIndex = (_focusedIndex + 1) % count);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _focusedIndex = (_focusedIndex - 1 + count) % count);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_layout == SplitLayoutType.grid2x2) {
        setState(() => _focusedIndex = (_focusedIndex + 2) % count);
      } else if (_layout == SplitLayoutType.vertical) {
        setState(() => _focusedIndex = (_focusedIndex + 1) % count);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_layout == SplitLayoutType.grid2x2) {
        setState(() => _focusedIndex = (_focusedIndex - 2 + count) % count);
      } else if (_layout == SplitLayoutType.vertical) {
        setState(() => _focusedIndex = (_focusedIndex - 1 + count) % count);
      }
    }
  }

  int _getPaneCount() {
    switch (_layout) {
      case SplitLayoutType.single:
        return 1;
      case SplitLayoutType.horizontal:
      case SplitLayoutType.vertical:
        return 2.clamp(1, widget.sessions.length);
      case SplitLayoutType.grid2x2:
        return 4.clamp(1, widget.sessions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          BroadcastInputBar(
            isBroadcastEnabled: _isBroadcastEnabled,
            onBroadcastChanged: (val) =>
                setState(() => _isBroadcastEnabled = val),
            currentLayout: _layout,
            onLayoutChanged: (val) {
              setState(() {
                _layout = val;
                if (_focusedIndex >= _getPaneCount()) {
                  _focusedIndex = 0;
                }
              });
            },
          ),
          Expanded(
            child: _buildLayoutPanes(),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPanes() {
    if (widget.sessions.isEmpty) {
      return const Center(child: Text('No active terminal sessions'));
    }

    switch (_layout) {
      case SplitLayoutType.single:
        return _buildTerminalPane(0);

      case SplitLayoutType.horizontal:
        return Row(
          children: [
            Expanded(child: _buildTerminalPane(0)),
            const VerticalDivider(width: 2, color: ShellitColors.border),
            Expanded(child: _buildTerminalPane(1)),
          ],
        );

      case SplitLayoutType.vertical:
        return Column(
          children: [
            Expanded(child: _buildTerminalPane(0)),
            const Divider(height: 2, color: ShellitColors.border),
            Expanded(child: _buildTerminalPane(1)),
          ],
        );

      case SplitLayoutType.grid2x2:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTerminalPane(0)),
                  const VerticalDivider(width: 2, color: ShellitColors.border),
                  Expanded(child: _buildTerminalPane(1)),
                ],
              ),
            ),
            const Divider(height: 2, color: ShellitColors.border),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTerminalPane(2)),
                  const VerticalDivider(width: 2, color: ShellitColors.border),
                  Expanded(child: _buildTerminalPane(3)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTerminalPane(int index) {
    final session = index < widget.sessions.length
        ? widget.sessions[index]
        : widget.sessions.first;
    final isFocused = _focusedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_focusedIndex != index) {
          setState(() => _focusedIndex = index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? ShellitColors.accentBlue : ShellitColors.border,
            width: isFocused ? 2 : 0.5,
          ),
        ),
        child: TerminalScreen(
          key: ValueKey('terminal-pane-$index-${session.id}'),
          session: session,
          host: widget.host,
          autoFocus: isFocused,
          onBroadcastOutput: (data) => _handleBroadcast(data, index),
        ),
      ),
    );
  }
}
