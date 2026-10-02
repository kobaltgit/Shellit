import 'dart:math';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'shell_integration_controller.dart';

/// Overlay gutter placed along the terminal scrollbar to display visual markers
/// (success green, failure red, running cyan) for executed command blocks.
class ShellCommandMarkersOverlay extends StatelessWidget {
  final ShellIntegrationController controller;
  final Terminal terminal;
  final ValueChanged<int> onScrollToLine;
  final bool checkScrollback;

  const ShellCommandMarkersOverlay({
    super.key,
    required this.controller,
    required this.terminal,
    required this.onScrollToLine,
    this.checkScrollback = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final blocks = controller.blocks;
        if (blocks.isEmpty) {
          return const SizedBox.shrink();
        }

        final aliveBlocks =
            blocks.where((b) => !b.isPendingPrompt && !b.isEvicted).toList();
        final evictedCount = blocks.where((b) => b.isEvicted).length;

        if (aliveBlocks.isEmpty && evictedCount == 0) {
          return const SizedBox.shrink();
        }

        // In active UI, only render scrollbar markers when terminal actually has scrollback history
        if (checkScrollback &&
            terminal.viewHeight > 0 &&
            terminal.buffer.lines.length <= terminal.viewHeight &&
            evictedCount == 0) {
          return const SizedBox.shrink();
        }

        final totalLines = max(1, terminal.buffer.lines.length);

        return LayoutBuilder(
          builder: (context, constraints) {
            final trackHeight = constraints.maxHeight;
            if (trackHeight <= 0) return const SizedBox.shrink();

            final topOffset = evictedCount > 0 ? 12.0 : 0.0;

            return SizedBox(
              width: 12,
              height: trackHeight,
              child: Stack(
                children: [
                  if (evictedCount > 0)
                    _buildEvictedCounter(context, evictedCount),
                  for (final block in aliveBlocks)
                    _buildMarker(
                      context,
                      block,
                      totalLines,
                      trackHeight,
                      topOffset: topOffset,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEvictedCounter(BuildContext context, int count) {
    return Positioned(
      top: 0,
      right: 1,
      child: Tooltip(
        message:
            '$count command(s) evicted from scrollback history (retaining last ${terminal.maxLines} lines)',
        waitDuration: const Duration(milliseconds: 150),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_drop_up,
              size: 10,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(
    BuildContext context,
    ShellCommandBlock block,
    int totalLines,
    double trackHeight, {
    double topOffset = 0.0,
  }) {
    if (block.isPendingPrompt || block.isEvicted) {
      return const SizedBox.shrink();
    }

    final ratio = (block.promptLine / totalLines).clamp(0.0, 1.0);
    final availableHeight = max(1.0, trackHeight - 10 - topOffset);
    final top = (topOffset + ratio * availableHeight)
        .clamp(topOffset, trackHeight - 10);

    Color color;
    String tooltipMsg;

    final durationStr = block.formatDuration();
    final durationSuffix = durationStr.isNotEmpty ? ' [$durationStr]' : '';

    if (block.isRunning) {
      color = const Color(0xFF00E5FF); // Bright Cyan
      tooltipMsg = 'Command #${block.id}: Running...';
    } else if (block.isSuccess) {
      color = const Color(0xFF00E676); // Bright Emerald Green
      tooltipMsg = 'Command #${block.id}: Success (exit 0)$durationSuffix';
    } else {
      color = const Color(0xFFFF1744); // Bright Coral Red
      tooltipMsg =
          'Command #${block.id}: Failed (exit ${block.exitCode})$durationSuffix';
    }

    return Positioned(
      top: top,
      right: 1,
      child: Tooltip(
        message: tooltipMsg,
        waitDuration: const Duration(milliseconds: 150),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onScrollToLine(block.promptLine),
          child: Container(
            width: 10,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
