import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

/// Wraps a terminal widget with a perimeter status border and warning banner
/// when connected to a production host or when Command Guard protection is active.
class ProdGuardBorder extends StatelessWidget {
  final Widget child;
  final bool isProduction;
  final bool hasProtection;
  final String? hostLabel;

  const ProdGuardBorder({
    super.key,
    required this.child,
    this.isProduction = false,
    this.hasProtection = false,
    this.hostLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (!isProduction && !hasProtection) {
      return child;
    }

    final isStrictProd = isProduction;
    final borderColor =
        isStrictProd ? ShellitColors.statusRed : ShellitColors.statusYellow;
    final bannerBg = isStrictProd
        ? ShellitColors.statusRed.withValues(alpha: 0.92)
        : const Color(0xFFD97706).withValues(alpha: 0.95);
    final iconData =
        isStrictProd ? Icons.warning_rounded : Icons.shield_outlined;

    final hostSuffix = hostLabel != null && hostLabel!.isNotEmpty
        ? ': $hostLabel'
        : '';
    final defaultBannerText = isStrictProd
        ? 'PROD ENVIRONMENT$hostSuffix — DANGEROUS OPERATIONS GUARD ACTIVE'
        : 'COMMAND GUARD ACTIVE$hostSuffix — DESTRUCTIVE COMMANDS INTERCEPTED';

    final bannerText = context.tr(
      isStrictProd ? 'prod_guard.banner_prod' : 'prod_guard.banner_guard',
      defaultText: defaultBannerText,
      params: {'host': hostSuffix},
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: isStrictProd ? 2.5 : 2.0,
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
              color: bannerBg,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      bannerText,
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
