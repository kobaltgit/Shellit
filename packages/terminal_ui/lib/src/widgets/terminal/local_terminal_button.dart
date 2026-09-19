import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/localization_scope.dart';
import '../../providers/local_terminal_provider.dart';
import '../../providers/session_manager_provider.dart';
import '../../theme/shellit_theme.dart';

/// Strict monochrome Split-Button for launching local terminal sessions.
/// Left portion triggers the default shell in 1 click;
/// Right dropdown chevron shows all detected shells with set-as-default option.
class LocalTerminalButton extends ConsumerWidget {
  const LocalTerminalButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellsState = ref.watch(localShellsProvider);
    final defaultProfile = shellsState.defaultProfile;
    final sessionNotifier = ref.read(sessionManagerProvider.notifier);

    final defaultShellName = defaultProfile?.name ?? 'Terminal';
    final tooltipText = context.tr(
      'local_terminal.tooltip.open_default',
      params: {'shell': defaultShellName},
      defaultText: 'Open Local Terminal ($defaultShellName)',
    );

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: ShellitColors.obsidianCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ShellitColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Left portion (1-click launch of default shell)
          Tooltip(
            message: tooltipText,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(7),
              ),
              onTap: defaultProfile == null
                  ? null
                  : () {
                      sessionNotifier.openLocalTerminalTab(
                        profile: defaultProfile,
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.terminal,
                      size: 16,
                      color: ShellitColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(
                        'local_terminal.btn.label',
                        defaultText: 'Terminal',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ShellitColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider between button and dropdown arrow
          Container(
            width: 1,
            height: 20,
            color: ShellitColors.border,
          ),

          // 2. Right portion (Chevron opening shell menu)
          Tooltip(
            message: context.tr(
              'local_terminal.tooltip.select_shell',
              defaultText: 'Select local shell',
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: ShellitColors.obsidianCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                      color: ShellitColors.border,
                      width: 1,
                    ),
                  ),
                ),
              ),
              child: PopupMenuButton<LocalShellProfile>(
                tooltip: '',
                offset: const Offset(0, 42),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: ShellitColors.textSecondary,
                ),
                onSelected: (profile) {
                  sessionNotifier.openLocalTerminalTab(profile: profile);
                },
                itemBuilder: (popupCtx) {
                  return shellsState.profiles.map((profile) {
                    final isDefault = profile.isDefault;
                    return PopupMenuItem<LocalShellProfile>(
                      value: profile,
                      height: 40,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.terminal_outlined,
                            size: 16,
                            color: ShellitColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: ShellitColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ShellitColors.obsidianBackground,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: ShellitColors.borderLight,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                popupCtx.tr(
                                  'local_terminal.menu.default_tag',
                                  defaultText: 'Default',
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: ShellitColors.accentBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
