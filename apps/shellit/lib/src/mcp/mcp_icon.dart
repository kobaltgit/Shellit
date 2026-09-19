import 'package:flutter/material.dart';
import 'package:terminal_ui/terminal_ui.dart';

/// Stylish vector icon for MCP (Model Context Protocol) AI Gateway.
class McpVectorIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const McpVectorIcon({
    super.key,
    this.size = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? ShellitColors.accentCyan;

    return CustomPaint(
      size: Size(size, size),
      painter: _McpIconPainter(activeColor),
    );
  }
}

class _McpIconPainter extends CustomPainter {
  final Color color;

  _McpIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Central diamond / core
    final path = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.9, h * 0.5)
      ..lineTo(w * 0.5, h * 0.9)
      ..lineTo(w * 0.1, h * 0.5)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);

    // Connecting circuit spurs
    canvas.drawLine(Offset(0, h * 0.5), Offset(w * 0.1, h * 0.5), strokePaint);
    canvas.drawLine(Offset(w * 0.9, h * 0.5), Offset(w, h * 0.5), strokePaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.1), strokePaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.9), Offset(w * 0.5, h), strokePaint);

    // Center processor node
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.15, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _McpIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
