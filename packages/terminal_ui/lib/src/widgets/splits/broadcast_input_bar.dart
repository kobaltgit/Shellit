import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';

class BroadcastInputBar extends StatelessWidget {
  final bool isBroadcastEnabled;
  final ValueChanged<bool> onBroadcastChanged;
  final SplitLayoutType currentLayout;
  final ValueChanged<SplitLayoutType> onLayoutChanged;

  const BroadcastInputBar({
    super.key,
    required this.isBroadcastEnabled,
    required this.onBroadcastChanged,
    required this.currentLayout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianHeader,
        border:
            Border(bottom: BorderSide(color: ShellitColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Split layout buttons
            _buildLayoutButton(
              type: SplitLayoutType.single,
              icon: Icons.crop_square,
              tooltip: context.tr('splits.single',
                  defaultText: 'Single Terminal'),
            ),
            const SizedBox(width: 4),
            _buildLayoutButton(
              type: SplitLayoutType.horizontal,
              icon: Icons.view_column_outlined,
              tooltip: context.tr('splits.horizontal_tooltip',
                  defaultText: 'Split Horizontal (Side by side)'),
            ),
            const SizedBox(width: 4),
            _buildLayoutButton(
              type: SplitLayoutType.vertical,
              icon: Icons.table_rows_outlined,
              tooltip: context.tr('splits.vertical_tooltip',
                  defaultText: 'Split Vertical (Top & bottom)'),
            ),
            const SizedBox(width: 4),
            _buildLayoutButton(
              type: SplitLayoutType.grid2x2,
              icon: Icons.grid_view_sharp,
              tooltip: context.tr('splits.matrix_tooltip',
                  defaultText: '2x2 Matrix Split'),
            ),

            const SizedBox(width: 14),
            const VerticalDivider(width: 1),
            const SizedBox(width: 14),

            // Broadcast Mode Switch
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cell_tower,
                  size: 16,
                  color: isBroadcastEnabled
                      ? ShellitColors.statusRed
                      : ShellitColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('splits.broadcast_title',
                      defaultText: 'Broadcast Input'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isBroadcastEnabled
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isBroadcastEnabled
                        ? ShellitColors.statusRed
                        : ShellitColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: isBroadcastEnabled,
                  activeThumbColor: ShellitColors.statusRed,
                  onChanged: onBroadcastChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),

            if (isBroadcastEnabled) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ShellitColors.envProdBg,
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: ShellitColors.statusRed, width: 0.8),
                ),
                child: Text(
                  context.tr('splits.broadcast_warning',
                      defaultText: 'INPUT SENT TO ALL PANES'),
                  style: const TextStyle(
                    color: ShellitColors.statusRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 20),

            Text(
              context.tr('splits.nav_hint',
                  defaultText: 'Alt + Arrows to navigate splits'),
              style: const TextStyle(fontSize: 11, color: ShellitColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutButton({
    required SplitLayoutType type,
    required IconData icon,
    required String tooltip,
  }) {
    final isActive = currentLayout == type;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onLayoutChanged(type),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isActive
                ? ShellitColors.accentBlue.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isActive
                ? Border.all(color: ShellitColors.accentBlue, width: 1)
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive
                ? ShellitColors.accentBlue
                : ShellitColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
