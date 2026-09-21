import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

/// Item model for the right plugin activity rail.
class PluginActivityRailItem {
  final String id;
  final String label;
  final Widget icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const PluginActivityRailItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });
}

/// A vertical 40px activity rail docked to the right edge of the workspace.
/// Displays installed plugins without consuming horizontal space in TopBar.
class PluginActivityRail extends StatelessWidget {
  final List<PluginActivityRailItem> items;
  final VoidCallback? onOpenPluginsManager;

  const PluginActivityRail({
    super.key,
    required this.items,
    this.onOpenPluginsManager,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && onOpenPluginsManager == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 40,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianHeader,
        border: Border(
          left: BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          // List of plugin action buttons
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRailButton(item);
              },
            ),
          ),

          // Bottom shortcut to open Plugins Screen if provided
          if (onOpenPluginsManager != null) ...[
            const Divider(height: 1, color: ShellitColors.border),
            const SizedBox(height: 4),
            Tooltip(
              message: 'Plugins & Extensions',
              child: IconButton(
                icon: const Icon(
                  Icons.extension_outlined,
                  size: 18,
                  color: ShellitColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                onPressed: onOpenPluginsManager,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildRailButton(PluginActivityRailItem item) {
    return Tooltip(
      message: item.tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 40,
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: item.isSelected
                ? ShellitColors.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Left neon active indicator
              if (item.isSelected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: ShellitColors.accentBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              // Plugin icon
              IconTheme(
                data: IconThemeData(
                  size: 18,
                  color: item.isSelected
                      ? ShellitColors.accentBlue
                      : ShellitColors.textSecondary,
                ),
                child: item.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
