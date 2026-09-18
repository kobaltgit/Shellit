import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

/// Wraps a terminal widget with a perimeter red status border and optional warning badge
/// when connected to a production host.
class ProdGuardBorder extends StatelessWidget {
  final Widget child;
  final bool isProduction;
  final String? hostLabel;

  const ProdGuardBorder({
    super.key,
    required this.child,
    this.isProduction = false,
    this.hostLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProduction) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ShellitColors.statusRed,
          width: 2.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          // Top warning banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 22,
              color: ShellitColors.statusRed.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'PROD ENVIRONMENT${hostLabel != null ? ": $hostLabel" : ""} — DANGEROUS OPERATIONS GUARD ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
