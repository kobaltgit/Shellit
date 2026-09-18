import 'dart:convert';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';
import '../app_shell/tab_drag_payload.dart';
import '../terminal/terminal_screen.dart';
import 'broadcast_input_bar.dart';
import 'host_slot_picker_dialog.dart';

class SplitMatrixView extends StatefulWidget {
  final List<ITerminalSession> sessions;
  final HostEntity? host;
  final List<HostEntity>? hosts;
  final SplitLayoutType initialLayout;
  final ValueChanged<SplitLayoutType>? onLayoutChanged;
  final ValueChanged<TabDragPayload>? onDropTab;
  final ValueChanged<int>? onUndockPane;
  final ValueChanged<int>? onClosePane;
  final VoidCallback? onSelectHostForSlot;
  final void Function(int slotIndex, HostEntity host)? onConnectHostToSlot;

  const SplitMatrixView({
    super.key,
    required this.sessions,
    this.host,
    this.hosts,
    this.initialLayout = SplitLayoutType.single,
    this.onLayoutChanged,
    this.onDropTab,
    this.onUndockPane,
    this.onClosePane,
    this.onSelectHostForSlot,
    this.onConnectHostToSlot,
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
  void didUpdateWidget(covariant SplitMatrixView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLayout != oldWidget.initialLayout) {
      setState(() {
        _layout = widget.initialLayout;
        if (_focusedIndex >= _getPaneCount()) {
          _focusedIndex = 0;
        }
      });
    }
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
              widget.onLayoutChanged?.call(val);
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
    if (index >= widget.sessions.length) {
      return _buildEmptyPane(index);
    }

    final session = widget.sessions[index];
    final isFocused = _focusedIndex == index;

    HostEntity? paneHost;
    if (widget.hosts != null) {
      for (final h in widget.hosts!) {
        if (h.id == session.hostId) {
          paneHost = h;
          break;
        }
      }
    }
    paneHost ??= widget.host;

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
        child: Stack(
          children: [
            Positioned.fill(
              child: TerminalScreen(
                key: ValueKey('terminal-pane-$index-${session.id}'),
                session: session,
                host: paneHost,
                autoFocus: isFocused,
                onBroadcastOutput: (data) => _handleBroadcast(data, index),
              ),
            ),
            // Pane header actions: Undock & Close
            Positioned(
              top: 8,
              right: 180, // Safe distance from SFTP & REC buttons
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onUndockPane != null)
                      Tooltip(
                        message: 'Extract / Undock to standalone tab',
                        child: InkWell(
                          onTap: () => widget.onUndockPane!(index),
                          borderRadius: BorderRadius.circular(3),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Icon(Icons.open_in_new,
                                size: 13, color: Colors.white70),
                          ),
                        ),
                      ),
                    if (widget.onClosePane != null) ...[
                      const SizedBox(width: 2),
                      Tooltip(
                        message: 'Close this pane',
                        child: InkWell(
                          onTap: () => widget.onClosePane!(index),
                          borderRadius: BorderRadius.circular(3),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Icon(Icons.close,
                                size: 13, color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHostPickerForSlot(int index) {
    if (widget.onConnectHostToSlot != null) {
      HostSlotPickerDialog.show(
        context,
        hosts: widget.hosts ?? const [],
        slotIndex: index,
        onSelected: (selectedHost) {
          widget.onConnectHostToSlot?.call(index, selectedHost);
        },
      );
    } else if (widget.onSelectHostForSlot != null) {
      widget.onSelectHostForSlot!();
    }
  }

  Widget _buildEmptyPane(int index) {
    return DragTarget<TabDragPayload>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        widget.onDropTab?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovering
                ? ShellitColors.accentBlue.withValues(alpha: 0.15)
                : ShellitColors.obsidianBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHovering
                  ? ShellitColors.accentBlue
                  : ShellitColors.border.withValues(alpha: 0.8),
              width: isHovering ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isHovering
                      ? Icons.file_download
                      : Icons.add_to_photos_outlined,
                  size: 42,
                  color: isHovering
                      ? ShellitColors.accentBlue
                      : ShellitColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  isHovering ? 'Drop Tab Here' : 'Empty Split Slot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isHovering
                        ? ShellitColors.accentBlue
                        : ShellitColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Drag an open tab here or select a host',
                  style: TextStyle(
                    fontSize: 11,
                    color: ShellitColors.textMuted,
                  ),
                ),
                if (widget.onConnectHostToSlot != null ||
                    widget.onSelectHostForSlot != null) ...[
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _openHostPickerForSlot(index),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Connect Host to this Pane',
                        style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ShellitColors.obsidianCard,
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                          color: ShellitColors.border, width: 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
