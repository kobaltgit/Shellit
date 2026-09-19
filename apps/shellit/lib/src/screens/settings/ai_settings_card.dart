import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/ai_snippet_controller.dart';
import '../../di/app_providers.dart';

/// Card for configuring Gemini AI integration in Settings.
class AiSettingsCard extends ConsumerStatefulWidget {
  const AiSettingsCard({super.key});

  @override
  ConsumerState<AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends ConsumerState<AiSettingsCard> {
  late final TextEditingController _keyController;
  bool _obscureKey = true;
  bool _isEnabled = false;
  String _selectedModel = 'gemini-2.5-flash';
  List<AiModelInfo> _availableModels = [];
  bool _isLoadingModels = false;
  bool _isTesting = false;
  String? _statusMessage;
  Color _statusColor = ShellitColors.textMuted;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _loadExistingSettings();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSettings() async {
    final repo = ref.read(appVaultRepositoryProvider);
    final settings = await repo.getSettings();
    if (mounted) {
      setState(() {
        _keyController.text = settings.geminiApiKey ?? '';
        _isEnabled = settings.isAiSnippetEnabled;
        _selectedModel = settings.geminiModelId.isNotEmpty
            ? settings.geminiModelId
            : 'gemini-2.5-flash';
      });

      if (_keyController.text.isNotEmpty) {
        _fetchModels(silent: true);
      }
    }
  }

  Future<void> _fetchModels({bool silent = false}) async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    if (!silent && mounted) {
      setState(() {
        _isLoadingModels = true;
        _statusMessage = null;
      });
    }

    try {
      final client = ref.read(geminiApiClientProvider);
      final models = await client.fetchAvailableModels(key);
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isLoadingModels = false;
          if (models.isNotEmpty && !models.any((m) => m.id == _selectedModel)) {
            _selectedModel = models.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
          if (!silent) {
            _statusMessage = context.tr('settings.ai.test_failed', params: {
              'error': e.toString().replaceFirst('Exception: ', ''),
            });
            _statusColor = ShellitColors.statusRed;
          }
        });
      }
    }
  }

  Future<void> _testConnection() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _statusMessage = context.tr('settings.ai.test_failed', params: {
          'error': 'API key is empty',
        });
        _statusColor = ShellitColors.statusRed;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    try {
      final client = ref.read(geminiApiClientProvider);
      final models = await client.fetchAvailableModels(key);
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isTesting = false;
          _statusMessage = context.tr('settings.ai.test_success', params: {
            'count': '${models.length}',
          });
          _statusColor = ShellitColors.statusGreen;
          if (models.isNotEmpty && !models.any((m) => m.id == _selectedModel)) {
            _selectedModel = models.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _statusMessage = context.tr('settings.ai.test_failed', params: {
            'error': e.toString().replaceFirst('Exception: ', ''),
          });
          _statusColor = ShellitColors.statusRed;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final repo = ref.read(appVaultRepositoryProvider);
    final current = await repo.getSettings();

    final apiKey = _keyController.text.trim().isEmpty
        ? null
        : _keyController.text.trim();

    final updated = current.copyWith(
      geminiApiKey: apiKey,
      geminiModelId: _selectedModel,
      isAiSnippetEnabled: _isEnabled,
    );

    final res = await repo.updateSettings(updated);

    // Invalidate AI chat state so the chat view re-reads fresh settings
    ref.invalidate(aiChatControllerProvider);

    if (mounted) {
      if (res.isError) {
        final errorMsg = res.failureOrNull?.message ?? 'Failed to save settings';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: ShellitColors.statusRed,
          ),
        );
      } else {
        final msg = context.tr(
          'settings.ai.saved_msg',
          defaultText: 'AI settings saved successfully',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: ShellitColors.statusGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(color: ShellitColors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: ShellitColors.obsidianCard,
          ),
        );
        if (apiKey != null && apiKey.isNotEmpty) {
          _fetchModels(silent: true);
        }
      }
    }
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Switch
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: ShellitColors.accentCyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'settings.ai.enable_title',
                          defaultText: 'Enable AI Snippet Assistant',
                        ),
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          'settings.ai.enable_subtitle',
                          defaultText:
                              'Use Google Gemini to generate, explain, and optimize terminal commands',
                        ),
                        style: const TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  activeThumbColor: ShellitColors.accentCyan,
                  onChanged: (val) {
                    setState(() => _isEnabled = val);
                    // NOTE: intentionally NOT auto-saving here.
                    // Settings are saved only via the "Save AI Settings" button.
                  },
                ),
              ],
            ),
            const Divider(color: ShellitColors.border, height: 24),

            // API Key input field
            Text(
              context.tr('settings.ai.api_key_label', defaultText: 'Gemini API Key'),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: context.tr('settings.ai.api_key_hint', defaultText: 'AIzaSy...'),
                hintStyle: const TextStyle(color: ShellitColors.textMuted),
                filled: true,
                fillColor: ShellitColors.obsidianBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: ShellitColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: ShellitColors.accentCyan),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: ShellitColors.textMuted,
                  ),
                  onPressed: () {
                    setState(() => _obscureKey = !_obscureKey);
                  },
                ),
              ),
              onChanged: (_) {
                if (_statusMessage != null) {
                  setState(() => _statusMessage = null);
                }
              },
            ),
            const SizedBox(height: 6),

            // Link to Google AI Studio
            InkWell(
              onTap: _openAiStudio,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: ShellitColors.accentCyan,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr(
                        'settings.ai.get_key_link',
                        defaultText: 'Get free API key at Google AI Studio ↗',
                      ),
                      style: const TextStyle(
                        color: ShellitColors.accentCyan,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Model Dropdown
            Text(
              context.tr('settings.ai.model_label', defaultText: 'AI Model'),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ShellitColors.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ShellitColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availableModels.any((m) => m.id == _selectedModel)
                            ? _selectedModel
                            : (_availableModels.isNotEmpty
                                ? _availableModels.first.id
                                : _selectedModel),
                        dropdownColor: ShellitColors.obsidianCard,
                        style: const TextStyle(
                          color: ShellitColors.textPrimary,
                          fontSize: 13,
                        ),
                        isExpanded: true,
                        items: _availableModels.isNotEmpty
                            ? _availableModels.map((m) {
                                return DropdownMenuItem<String>(
                                  value: m.id,
                                  child: Row(
                                    children: [
                                      Text(m.displayName),
                                      if (m.isRecommended) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ShellitColors.accentCyan.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: ShellitColors.accentCyan.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            context.tr('settings.ai.recommended_badge', defaultText: 'Recommended'),
                                            style: const TextStyle(
                                              color: ShellitColors.accentCyan,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList()
                            : [
                                DropdownMenuItem(
                                  value: _selectedModel,
                                  child: Text(_selectedModel),
                                ),
                              ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModel = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: context.tr(
                    'settings.ai.refresh_models_tooltip',
                    defaultText: 'Refresh available models from Gemini API',
                  ),
                  child: IconButton(
                    icon: _isLoadingModels
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    color: ShellitColors.textSecondary,
                    onPressed: _isLoadingModels ? null : () => _fetchModels(),
                  ),
                ),
              ],
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _statusColor == ShellitColors.statusGreen
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(color: _statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt, size: 16),
                  label: Text(
                    context.tr('settings.ai.test_connection_btn', defaultText: 'Test Connection'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShellitColors.accentCyan,
                    side: const BorderSide(color: ShellitColors.accentCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: _isTesting ? null : _testConnection,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(
                    context.tr('settings.ai.save_btn', defaultText: 'Save AI Settings'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShellitColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
