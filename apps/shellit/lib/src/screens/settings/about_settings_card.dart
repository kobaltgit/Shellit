import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'feedback_report_dialog.dart';

/// Card component displaying the "About Shellit" section in the settings screen.
/// Inspired by modern terminal about blocks with quick action links,
/// pre-filled GitHub bug reporting, and GitHub releases update checking.
class AboutSettingsCard extends ConsumerStatefulWidget {
  const AboutSettingsCard({super.key});

  static const String defaultAppVersion = '0.8.6';
  static String appVersion = defaultAppVersion;
  static const String appReleaseChannel = 'α';
  static const String githubRepoUrl = 'https://github.com/kobaltgit/Shellit';
  static const String releasesApiUrl =
      'https://api.github.com/repos/kobaltgit/Shellit/releases/latest';

  @override
  ConsumerState<AboutSettingsCard> createState() => _AboutSettingsCardState();
}

class _AboutSettingsCardState extends ConsumerState<AboutSettingsCard> {
  bool _isCheckingUpdates = false;
  String _currentVersion = AboutSettingsCard.appVersion;
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _currentVersion = info.version;
          _buildNumber = info.buildNumber;
          AboutSettingsCard.appVersion = info.version;
        });
      }
    } catch (_) {
      // Fallback to defaultAppVersion if platform channel unavailable
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ShellitColors.obsidianCard,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: ShellitColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side: Brand identity & update check
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildBrandBlock(context),
                    ),
                  ),
                  const VerticalDivider(
                    color: ShellitColors.border,
                    width: 1,
                    thickness: 1,
                  ),
                  // Right side: Quick action items
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: _buildActionList(context),
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile / narrow layout: stacked
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandBlock(context),
                const SizedBox(height: 16),
                const Divider(color: ShellitColors.border, height: 1),
                const SizedBox(height: 8),
                _buildActionList(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ShellitLogo(size: 46, borderRadius: 10),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Shellit',
                      style: TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AboutSettingsCard.appReleaseChannel,
                      style: const TextStyle(
                        color: ShellitColors.accentCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.superscripts()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _buildNumber.isNotEmpty
                      ? 'v$_currentVersion (Build $_buildNumber)'
                      : 'v$_currentVersion',
                  style: const TextStyle(
                    color: ShellitColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: ShellitColors.obsidianBackground,
            foregroundColor: ShellitColors.textPrimary,
            side: const BorderSide(color: ShellitColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: _isCheckingUpdates ? null : _checkForUpdates,
          icon: _isCheckingUpdates
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ShellitColors.accentLime,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: ShellitColors.textSecondary,
                ),
          label: Text(
            _isCheckingUpdates
                ? context.tr(
                    'settings.about.checking_updates',
                    defaultText: 'Checking for updates...',
                  )
                : context.tr(
                    'settings.about.check_updates_btn',
                    defaultText: 'Check for updates',
                  ),
            style: const TextStyle(
              fontSize: 13,
              color: ShellitColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: ShellitColors.obsidianBackground,
            foregroundColor: ShellitColors.textPrimary,
            side: const BorderSide(color: ShellitColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () => FeedbackReportDialog.show(context),
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 16,
            color: ShellitColors.accentLime,
          ),
          label: Text(
            context.tr(
              'settings.about.send_feedback_btn',
              defaultText: 'Send Feedback / Bug Report',
            ),
            style: const TextStyle(
              fontSize: 13,
              color: ShellitColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionTile(
          icon: Icons.bug_report_outlined,
          title: context.tr(
            'settings.about.report_issue_title',
            defaultText: 'Report an Issue',
          ),
          subtitle: context.tr(
            'settings.about.report_issue_subtitle',
            defaultText: 'Open pre-filled report on GitHub',
          ),
          onTap: _openReportIssue,
        ),
        _buildActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: context.tr(
            'settings.about.community_title',
            defaultText: 'Community',
          ),
          subtitle: context.tr(
            'settings.about.community_subtitle',
            defaultText: 'Telegram (Coming soon)',
          ),
          onTap: _showCommunityInfo,
        ),
        _buildActionTile(
          icon: Icons.code_rounded,
          title: context.tr(
            'settings.about.github_title',
            defaultText: 'GitHub',
          ),
          subtitle: context.tr(
            'settings.about.github_subtitle',
            defaultText: 'Source code repository',
          ),
          onTap: _openGitHubRepo,
        ),
        _buildActionTile(
          icon: Icons.auto_stories_outlined,
          title: context.tr(
            'settings.about.changelog_title',
            defaultText: "What's New",
          ),
          subtitle: context.tr(
            'settings.about.changelog_subtitle',
            defaultText: 'View release highlights and changes',
          ),
          onTap: _showChangelogDialog,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: ShellitColors.border.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ShellitColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ShellitColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ShellitColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: ShellitColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdates = true);

    try {
      final response = await http
          .get(
            Uri.parse(AboutSettingsCard.releasesApiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'Shellit-Desktop-Client',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').replaceFirst(
          'v',
          '',
        );
        final htmlUrl =
            data['html_url'] as String? ??
            '${AboutSettingsCard.githubRepoUrl}/releases';
        final releaseName = data['name'] as String? ?? tagName;
        final releaseBody = data['body'] as String? ?? '';

        final isNewer = _isVersionGreater(tagName, _currentVersion);

        if (isNewer) {
          _showUpdateAvailableDialog(
            version: tagName,
            name: releaseName,
            notes: releaseBody,
            url: htmlUrl,
          );
        } else {
          _showSnackBar(
            context.tr(
              'settings.about.latest_version_installed',
              params: {'version': _currentVersion},
              defaultText:
                  'You have the latest version of Shellit installed ($_currentVersion).',
            ),
            backgroundColor: ShellitColors.statusGreen,
          );
        }
      } else if (response.statusCode == 403 || response.statusCode == 429) {
        _showSnackBar(
          context.tr(
            'settings.about.rate_limit_error',
            defaultText:
                'GitHub API rate limit exceeded. Please check releases manually on GitHub.',
          ),
          backgroundColor: ShellitColors.statusYellow,
        );
      } else if (response.statusCode == 404) {
        _showSnackBar(
          context.tr(
            'settings.about.no_releases_found',
            defaultText:
                'No remote releases found. You are running the latest preview build.',
          ),
          backgroundColor: ShellitColors.obsidianCard,
        );
      } else {
        _showSnackBar(
          context.tr(
            'settings.about.error_checking_updates',
            defaultText:
                'Could not check for updates (HTTP ${response.statusCode}).',
          ),
          backgroundColor: ShellitColors.statusRed,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          context.tr(
            'settings.about.network_error',
            defaultText:
                'Network connection failed. Could not check for updates.',
          ),
          backgroundColor: ShellitColors.statusRed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdates = false);
      }
    }
  }

  void _showSnackBar(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isVersionGreater(String remote, String current) {
    try {
      String cleanVersion(String v) {
        var s = v.trim();
        if (s.startsWith('v') || s.startsWith('V')) {
          s = s.substring(1);
        }
        if (s.contains('+')) {
          s = s.split('+').first;
        }
        if (s.contains('-')) {
          s = s.split('-').first;
        }
        return s;
      }

      final cleanRemote = cleanVersion(remote);
      final cleanCurrent = cleanVersion(current);

      final remoteParts = cleanRemote
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = cleanCurrent
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      final maxLen = remoteParts.length > currentParts.length
          ? remoteParts.length
          : currentParts.length;

      for (int i = 0; i < maxLen; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showUpdateAvailableDialog({
    required String version,
    required String name,
    required String notes,
    required String url,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Row(
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              color: ShellitColors.accentCyan,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              ctx.tr(
                'settings.about.update_available_title',
                defaultText: 'Update Available',
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.tr(
                  'settings.about.update_available_msg',
                  params: {'version': version},
                  defaultText:
                      'A new version of Shellit is available: $version',
                ),
                style: const TextStyle(
                  color: ShellitColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ShellitColors.obsidianBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ShellitColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        color: ShellitColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('common.cancel', defaultText: 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: Text(
              ctx.tr(
                'settings.about.download_update_btn',
                defaultText: 'Download Update',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReportIssue() async {
    final os = kIsWeb
        ? 'Web'
        : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

    final body =
        '### Environment\n'
        '- **Shellit Version**: $_currentVersion${AboutSettingsCard.appReleaseChannel}\n'
        '- **Operating System**: $os\n'
        '- **Dart/Flutter**: ${kIsWeb ? "Web" : Platform.version.split(" ").first}\n\n'
        '### Describe the bug\n'
        '<!-- A clear and concise description of what the bug is. -->\n\n'
        '### Steps to reproduce\n'
        '1. Go to \'...\'\n'
        '2. Click on \'....\'\n'
        '3. See error\n\n'
        '### Expected behavior\n'
        '<!-- What did you expect to happen? -->\n\n'
        '### Screenshots / Logs\n'
        '<!-- Attach logs from Settings -> Open Logs Directory if applicable -->\n';

    final query = Uri(
      queryParameters: {'title': '[Bug]: ', 'body': body},
    ).query;

    final url = Uri.parse(
      '${AboutSettingsCard.githubRepoUrl}/issues/new?$query',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showCommunityInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'settings.about.community_planned_msg',
            defaultText:
                'Telegram community chat is in preparation and will launch with the public release.',
          ),
        ),
        backgroundColor: ShellitColors.accentBlue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openGitHubRepo() async {
    await launchUrl(
      Uri.parse(AboutSettingsCard.githubRepoUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  void _showChangelogDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: Row(
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: ShellitColors.accentCyan,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              ctx.tr(
                'settings.about.changelog_dialog_title',
                defaultText: "What's New in Shellit",
              ),
              style: const TextStyle(
                color: ShellitColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ShellitColors.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ShellitColors.accentCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Version $_currentVersion${AboutSettingsCard.appReleaseChannel}',
                    style: const TextStyle(
                      color: ShellitColors.accentCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildChangelogItem(
                  '⚡ Matrix Tiling Splits',
                  'Support for 2x2, vertical and horizontal split layouts with live synchronized terminals.',
                ),
                _buildChangelogItem(
                  '🔒 SQLCipher & Argon2id Vault',
                  'Encrypted zero-leakage credentials store with auto-lock policy and master key derivation.',
                ),
                _buildChangelogItem(
                  '☁️ Cross-Device E2EE Sync',
                  'Encrypted multi-device sync engine supporting custom self-hosted sync relays.',
                ),
                _buildChangelogItem(
                  '🤖 Gemini AI Terminal Assistant',
                  'Natural language shell command generation and explanation directly inside sessions.',
                ),
                _buildChangelogItem(
                  '🧩 Plugin Ecosystem & I18n',
                  'Sandboxed WebView IPC plugins, live localizations, and asciinema session recording.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('common.close', defaultText: 'Close')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ShellitColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(
                Uri.parse('${AboutSettingsCard.githubRepoUrl}/releases'),
                mode: LaunchMode.externalApplication,
              );
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(
              ctx.tr(
                'settings.about.view_all_releases_btn',
                defaultText: 'All Releases on GitHub',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(
              Icons.check_circle_outline,
              size: 14,
              color: ShellitColors.statusGreen,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ShellitColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: ShellitColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
