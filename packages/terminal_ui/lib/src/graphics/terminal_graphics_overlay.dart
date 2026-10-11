import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:xterm/src/ui/render.dart';
import 'terminal_graphics_registry.dart';

/// Overlay widget that renders in-terminal graphics (Kitty Graphics Protocol)
/// aligned precisely with the terminal grid cells.
class TerminalGraphicsOverlay extends StatelessWidget {
  final TerminalGraphicsRegistry registry;
  final ScrollController scrollController;
  final RenderTerminal? Function()? getRenderTerminal;
  final Size defaultCellSize;
  final double leftPadding;
  final double topPadding;

  const TerminalGraphicsOverlay({
    super.key,
    required this.registry,
    required this.scrollController,
    this.getRenderTerminal,
    this.defaultCellSize = const Size(8.4, 18.2),
    this.leftPadding = 22.0,
    this.topPadding = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([registry, scrollController]),
      builder: (context, _) {
        if (registry.placements.isEmpty) {
          return const SizedBox.shrink();
        }

        final render = getRenderTerminal?.call();
        final cellSize = (render != null && render.hasSize)
            ? render.cellSize
            : defaultCellSize;

        final scrollOffset =
            scrollController.hasClients ? scrollController.offset : 0.0;

        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _TerminalGraphicsPainter(
              placements: registry.placements,
              cellSize: cellSize,
              scrollOffset: scrollOffset,
              leftPadding: leftPadding,
              topPadding: topPadding,
            ),
          ),
        );
      },
    );
  }
}

class _TerminalGraphicsPainter extends CustomPainter {
  final List<TerminalImagePlacement> placements;
  final Size cellSize;
  final double scrollOffset;
  final double leftPadding;
  final double topPadding;

  _TerminalGraphicsPainter({
    required this.placements,
    required this.cellSize,
    required this.scrollOffset,
    required this.leftPadding,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.medium;

    for (final placement in placements) {
      final x = leftPadding + (placement.column * cellSize.width);
      final y = topPadding + (placement.row * cellSize.height) - scrollOffset;
      final w = placement.widthCells * cellSize.width;
      final h = placement.heightCells * cellSize.height;

      // Skip offscreen images
      if (y + h < 0 || y > size.height || x + w < 0 || x > size.width) {
        continue;
      }

      final srcRect = Rect.fromLTWH(
        0,
        0,
        placement.image.width.toDouble(),
        placement.image.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(x, y, w, h);

      canvas.drawImageRect(placement.image, srcRect, dstRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TerminalGraphicsPainter oldDelegate) {
    return oldDelegate.placements != placements ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
