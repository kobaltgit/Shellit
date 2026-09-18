import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';
import 'shellit_logo.dart';

enum SidebarSection {
  hosts,
  keychain,
  tunnels,
  snippets,
  logs,
  plugins,
  settings,
}

class NavigationSidebar extends StatelessWidget {
  final SidebarSection currentSection;
  final ValueChanged<SidebarSection> onSectionSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const NavigationSidebar({
    super.key,
    required this.currentSection,
    required this.onSectionSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed ? 64.0 : 210.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianSidebar,
        border: Border(
          right: BorderSide(color: ShellitColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // App Logo / Title
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ShellitColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const ShellitLogo(size: 32, borderRadius: 8),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Shellit',
                      style: TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  section: SidebarSection.hosts,
                  icon: Icons.dns_outlined,
                  activeIcon: Icons.dns,
                  label: 'Hosts',
                ),
                _buildNavItem(
                  section: SidebarSection.keychain,
                  icon: Icons.key_outlined,
                  activeIcon: Icons.key,
                  label: 'Keychain',
                ),
                _buildNavItem(
                  section: SidebarSection.tunnels,
                  icon: Icons.alt_route_outlined,
                  activeIcon: Icons.alt_route,
                  label: 'Port Forwarding',
                ),
                _buildNavItem(
                  section: SidebarSection.snippets,
                  icon: Icons.code_outlined,
                  activeIcon: Icons.code,
                  label: 'Snippets',
                ),
                _buildNavItem(
                  section: SidebarSection.logs,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Logs',
                ),
                _buildNavItem(
                  section: SidebarSection.plugins,
                  icon: Icons.extension_outlined,
                  activeIcon: Icons.extension,
                  label: 'Plugins',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings & Collapse button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                _buildNavItem(
                  section: SidebarSection.settings,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                ),
                if (onToggleCollapse != null)
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: ShellitColors.textSecondary,
                    ),
                    onPressed: onToggleCollapse,
                    tooltip:
                        isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required SidebarSection section,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentSection == section;

    return Tooltip(
      message: isCollapsed ? label : '',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: () => onSectionSelected(section),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? ShellitColors.accentBlue.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: ShellitColors.accentBlue.withValues(alpha: 0.4))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? ShellitColors.accentBlue
                      : ShellitColors.textSecondary,
                  size: 20,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? ShellitColors.textPrimary
                            : ShellitColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
