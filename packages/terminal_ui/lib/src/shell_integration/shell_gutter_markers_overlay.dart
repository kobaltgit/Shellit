import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
// ignore: implementation_imports
import 'package:xterm/src/ui/render.dart';
import 'shell_integration_controller.dart';

/// Overlay gutter placed along the left margin of the terminal view.
/// Renders crisp, glowing indicator dots aligned with command prompt lines
/// (inspired by VS Code, Warp, and JetBrains terminal integration).
class ShellGutterMarkersOverlay extends StatelessWidget {
  final ShellIntegrationController controller;
  final Terminal terminal;
  final ScrollController scrollController;
  final double lineHeight;
  final double topPadding;
  final RenderTerminal? Function()? getRenderTerminal;
  final void Function(ShellCommandBlock block)? onBlockTap;

  const ShellGutterMarkersOverlay({
    super.key,
    required this.controller,
    required this.terminal,
    required this.scrollController,
    required this.lineHeight,
    this.topPadding = 12.0,
    this.getRenderTerminal,
    this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, scrollController]),
      builder: (context, child) {
        final blocks = controller.blocks;
        if (blocks.isEmpty) {
          return const SizedBox.shrink();
        }

        final render = getRenderTerminal?.call();
        final effectiveLineHeight = (render != null && render.lineHeight > 0)
            ? render.lineHeight
            : lineHeight;
        if (effectiveLineHeight <= 0) return const SizedBox.shrink();

        final scrollOffset =
            scrollController.hasClients ? scrollController.offset : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            if (viewportHeight <= 0) return const SizedBox.shrink();

            final visibleBlocks = <Widget>[];

            for (final block in blocks) {
              if (block.isPendingPrompt) continue;

              double y;
              if (render != null && render.hasSize) {
                // Precise pixel coordinate calculated directly by xterm RenderTerminal
                y = render.getOffset(CellOffset(0, block.promptLine)).dy;
              } else {
                y = topPadding +
                    (block.promptLine * effectiveLineHeight) -
                    scrollOffset;
              }

              // Only render markers that are currently visible within the viewport
              if (y < -effectiveLineHeight || y > viewportHeight) continue;

              visibleBlocks.add(
                _GutterMarkerItem(
                  block: block,
                  top: y + (effectiveLineHeight - 10) / 2,
                  onTap: () => onBlockTap?.call(block),
                ),
              );
            }

            return SizedBox(
              width: 22,
              height: viewportHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: visibleBlocks,
              ),
            );
          },
        );
      },
    );
  }
}

class _GutterMarkerItem extends StatefulWidget {
  final ShellCommandBlock block;
  final double top;
  final VoidCallback onTap;

  const _GutterMarkerItem({
    required this.block,
    required this.top,
    required this.onTap,
  });

  @override
  State<_GutterMarkerItem> createState() => _GutterMarkerItemState();
}

class _GutterMarkerItemState extends State<_GutterMarkerItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final durationStr = block.formatDuration();
    final durationSuffix = durationStr.isNotEmpty ? ' [$durationStr]' : '';

    Color color;
    String statusText;

    if (block.isRunning) {
      color = const Color(0xFF00E5FF); // Bright Cyan
      statusText = 'Running...';
    } else if (block.isSuccess) {
      color = const Color(0xFF10B981); // Emerald Green
      statusText = 'Success (exit 0)$durationSuffix';
    } else {
      color = const Color(0xFFEF4444); // Coral Red
      statusText = 'Failed (exit ${block.exitCode})$durationSuffix';
    }

    final tooltipMsg =
        'Command #${block.id}: $statusText\nClick to copy output';

    return Positioned(
      top: widget.top,
      left: 6,
      child: Tooltip(
        message: tooltipMsg,
        waitDuration: const Duration(milliseconds: 150),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isHovered ? 12 : 9,
              height: _isHovered ? 12 : 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: _isHovered ? 0.9 : 0.6),
                    blurRadius: _isHovered ? 6 : 3,
                    spreadRadius: _isHovered ? 1 : 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
