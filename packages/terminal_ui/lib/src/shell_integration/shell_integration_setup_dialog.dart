import 'package:flutter/material.dart';
import '../localization/localization_scope.dart';
import '../theme/shellit_theme.dart';

/// Modal dialog for configuring and activating OSC 133 Semantic Shell Integration.
class ShellIntegrationSetupDialog extends StatelessWidget {
  final VoidCallback onActivateSession;
  final VoidCallback onInstallPermanent;
  final VoidCallback onCopyScript;

  const ShellIntegrationSetupDialog({
    super.key,
    required this.onActivateSession,
    required this.onInstallPermanent,
    required this.onCopyScript,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onActivateSession,
    required VoidCallback onInstallPermanent,
    required VoidCallback onCopyScript,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ShellIntegrationSetupDialog(
        onActivateSession: onActivateSession,
        onInstallPermanent: onInstallPermanent,
        onCopyScript: onCopyScript,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ShellitColors.border, width: 1),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF00E5FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'shell_integration.dialog_title',
                            defaultText:
                                'Shell Integration & Markers (OSC 133)',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr(
                            'shell_integration.dialog_subtitle',
                            defaultText:
                                'Command markers, exit status tracking, and hopping navigation',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: context.tr('common.close', defaultText: 'Close'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                context.tr(
                  'shell_integration.dialog_desc',
                  defaultText:
                      'To display command markers (green/red dots) and jump between commands with Alt+↑/↓, the remote shell requires lightweight OSC 133 hooks.',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: Current Session
              _buildOptionCard(
                context: context,
                icon: Icons.bolt_rounded,
                accentColor: const Color(0xFF00E5FF),
                title: context.tr(
                  'shell_integration.option_session_title',
                  defaultText: 'Activate in Current Session',
                ),
                subtitle: context.tr(
                  'shell_integration.option_session_desc',
                  defaultText:
                      'Enables markers in memory only and clears the screen. Automatically resets when the tab is closed.',
                ),
                buttonLabel: context.tr(
                  'shell_integration.btn_session',
                  defaultText: 'Activate',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onActivateSession();
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Permanent ~/.bashrc
              _buildOptionCard(
                context: context,
                icon: Icons.save_outlined,
                accentColor: const Color(0xFF10B981),
                title: context.tr(
                  'shell_integration.option_permanent_title',
                  defaultText: 'Install Permanently (~/.bashrc)',
                ),
                subtitle: context.tr(
                  'shell_integration.option_permanent_desc',
                  defaultText:
                      'Appends hook to ~/.bashrc on the server. Markers will be active automatically on every SSH login.',
                ),
                buttonLabel: context.tr(
                  'shell_integration.btn_permanent',
                  defaultText: 'Install to Host',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onInstallPermanent();
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Copy Script
              _buildOptionCard(
                context: context,
                icon: Icons.copy_rounded,
                accentColor: Colors.white70,
                title: context.tr(
                  'shell_integration.option_copy_title',
                  defaultText: 'Copy Hook Script',
                ),
                subtitle: context.tr(
                  'shell_integration.option_copy_desc',
                  defaultText:
                      'Copy the shell script to clipboard to inspect or run manually.',
                ),
                buttonLabel: context.tr(
                  'shell_integration.btn_copy',
                  defaultText: 'Copy Script',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onCopyScript();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ShellitColors.obsidianBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ShellitColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.2),
              foregroundColor: accentColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
