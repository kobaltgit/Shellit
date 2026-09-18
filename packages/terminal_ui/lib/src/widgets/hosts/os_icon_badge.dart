import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'os_svg_icons.dart';

/// Renders an authentic, crisp SVG badge for a remote host's operating system.
class OsIconBadge extends StatelessWidget {
  final OsType os;
  final double size;
  final double padding;

  const OsIconBadge({
    super.key,
    required this.os,
    this.size = 28,
    this.padding = 6,
  });

  @override
  Widget build(BuildContext context) {
    final meta = OsMeta.forType(os);
    final totalSize = size + (padding * 2);

    return Tooltip(
      message: meta.label,
      child: Container(
        width: totalSize,
        height: totalSize,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: meta.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: meta.brandColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: meta.brandColor.withValues(alpha: 0.12),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(
          meta.svgContent,
          width: size,
          height: size,
        ),
      ),
    );
  }
}
