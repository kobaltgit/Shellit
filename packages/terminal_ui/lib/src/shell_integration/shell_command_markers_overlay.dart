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

        // In active UI, only render scrollbar markers when terminal actually has scrollback history
        if (checkScrollback &&
            terminal.viewHeight > 0 &&
            terminal.buffer.lines.length <= terminal.viewHeight) {
          return const SizedBox.shrink();
        }

        final totalLines = max(1, terminal.buffer.lines.length);

        return LayoutBuilder(
          builder: (context, constraints) {
            final trackHeight = constraints.maxHeight;
            if (trackHeight <= 0) return const SizedBox.shrink();

            return SizedBox(
              width: 12,
              height: trackHeight,
              child: Stack(
                children: [
                  for (final block in blocks)
                    _buildMarker(context, block, totalLines, trackHeight),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarker(
    BuildContext context,
    ShellCommandBlock block,
    int totalLines,
    double trackHeight,
  ) {
    if (block.isPendingPrompt) {
      return const SizedBox.shrink();
    }

    final ratio = (block.promptLine / totalLines).clamp(0.0, 1.0);
    final top = (ratio * (trackHeight - 10)).clamp(0.0, trackHeight - 10);

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
