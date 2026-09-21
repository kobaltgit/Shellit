import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

/// Platform-agnostic desktop window buttons (Minimize, Maximize/Restore, Close).
/// Renders standard sleek controls matching Obsidian Dark theme.
/// If all callbacks are null, returns [SizedBox.shrink] for mobile/web hygiene.
class WindowControls extends StatefulWidget {
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;
  final bool isMaximized;

  const WindowControls({
    super.key,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
    this.isMaximized = false,
  });

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _hoverMinimize = false;
  bool _hoverMaximize = false;
  bool _hoverClose = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onMinimize == null &&
        widget.onMaximize == null &&
        widget.onClose == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Minimize Button
        if (widget.onMinimize != null)
          MouseRegion(
            onEnter: (_) => setState(() => _hoverMinimize = true),
            onExit: (_) => setState(() => _hoverMinimize = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onMinimize,
              child: Container(
                width: 44,
                color: _hoverMinimize
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    width: 10,
                    height: 1.5,
                    color: ShellitColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

        // Maximize / Restore Button
        if (widget.onMaximize != null)
          MouseRegion(
            onEnter: (_) => setState(() => _hoverMaximize = true),
            onExit: (_) => setState(() => _hoverMaximize = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onMaximize,
              child: Container(
                width: 44,
                color: _hoverMaximize
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Center(
                  child: widget.isMaximized
                      ? _buildRestoreIcon()
                      : _buildMaximizeIcon(),
                ),
              ),
            ),
          ),

        // Close Button
        if (widget.onClose != null)
          MouseRegion(
            onEnter: (_) => setState(() => _hoverClose = true),
            onExit: (_) => setState(() => _hoverClose = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(
                width: 46,
                color: _hoverClose ? const Color(0xFFE81123) : Colors.transparent,
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: _hoverClose
                        ? Colors.white
                        : ShellitColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMaximizeIcon() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(color: ShellitColors.textSecondary, width: 1.2),
      ),
    );
  }

  Widget _buildRestoreIcon() {
    return SizedBox(
      width: 11,
      height: 11,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: ShellitColors.textSecondary, width: 1.2),
                  right:
                      BorderSide(color: ShellitColors.textSecondary, width: 1.2),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ShellitColors.obsidianHeader,
                border:
                    Border.all(color: ShellitColors.textSecondary, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
