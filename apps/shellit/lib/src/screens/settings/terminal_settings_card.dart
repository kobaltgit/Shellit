import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../di/app_providers.dart';

/// Card for configuring Terminal Font, Security, and Interaction settings.
class TerminalSettingsCard extends ConsumerStatefulWidget {
  const TerminalSettingsCard({super.key});

  @override
  ConsumerState<TerminalSettingsCard> createState() =>
      _TerminalSettingsCardState();
}

class _TerminalSettingsCardState extends ConsumerState<TerminalSettingsCard> {
  bool _multilinePasteDefense = true;
  bool _enableClickableLinks = true;
  String _terminalFontFamily = 'JetBrains Mono';
  late final TextEditingController _customFontController;
  bool _isCustomFontSelected = false;
  bool _isLoading = true;

  static const List<String> _fontPresets = [
    'JetBrains Mono',
    'JetBrainsMono Nerd Font',
    'Fira Code',
    'FiraCode Nerd Font',
    'Cascadia Code',
  ];

  @override
  void initState() {
    super.initState();
    _customFontController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _customFontController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(appVaultRepositoryProvider);
    final settings = await repo.getSettings();
    if (mounted) {
      final isPreset = _fontPresets.contains(settings.terminalFontFamily);
      setState(() {
        _multilinePasteDefense = settings.multilinePasteDefense;
        _enableClickableLinks = settings.enableClickableLinks;
        _terminalFontFamily = settings.terminalFontFamily;
        _isCustomFontSelected = !isPreset;
        _customFontController.text = settings.terminalFontFamily;
        _isLoading = false;
      });
      ref.read(terminalFontFamilyProvider.notifier).state =
          settings.terminalFontFamily;
    }
  }

  Future<void> _updateSettings({
    bool? multilinePasteDefense,
    bool? enableClickableLinks,
    String? terminalFontFamily,
  }) async {
    final repo = ref.read(appVaultRepositoryProvider);
    final current = await repo.getSettings();
    final updated = current.copyWith(
      multilinePasteDefense: multilinePasteDefense ?? _multilinePasteDefense,
      enableClickableLinks: enableClickableLinks ?? _enableClickableLinks,
      terminalFontFamily: terminalFontFamily ?? _terminalFontFamily,
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
        if (terminalFontFamily != null) {
          _terminalFontFamily = terminalFontFamily;
        }
      });
      if (terminalFontFamily != null) {
        ref.read(terminalFontFamilyProvider.notifier).state =
            terminalFontFamily;
      }
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

    final effectiveDropdownValue = _isCustomFontSelected
        ? 'CUSTOM'
        : _terminalFontFamily;

    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Font Selection Header & Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.font_download_outlined,
                      color: ShellitColors.accentCyan,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(
                              'settings.terminal.font_family_title',
                              defaultText: 'Terminal Font Family',
                            ),
                            style: const TextStyle(
                              color: ShellitColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'settings.terminal.font_family_subtitle',
                              defaultText:
                                  'Primary font for the terminal grid. Nerd Fonts icons (PUA) and CJK are supported via fallback.',
                            ),
                            style: const TextStyle(
                              color: ShellitColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dropdown of presets
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ShellitColors.obsidianBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ShellitColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveDropdownValue,
                      isExpanded: true,
                      dropdownColor: ShellitColors.obsidianBackground,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ShellitColors.textMuted,
                      ),
                      items: [
                        ..._fontPresets.map(
                          (preset) => DropdownMenuItem(
                            value: preset,
                            child: Text(
                              preset,
                              style: TextStyle(
                                fontFamily: preset,
                                fontFamilyFallback: kTerminalFontFallbacks,
                                color: ShellitColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOM',
                          child: Text(
                            context.tr(
                              'settings.terminal.font_custom',
                              defaultText: 'Custom Font...',
                            ),
                            style: const TextStyle(
                              color: ShellitColors.accentCyan,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        if (val == 'CUSTOM') {
                          setState(() {
                            _isCustomFontSelected = true;
                          });
                        } else {
                          setState(() {
                            _isCustomFontSelected = false;
                            _customFontController.text = val;
                          });
                          _updateSettings(terminalFontFamily: val);
                        }
                      },
                    ),
                  ),
                ),

                // Custom font input field when "Custom..." is selected
                if (_isCustomFontSelected) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customFontController,
                          style: const TextStyle(
                            color: ShellitColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g. Hack Nerd Font, Cascadia Code PL',
                            hintStyle: const TextStyle(
                              color: ShellitColors.textMuted,
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: ShellitColors.obsidianBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: ShellitColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: ShellitColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: ShellitColors.accentCyan,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ShellitColors.accentCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {
                          final fontName = _customFontController.text.trim();
                          if (fontName.isNotEmpty) {
                            _updateSettings(terminalFontFamily: fontName);
                          }
                        },
                        child: Text(
                          context.tr('common.apply', defaultText: 'Apply'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Live font & glyph preview box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ShellitColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font Preview ($_terminalFontFamily):',
                        style: const TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$ ls -la 📁 dev/ 📄 main.dart  main [✓] 🚀',
                        style: TextStyle(
                          fontFamily: _terminalFontFamily,
                          fontFamilyFallback: kTerminalFontFallbacks,
                          fontSize: 13,
                          color: ShellitColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz',
                        style: TextStyle(
                          fontFamily: _terminalFontFamily,
                          fontFamilyFallback: kTerminalFontFallbacks,
                          fontSize: 11,
                          color: ShellitColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: ShellitColors.borderLight),

          // 2. Multiline Paste Defense
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

          // 3. Clickable Links
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
