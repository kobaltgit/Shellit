import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

/// Card for configuring Terminal Security and Interaction settings.
class TerminalSettingsCard extends ConsumerStatefulWidget {
  const TerminalSettingsCard({super.key});

  @override
  ConsumerState<TerminalSettingsCard> createState() =>
      _TerminalSettingsCardState();
}

class _TerminalSettingsCardState extends ConsumerState<TerminalSettingsCard> {
  bool _multilinePasteDefense = true;
  bool _enableClickableLinks = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(appVaultRepositoryProvider);
    final settings = await repo.getSettings();
    if (mounted) {
      setState(() {
        _multilinePasteDefense = settings.multilinePasteDefense;
        _enableClickableLinks = settings.enableClickableLinks;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings({
    bool? multilinePasteDefense,
    bool? enableClickableLinks,
  }) async {
    final repo = ref.read(appVaultRepositoryProvider);
    final current = await repo.getSettings();
    final updated = current.copyWith(
      multilinePasteDefense: multilinePasteDefense ?? _multilinePasteDefense,
      enableClickableLinks: enableClickableLinks ?? _enableClickableLinks,
    );
    await repo.updateSettings(updated);
    if (mounted) {
      setState(() {
        if (multilinePasteDefense != null) {
          _multilinePasteDefense = multilinePasteDefense;
        }
        if (enableClickableLinks != null) {
          _enableClickableLinks = enableClickableLinks;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          SwitchListTile(
            activeThumbColor: ShellitColors.accentCyan,
            value: _multilinePasteDefense,
            onChanged: (val) => _updateSettings(multilinePasteDefense: val),
            secondary: const Icon(
              Icons.shield_outlined,
              color: ShellitColors.accentCyan,
            ),
            title: Text(
              context.tr(
                'settings.terminal.multiline_paste_title',
                defaultText: 'Multiline Paste Defense',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              context.tr(
                'settings.terminal.multiline_paste_subtitle',
                defaultText:
                    'Intercept multiline paste with preview dialog to prevent accidental script execution',
              ),
              style: const TextStyle(
                color: ShellitColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          const Divider(height: 1, color: ShellitColors.borderLight),
          SwitchListTile(
            activeThumbColor: ShellitColors.accentCyan,
            value: _enableClickableLinks,
            onChanged: (val) => _updateSettings(enableClickableLinks: val),
            secondary: const Icon(
              Icons.link_outlined,
              color: ShellitColors.accentCyan,
            ),
            title: Text(
              context.tr(
                'settings.terminal.clickable_links_title',
                defaultText: 'Clickable Links & File Paths',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              context.tr(
                'settings.terminal.clickable_links_subtitle',
                defaultText:
                    'Open URLs in browser and file paths in SFTP editor via Ctrl+Click / Cmd+Click and context menu',
              ),
              style: const TextStyle(
                color: ShellitColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
