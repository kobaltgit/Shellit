import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:terminal_ui/terminal_ui.dart';

/// Feedback & Bug Reporter Dialog (IDEA-028).
/// Allows users to submit bugs, feature requests, or general feedback directly
/// to the Shellit central dashboard (PocketBase on https://shellit.top)
/// with safe, zero-knowledge telemetry (OS version, app version).
class FeedbackReportDialog extends StatefulWidget {
  final String? initialType;

  const FeedbackReportDialog({
    super.key,
    this.initialType,
  });

  static const String feedbackEndpoint =
      'https://shellit.top/api/collections/feedback_reports/records';

  /// Shows the feedback dialog modally.
  static Future<void> show(BuildContext context, {String? initialType}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => FeedbackReportDialog(initialType: initialType),
    );
  }

  @override
  State<FeedbackReportDialog> createState() => _FeedbackReportDialogState();
}

class _FeedbackReportDialogState extends State<FeedbackReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  late String _selectedType;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  String _appVersion = '0.8.4';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'bug';
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _appVersion = info.buildNumber.isNotEmpty
              ? '${info.version}+${info.buildNumber}'
              : info.version;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getOsTelemetry() {
    try {
      if (kIsWeb) return 'Web Browser';
      final os = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      return '$os ($version)';
    } catch (_) {
      return 'Unknown OS';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = {
      'type': _selectedType,
      'subject': _subjectController.text.trim(),
      'message': _messageController.text.trim(),
      'email': _emailController.text.trim(),
      'os_info': _getOsTelemetry(),
      'app_version': _appVersion,
      'status': 'new',
    };

    try {
      final response = await http
          .post(
            Uri.parse(FeedbackReportDialog.feedbackEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = context.tr(
            'feedback.error_banner',
            defaultText:
                'Failed to send report (HTTP ${response.statusCode}). Please check your connection and try again.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = context.tr(
          'feedback.error_banner',
          defaultText:
              'Failed to connect to the feedback server. Please check your internet connection.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ShellitColors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Neon Accent Gradient Line
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ShellitColors.accentLime,
                      ShellitColors.accentPurple,
                      ShellitColors.accentLime,
                    ],
                  ),
                ),
              ),

              // Content Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _isSuccess ? _buildSuccessView() : _buildFormView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        'feedback.dialog_title',
                        defaultText: 'Send Feedback or Bug Report',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ShellitColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        'feedback.dialog_subtitle',
                        defaultText:
                            'Help us make Shellit better. We read every submission.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShellitColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: ShellitColors.textMuted),
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                splashRadius: 18,
                tooltip: context.tr('common.close', defaultText: 'Close'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Error Banner if submission failed
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ShellitColors.statusRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ShellitColors.statusRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: ShellitColors.statusRed),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ShellitColors.statusRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category Selector Pills
          Text(
            context.tr('feedback.category_label', defaultText: 'Category'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ShellitColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCategoryPill(
                  type: 'bug',
                  label: context.tr(
                    'feedback.category_bug',
                    defaultText: '🐛 Bug Report',
                  ),
                  accentColor: ShellitColors.statusRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryPill(
                  type: 'feature_request',
                  label: context.tr(
                    'feedback.category_feature',
                    defaultText: '💡 Feature',
                  ),
                  accentColor: ShellitColors.accentPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCategoryPill(
                  type: 'general',
                  label: context.tr(
                    'feedback.category_general',
                    defaultText: '💬 Feedback',
                  ),
                  accentColor: ShellitColors.accentLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subject Input
          Text(
            context.tr('feedback.subject_label', defaultText: 'Subject'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ShellitColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _subjectController,
            enabled: !_isSubmitting,
            style: const TextStyle(fontSize: 13, color: ShellitColors.textPrimary),
            decoration: InputDecoration(
              hintText: context.tr(
                'feedback.subject_placeholder',
                defaultText: 'Brief summary of the issue or idea...',
              ),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr(
                  'feedback.subject_required',
                  defaultText: 'Please enter a subject',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Details / Message Input
          Text(
            context.tr('feedback.message_label', defaultText: 'Details'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ShellitColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _messageController,
            enabled: !_isSubmitting,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(fontSize: 13, color: ShellitColors.textPrimary),
            decoration: InputDecoration(
              hintText: context.tr(
                'feedback.message_placeholder',
                defaultText: 'Describe what happened or what you would like to see...',
              ),
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr(
                  'feedback.message_required',
                  defaultText: 'Please provide details',
                );
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Email Input (Optional)
          Text(
            context.tr('feedback.email_label', defaultText: 'Your Email (Optional)'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ShellitColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 13, color: ShellitColors.textPrimary),
            decoration: InputDecoration(
              hintText: context.tr(
                'feedback.email_placeholder',
                defaultText: 'you@domain.com (for follow-up)',
              ),
              isDense: true,
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final email = value.trim();
                if (!email.contains('@') || !email.contains('.')) {
                  return context.tr(
                    'feedback.email_invalid',
                    defaultText: 'Please enter a valid email address',
                  );
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: ShellitColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  context.tr('feedback.cancel_btn', defaultText: 'Cancel'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: FilledButton.styleFrom(
                  backgroundColor: ShellitColors.accentLime,
                  foregroundColor: const Color(0xFF0D0F12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0D0F12),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting
                      ? context.tr('feedback.sending_btn', defaultText: 'Sending...')
                      : context.tr('feedback.send_btn', defaultText: 'Send Report'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String type,
    required String label,
    required Color accentColor,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: _isSubmitting ? null : () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : ShellitColors.obsidianBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? accentColor
                : ShellitColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? accentColor : ShellitColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ShellitColors.statusGreen.withValues(alpha: 0.15),
            border: Border.all(
              color: ShellitColors.statusGreen.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 32,
            color: ShellitColors.statusGreen,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('feedback.success_title', defaultText: 'Report Received!'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ShellitColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.tr(
              'feedback.success_desc',
              defaultText:
                  'Thank you! Your feedback has been submitted to the engineering dashboard.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: ShellitColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            backgroundColor: ShellitColors.obsidianBackground,
            foregroundColor: ShellitColors.textPrimary,
            side: const BorderSide(color: ShellitColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            context.tr('feedback.close_btn', defaultText: 'Close'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
